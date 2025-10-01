from datetime import datetime, timezone, timedelta
import json
from typing import Any, Dict, List, Optional

from langchain_openai import ChatOpenAI
from langchain.tools import tool
from langchain.agents import AgentExecutor, create_tool_calling_agent
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.messages import HumanMessage, AIMessage
import streamlit as st
import requests
import dotenv
import os


dotenv.load_dotenv()
os.environ["OPENAI_API_KEY"] = os.getenv("OPENAI_API_KEY")

data = requests.get('http://127.0.0.1:8090/export').json()

users = data.get('users', [])
notifications = data.get('notifications', [])



# Funções auxiliares para tools
def _parse_iso8601(date_str: Optional[str]) -> Optional[datetime]:
    if not date_str:
        return None
    cleaned = date_str.strip()
    if cleaned.endswith('Z'):
        cleaned = cleaned[:-1] + '+00:00'
    try:
        parsed = datetime.fromisoformat(cleaned)
    except ValueError as exc:
        raise ValueError(f"Data/hora ISO-8601 inválida: {date_str}") from exc
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed


def _apply_date_window(
    candidate: datetime,
    start: Optional[datetime],
    end: Optional[datetime],
) -> bool:
    if start and candidate < start:
        return False
    if end and candidate > end:
        return False
    return True


def _to_int(value: Any) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return 0


# Tools for the agent

@tool
# TODO Make a query for searching a user using its code, ID, email or name

def search_user(query: str) -> str:
    """Buscar um usuário pelo código, UID, e-mail ou nome."""
    lowered = query.lower()
    results = []
    for user in users:
        if not isinstance(user, dict):
            continue
        name = user.get('name', '') or ''
        email = user.get('email', '') or ''
        uid = user.get('uid', '') or ''
        my_code = user.get('my_code', '') or ''
        if (
            lowered in name.lower()
            or lowered in email.lower()
            or lowered in uid.lower()
            or lowered in my_code.lower()
        ):
            results.append(user)

    if not results:
        return "Nenhum usuário encontrado para a consulta."

    formatted = "; ".join(
        [
            f"UID: {u.get('uid')}, Nome: {u.get('name')}, E-mail: {u.get('email')}, Meu Código: {u.get('my_code')}"
            for u in results
        ]
    )
    return f"Encontrado(s) {len(results)} usuário(s): {formatted}"


@tool
def get_notifications_by_date(
    inviter_uid: Optional[str] = None,
    start: Optional[str] = None,
    end: Optional[str] = None,
    type: Optional[str] = None,
    limit: int = 50,
) -> str:
    """Retornar notificações filtradas por convidador, intervalo de datas e tipo."""

    if limit <= 0:
        raise ValueError("limit deve ser um inteiro positivo")

    start_dt = _parse_iso8601(start) if start else None
    end_dt = _parse_iso8601(end) if end else None

    if start_dt and end_dt and start_dt > end_dt:
        raise ValueError("start deve ser anterior ou igual a end")

    normalized_type = type.lower() if type else None
    if normalized_type and normalized_type not in {"conversion", "bonus"}:
        raise ValueError("type deve ser 'conversion' ou 'bonus'")


    filtered: List[Dict[str, Any]] = []
    for notification in notifications:
        created_at = _parse_iso8601(notification.get('created_at'))
        if created_at is None:
            continue
        if not _apply_date_window(created_at, start_dt, end_dt):
            continue
        if inviter_uid and notification.get('inviter_uid') != inviter_uid:
            continue
        if normalized_type and (notification.get('type') or '').lower() != normalized_type:
            continue
        filtered.append(notification)

    filtered.sort(
        key=lambda item: _parse_iso8601(item.get('created_at')) or datetime.min.replace(tzinfo=timezone.utc),
        reverse=True,
    )

    payload = filtered[:limit]
    return json.dumps(payload)


@tool
def get_points_summary(
    inviter_uid: Optional[str] = None,
    start: Optional[str] = None,
    end: Optional[str] = None,
) -> str:
    """Resumir os pontos concedidos no período agrupando por tipo de notificação."""

    start_dt = _parse_iso8601(start) if start else None
    end_dt = _parse_iso8601(end) if end else None

    if start_dt and end_dt and start_dt > end_dt:
        raise ValueError("start deve ser anterior ou igual a end")

    total = 0
    conversions = 0
    bonus = 0

    for notification in notifications:
        created_at = _parse_iso8601(notification.get('created_at'))
        if created_at is None:
            continue
        if not _apply_date_window(created_at, start_dt, end_dt):
            continue
        if inviter_uid and notification.get('inviter_uid') != inviter_uid:
            continue

        points = _to_int(notification.get('points_awarded'))
        total += points
        notif_type = (notification.get('type') or '').lower()
        if notif_type == 'conversion':
            conversions += points
        elif notif_type == 'bonus':
            bonus += points

    result = {
        'points_total_period': total,
        'points_from_conversions': conversions,
        'points_from_bonus': bonus,
    }
    return json.dumps(result)


