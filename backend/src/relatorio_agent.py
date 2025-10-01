from datetime import datetime, timezone, timedelta
import json
from typing import Any, Dict, List, Optional

from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage

import dotenv
import os

from chatagent import _parse_iso8601, _apply_date_window, _to_int, refresh_data, users, notifications

dotenv.load_dotenv()
os.environ["OPENAI_API_KEY"] = os.getenv("OPENAI_API_KEY")


def analise_content(report: str) -> str:
    """Analisa o conteúdo do relatório e gera uma análise narrativa junto dos dados."""
    
    llm = ChatOpenAI(model="gpt-4o-mini", temperature=0.2)
    
    system_prompt = """Você é um analista de negócios.
    Você ajuda na informação do produto: Aplicativo Member-Get-Member gamificado, onde usuários convidam novos participantes por código. Cada conversão gera pontos e, após certo número de indicações, recebem bônus. O sistema registra novos usuários e notificações de indicações.    
    Sua tarefa é receber um relatório bruto (com métricas e dados JSON retirados da plataforma)
    e transformá-lo em um texto estruturado, com:
    1. Resumo executivo
    2. Principais métricas destacadas
    3. Insights e tendências (crescimento, quedas, riscos)
    4. Recomendações de ação
    5. Conclusão

    Use linguagem clara e objetiva. Explique os números.
    """

    human_prompt = f"""Aqui está o relatório bruto:

    {report}

    Gere a análise interpretativa em PT-BR, mantendo os dados principais, mas enriquecendo com insights narrativos.
    """

    response = llm.invoke([SystemMessage(content=system_prompt), HumanMessage(content=human_prompt)])
    return response.content

def _filter_by_date_range(
    items: List[Dict[str, Any]],
    start: Optional[datetime],
    end: Optional[datetime],
    date_key: str,
) -> List[Dict[str, Any]]:
    """Retorna itens cujo campo de data está dentro da janela desejada."""

    filtered: List[Dict[str, Any]] = []
    for item in items:
        if not isinstance(item, dict):
            continue
        raw_date = item.get(date_key)
        candidate = _parse_iso8601(raw_date)
        if candidate is None:
            continue
        if _apply_date_window(candidate, start, end):
            filtered.append(item)
    return filtered


def _calculate_points_summary(notifs: List[Dict[str, Any]]) -> Dict[str, int]:
    total = 0
    conversions = 0
    bonus = 0

    for notification in notifs:
        points = _to_int(notification.get('points_awarded'))
        total += points
        notif_type = (notification.get('type') or '').lower()
        if notif_type == 'conversion':
            conversions += points
        elif notif_type == 'bonus':
            bonus += points

    return {
        'points_total_period': total,
        'points_from_conversions': conversions,
        'points_from_bonus': bonus,
    }


def _top_referrers(
    users_data: List[Dict[str, Any]],
    notifs: List[Dict[str, Any]],
    limit: int = 5,
) -> List[Dict[str, Any]]:
    conversion_counts: Dict[str, int] = {}
    for notification in notifs:
        if (notification.get('type') or '').lower() != 'conversion':
            continue
        inviter = notification.get('inviter_uid')
        if not inviter:
            continue
        conversion_counts[inviter] = conversion_counts.get(inviter, 0) + 1

    ranked: List[Dict[str, Any]] = []
    for uid, conversions in conversion_counts.items():
        user = next((u for u in users_data if u.get('uid') == uid), None)
        if not user:
            continue
        ranked.append({
            'uid': uid,
            'name': user.get('name'),
            'my_code': user.get('my_code'),
            'conversions': conversions,
            'points_total': _to_int(user.get('points_total')),
        })

    ranked.sort(key=lambda item: (item['conversions'], item['points_total']), reverse=True)
    return ranked[:limit]


def _churn_risk(
    users_subset: List[Dict[str, Any]],
    reference_date: datetime,
    days: int = 7,
) -> Dict[str, Any]:
    cutoff = reference_date - timedelta(days=days)
    at_risk: List[Dict[str, Any]] = []

    for user in users_subset:
        if not user.get('invited_by_code'):
            continue
        if _to_int(user.get('points_total')) != 0:
            continue
        created_at = _parse_iso8601(user.get('created_at'))
        if created_at is None:
            continue
        if created_at > cutoff:
            continue
        at_risk.append({
            'uid': user.get('uid'),
            'name': user.get('name'),
            'email': user.get('email'),
            'invited_by_code': user.get('invited_by_code'),
        })

    return {
        'days': days,
        'count': len(at_risk),
        'users': at_risk,
    }


def generate_report(
    start: Optional[str],
    end: Optional[str],
) -> Dict[str, Any]:
    """Gera um relatório textual a partir da janela de datas informada."""
    start_date = _parse_iso8601(start) if start else None
    end_date = _parse_iso8601(end) if end else None

    refresh_data()

    users_data = list(users)
    notifications_data = list(notifications)

    filtered_users = _filter_by_date_range(users_data, start_date, end_date, date_key="created_at")
    filtered_notifications = _filter_by_date_range(notifications_data, start_date, end_date, date_key="created_at")

    points_summary = _calculate_points_summary(filtered_notifications)
    top_users = _top_referrers(users_data, filtered_notifications, limit=5)
    reference_date = end_date or datetime.now(timezone.utc)
    churned_users = _churn_risk(filtered_users, reference_date)

    report_content = f"""
    Relatório de Indicações
    Período: {start_date.date() if start_date else 'Início'} a {end_date.date() if end_date else 'Atual'}

    Resumo de Pontos:
    {json.dumps(points_summary, indent=2)}

    Top 5 Usuários que mais indicaram:
    {json.dumps(top_users, indent=2)}

    Usuários com risco de churn:
    {json.dumps(churned_users, indent=2)}

    Indicações e Notificações:
    {json.dumps(filtered_notifications, indent=2)}

    Fim do Relatório
    """

    processed_report = analise_content(report_content)

    period_label = f"{start_date.date()}_{end_date.date()}" if start_date and end_date else "completo"
    file_name = f"relatorio_indicacoes_{period_label}.txt"

    return {
        "content": processed_report,
        "file_name": file_name,
        "metadata": {
            "start": start,
            "end": end,
            "raw_report": report_content,
        },
    }

def main():
    """Função principal para teste."""
    resultado = generate_report("2023-01-01", "2023-12-31")
    print(f"Relatório gerado: {resultado['file_name']}")

if __name__ == "__main__":
    main()
