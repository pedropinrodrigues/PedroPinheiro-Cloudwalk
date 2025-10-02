# Member-Get-Member (CloudWalk Challenge)

## Visão geral
Este repositório reúne dois componentes complementares que simulam o programa *Member-Get-Member* gamificado:

1. **Backend Conversacional (Python + LangChain + Streamlit)** – carrega o dataset mockado, responde perguntas sobre o programa de indicações e gera relatórios interpretativos em PT-BR.
2. **Aplicativo Cliente (Flutter)** – consome o mesmo conjunto de dados para reproduzir a experiência do usuário no app gamificado, exibindo convites, notificações e pontuação.

Ambos os componentes trabalham a partir do mesmo formato de dados (estrutura JSON/Hive) e podem ser executados juntos para validar fluxos ponta a ponta.

## Dataset compartilhado
- A fonte de dados é um endpoint exposto em `DATA_URL` (padrão: `http://127.0.0.1:8090/export`), retornando um JSON com:
  ```json
  {
    "settings": {...},
    "session": {...},
    "users": [...],
    "notifications": [...]
  }
  ```
- O backend mantém um snapshot em memória (via `refresh_data()`), garantindo que o agente e os relatórios reflitam o estado atual.
- O aplicativo Flutter carrega os mesmos dados no Hive (ou arquivo local) para simular a experiência do usuário final.

## Backend (`backend/`)
- `src/chatagent.py`: define o agente e as ferramentas LangChain (`search_user`, `get_notifications_by_date`, `top_referrers`, etc.).
- `src/main.py`: interface Streamlit com duas abas – **Chat** (conversa com o agente) e **Relatórios** (seleção de período, geração de relatório textual e download). Possui botão **Recarregar dados** para sincronizar com `DATA_URL`.
- `src/relatorio_agent.py`: processa o snapshot, calcula métricas e pede ao modelo OpenAI para gerar um texto analítico.
- `requirements.txt`: dependências Python.

### Executar o backend
```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cat <<'ENV' > .env
OPENAI_API_KEY=sk-...
DATA_URL=http://127.0.0.1:8090/export  # opcional
ENV

# CLI
python3 src/chatagent.py

# Streamlit
streamlit run src/main.py
```
- **Chat**: faça perguntas em português; o histórico é preservado.
- **Relatórios**: escolha o período, gere o relatório e baixe o `.txt`. Lembre-se de clicar em **Recarregar dados** quando o dataset mudar.

## Aplicativo Flutter (`mgm_app/`)
- Reproduz o fluxo do app gamificado: cadastro, convites, lista de notificações e pontuação.
- Consome o mesmo dataset mockado (armazenado localmente em Hive/JSON). Ao atualizar o dataset, basta sincronizar o arquivo equivalente.
- Para rodar/depurar, siga as instruções detalhadas em `mgm_app/README.md` (configuração do Flutter SDK, dependências, comandos `flutter run`/`flutter test`).

## Integração entre backend e app
- **Consistência de dados**: mantenha o arquivo JSON (ou serviço em `DATA_URL`) sincronizado com o Hive do Flutter. Assim, o que o agente responde via chat/ref dados é o mesmo que aparece no app.
- **Fluxo sugerido para demonstração**:
  1. Atualize/preencha o dataset no serviço (ex.: script que exporta o JSON para `DATA_URL`).
  2. Execute o backend Streamlit e clique em **Recarregar dados**.
  3. Abra o app Flutter (em emulador ou dispositivo) e garanta que o arquivo Hive contenha o mesmo dataset.
  4. Navegue pelo app (ex.: visualizar notificações) e faça perguntas ao agente/relatório para comparar os resultados.
- **Testes ponta a ponta**: ao adicionar novos campos ou eventos, confirme a compatibilidade em ambos os lados (por exemplo, novas notificações “signup” já são aceitas pelas tools do backend).

## Estrutura do repositório
```
backend/
  src/
    chatagent.py
    main.py
    relatorio_agent.py
  README.md
  requirements.txt
mgm_app/
  lib/
  assets/
  test/
  README.md
roteiro_flutter_mgm.txt
README  (este arquivo)
```
