# Backend (LangChain + Streamlit)

## Visão geral
O backend concentra toda a automação conversacional e a geração de relatórios do desafio Member-Get-Member. Ele é composto por três módulos Python dentro de `src/` que compartilham o mesmo cache de dados obtido a partir da API configurada em `DATA_URL`.

## Módulos Python

### `src/chatagent.py`
Responsável por tudo que o agente precisa para funcionar:
- **Carregamento de dados**: `refresh_data()` consulta `DATA_URL`, atualiza os caches globais (`users`, `notifications`) e é chamado automaticamente em cada tool antes do processamento.
- **Helpers**: `_parse_iso8601`, `_apply_date_window`, `_to_int` padronizam parsing de datas e manipulação numérica.
- **Ferramentas LangChain**:
  - `search_user(query)` – aceita nome, e-mail, UID, `my_code` ou datas (`YYYY-MM-DD`) e retorna um resumo do usuário.
  - `get_notifications_by_date(...)` – filtra notificações por convidador, período e tipo (qualquer string).
  - `get_points_summary(...)`, `top_referrers(...)`, `churn_risk(days)`, `total_points_given_per_time(...)`, `get_actual_date()` – agregações utilizadas pelo agente e pelo relatório.
- **Agente**: `criar_agent()` monta o prompt, registra as tools e devolve um `AgentExecutor` pronto para uso.
- **CLI**: executado com `python3 src/chatagent.py`, abre um loop interativo em português que mantém `chat_history` em memória.

### `src/main.py`
Interface Streamlit oficial:
- Exibe duas abas: **Chat** (histórico com o agente) e **Relatórios** (preview completo do texto gerado).
- A barra lateral possui:
  - botão **Recarregar dados** → chama `refresh_data()` e invalida o relatório em cache;
  - seleção de período + botão **Gerar relatório** → invoca `generate_report`;
  - botão **Baixar relatório** para salvar o texto como `.txt`.
- Reutiliza o mesmo `AgentExecutor` criado em `chatagent.py`, preservando o histórico via `st.session_state.chat_history`.

### `src/relatorio_agent.py`
- Chama `refresh_data()` para garantir dados atualizados e filtra as listas via `_filter_by_date_range`.
- Consolida métricas (`_calculate_points_summary`, `_top_referrers`, `_churn_risk`) e monta o relatório bruto com os valores JSON.
- `analise_content()` envia o material bruto para o LLM e devolve um texto estruturado (resumo executivo, métricas, insights e recomendações).
- `generate_report(start, end)` retorna um dicionário com o texto final, nome do arquivo `.txt` e metadados (período, JSON base). É usado pela aba de relatórios no Streamlit.

## Ambiente e variáveis
Crie `backend/.env` com, no mínimo:
```env
OPENAI_API_KEY=sk-...
DATA_URL=http://127.0.0.1:8090/export  # opcional; padrão aponta para localhost
```
A API deve entregar um JSON com as chaves `settings`, `session`, `users` e `notifications`.

## Como executar
1. **Instalar dependências**
   ```bash
   cd backend
   python3 -m venv .venv && source .venv/bin/activate
   pip install -r requirements.txt
   ```
2. **CLI** – conversa direta com o agente:
   ```bash
   python3 src/chatagent.py
   ```
3. **Streamlit** – UI completa com chat e relatórios:
   ```bash
   streamlit run src/main.py
   ```

## Dicas de desenvolvimento
- `refresh_data()` é a fonte de verdade; invoque-a sempre que criar novas ferramentas ou análises para manter o cache sincronizado.
- Utilize `python3 -m compileall src` para validar rapidamente se há erros de sintaxe após alterações.
- Ao adicionar novas tools, lembre-se de registrá-las na lista de `tools` dentro de `criar_agent()`.
- O relatório atualmente salva apenas `.txt`; para oferecer PDF/HTML, estenda `generate_report` ou trate o arquivo diretamente na camada Streamlit.