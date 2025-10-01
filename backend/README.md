# Backend

## Visão geral
Este diretório contém um agente implementado com LangChain que consulta dados mockados de um programa de indicações. O agente expõe ferramentas (tools) específicas para consultar usuários, notificações e estatísticas e pode ser utilizado tanto via CLI quanto integrado a uma aplicação Streamlit.

## Estrutura principal
- `main.py` – inicializa o agente (`criar_agent`) com as tools personalizadas e um prompt em português, além de oferecer um loop de linha de comando (`main`) que mantém histórico de conversa.

## Ferramentas disponíveis
Todas as tools retornam JSON para fácil serialização:
- `search_user(query)` – busca usuários pelo nome, e-mail, UID ou código (`my_code`).
- `get_notifications_by_date(inviter_uid, start, end, type, limit)` – filtra notificações por convidador, janela temporal e tipo (`conversion`, `bonus`).
- `get_points_summary(inviter_uid, start, end)` – retorna totais de pontos e soma por tipo de evento no período.
- `top_referrers(start, end, limit)` – ranqueia os usuários com mais conversões no intervalo.
- `churn_risk(days)` – lista convidados sem pontos cuja conta é mais antiga que a janela informada.

## Pré-requisitos
- Python 3.10+
- Dependências: `langchain`, `langchain-openai`, `openai`, `requests`, `python-dotenv`, `streamlit` (para a camada UI), além de qualquer pacote adicional exigido pelas ferramentas do LangChain em uso.

## Configuração
1. Crie um arquivo `.env` na raiz do projeto com sua chave da OpenAI:
   ```env
   OPENAI_API_KEY=sk-...
   ```
2. Garanta que o endpoint de dados mockados esteja acessível em `http://127.0.0.1:8090/export` ou ajuste a URL em `main.py` conforme necessário. O JSON deve seguir a estrutura `{ schema_version, settings, session, users, notifications }`.

## Execução
Com o ambiente configurado, execute:
```bash
python3 main.py
```
Durante a execução:
- Digite perguntas em português para o agente.
- Use `exit` ou `sair` para encerrar o loop.
- O agente mantém o histórico da conversa (`chat_history`) e resume respostas em linguagem natural, sem repetir JSON bruto.

## Desenvolvimento
- Ajuste ou adicione novas tools em `main.py`, reutilizando os helpers (`_parse_iso8601`, `_apply_date_window`, `_to_int`).
- Utilize `python3 -m compileall main.py` para uma checagem rápida de sintaxe.
- Atualize o prompt no `criar_agent` se novas instruções forem necessárias.

## Próximos passos sugeridos
- Criar testes automatizados para validar cada tool com datasets de exemplo.
- Extrair variáveis configuráveis (URL do dataset, modelo OpenAI, temperatura) para um arquivo de configuração dedicado.
- Disponibilizar um script de seed para gerar ou atualizar o arquivo de dados consumido pela aplicação móvel.
