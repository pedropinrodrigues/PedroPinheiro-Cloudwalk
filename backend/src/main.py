"""Página Streamlit para conversar com o agente e gerar relatórios."""

from datetime import date
from typing import List

import streamlit as st
from langchain_core.messages import HumanMessage, AIMessage

from chatagent import criar_agent, refresh_data
from relatorio_agent import generate_report


st.set_page_config(page_title="Assistente de Indicações", page_icon="🤖", layout="wide")

if "agent" not in st.session_state:
    st.session_state.agent = criar_agent()

if "chat_history" not in st.session_state:
    st.session_state.chat_history: List = []

if "report_result" not in st.session_state:
    st.session_state.report_result = None

st.title("Assistente do Programa de Indicações")
st.caption("Converse em português ou gere relatórios analíticos.")

# Controles laterais (sidebar) para geração de relatórios
_today = date.today()
_default_start = _today.replace(day=1)

if st.sidebar.button("Recarregar dados", use_container_width=True):
    with st.spinner("Recarregando dados..."):
        refresh_data()
        st.session_state.report_result = None
    st.sidebar.success("Dados atualizados!")

start_date = st.sidebar.date_input("Data inicial", value=_default_start)
end_date = st.sidebar.date_input("Data final", value=_today)

if start_date > end_date:
    st.sidebar.error("A data inicial deve ser anterior ou igual à data final.")

if st.sidebar.button("Gerar relatório", use_container_width=True) and start_date <= end_date:
    with st.spinner("Gerando relatório..."):
        st.session_state.report_result = generate_report(start_date.isoformat(), end_date.isoformat())
    st.sidebar.success("Relatório gerado!")

if st.session_state.report_result:
    report_content = st.session_state.report_result["content"]
    report_file = st.session_state.report_result["file_name"]
    st.sidebar.download_button(
        label="Baixar relatório",
        data=report_content.encode("utf-8"),
        file_name=report_file,
        mime="text/plain",
        use_container_width=True,
    )
else:
    st.sidebar.info("Gere um relatório para habilitar o download.")

aba_chat, aba_relatorios = st.tabs(["Chat", "Relatórios"])

with aba_chat:
    chat_container = st.container()
    with chat_container:
        for message in st.session_state.chat_history:
            role = "user" if isinstance(message, HumanMessage) else "assistant"
            with st.chat_message(role):
                st.markdown(message.content)

    prompt = st.chat_input("Digite sua pergunta")
    if prompt:
        with st.chat_message("user"):
            st.markdown(prompt)

        st.session_state.chat_history.append(HumanMessage(content=prompt))

        response = st.session_state.agent.invoke(
            {"input": prompt, "chat_history": st.session_state.chat_history}
        )
        output_text = response.get("output") if isinstance(response, dict) else str(response)

        with st.chat_message("assistant"):
            st.markdown(output_text)

        st.session_state.chat_history.append(AIMessage(content=output_text))

with aba_relatorios:
    if st.session_state.report_result:
        metadata = st.session_state.report_result.get("metadata", {})
        inicio = metadata.get("start") or "Início"
        fim = metadata.get("end") or "Atual"

        st.subheader("Relatório mais recente")
        st.markdown(f"**Período:** {inicio} — {fim}")
        st.markdown(st.session_state.report_result["content"], unsafe_allow_html=False)
    else:
        st.info("Use os controles na barra lateral para gerar um relatório de indicações.")