@tool
def top_referrers(
    start: Optional[str] = None,
    end: Optional[str] = None,
    limit: int = 5,
) -> str:
    """Listar indicadores ranqueados pelo número de conversões no período escolhido."""

    if limit <= 0:
        raise ValueError("limit deve ser um inteiro positivo")

    start_dt = _parse_iso8601(start) if start else None
    end_dt = _parse_iso8601(end) if end else None

    if start_dt and end_dt and start_dt > end_dt:
        raise ValueError("start deve ser anterior ou igual a end")

    conversion_counts: Dict[str, int] = {}
    for notification in notifications:
        if (notification.get('type') or '').lower() != 'conversion':
            continue
        created_at = _parse_iso8601(notification.get('created_at'))
        if created_at is None:
            continue
        if not _apply_date_window(created_at, start_dt, end_dt):
            continue
        inviter = notification.get('inviter_uid')
        if not inviter:
            continue
        conversion_counts[inviter] = conversion_counts.get(inviter, 0) + 1

    ranked: List[Dict[str, Any]] = []
    for uid, conversions in conversion_counts.items():
        user = next((u for u in users if u.get('uid') == uid), None)
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
    payload = ranked[:limit]
    return json.dumps(payload)


@tool
def churn_risk(days: int = 7) -> str:
    """Identificar usuários convidados sem pontos com contas mais antigas que a janela informada."""

    if days <= 0:
        raise ValueError("days deve ser um inteiro positivo")

    cutoff = datetime.now(timezone.utc) - timedelta(days=days)
    at_risk: List[Dict[str, Any]] = []

    for user in users:
        if not isinstance(user, dict):
            continue
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

    result = {
        'days': days,
        'count': len(at_risk),
        'users': at_risk,
    }
    return json.dumps(result)

@tool
def get_actual_date() -> str:
    """Obter a data e hora atual. Essa função deve ser usada ANTES da utilização de outras ferramentas que dependem de data/hora, como as tools: get_notifications_by_date, churn_risk."""
    return json.dumps({"current_date": datetime.now(timezone.utc).isoformat()})

@tool
def total_points_given_per_time(
        start: Optional[str] = None,
        end: Optional[str] = None,
    ) -> int:

    """Retornar o total de pontos concedidos no período especificado. Tem como parâmetro o início e o fim do período."""
    start_dt = _parse_iso8601(start) if start else None
    end_dt = _parse_iso8601(end) if end else None

    if start_dt and end_dt and start_dt > end_dt:
        raise ValueError("start deve ser anterior ou igual a end")
        
    total_points = 0
    for notification in notifications:
        created_at = _parse_iso8601(notification.get('created_at'))
        if created_at is None:
            continue
        if not _apply_date_window(created_at, start_dt, end_dt):
            continue
        points = _to_int(notification.get('points_awarded'))
        total_points += points

    return total_points
    
def criar_agent() -> AgentExecutor:
    llm = ChatOpenAI(temperature=0, model_name="gpt-4o-mini", max_retries=3)

    tools = [
        search_user,
        get_notifications_by_date,
        get_points_summary,
        top_referrers,
        churn_risk,
        get_actual_date,
    ]

    prompt = ChatPromptTemplate.from_messages([
        ("system", "Você é um assistente que ajuda a analisar uma base de dados de programa de indicações. "
                   "Use as ferramentas disponíveis para responder perguntas sobre usuários e notificações. "
                   "Interprete as saídas das ferramentas e responda resumindo em linguagem natural, sem necessariamente repetir o JSON bruto. "
                   "Seja conciso e factual em suas respostas."),
        MessagesPlaceholder(variable_name="chat_history"),
        ("user", "Responda à seguinte pergunta: {input}"),
        MessagesPlaceholder(variable_name="agent_scratchpad"),
    ])

    agent = create_tool_calling_agent(
        llm=llm,
        tools=tools,
        prompt=prompt,
        # handle_parsing_errors=True,
    )

    return AgentExecutor(agent=agent, tools=tools, verbose=True)

def main():
    agent = criar_agent()
    chat_history: List = []

    while True:
        user_input = input("Você: ")
        if user_input.lower() in {"exit", "sair"}:
            break
        response = agent.invoke({"input": user_input, "chat_history": chat_history})
        output_text = response.get("output") if isinstance(response, dict) else response
        print("Agente:", output_text)

        chat_history.append(HumanMessage(content=user_input))
        chat_history.append(AIMessage(content=output_text or ""))

if __name__ == "__main__":
    main()
