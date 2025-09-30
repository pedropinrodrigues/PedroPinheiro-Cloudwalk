# MGM App — Documentação do MVP

## Visão Geral
Este projeto Flutter implementa um front-end de Member-Get-Member seguindo o roteiro definido. Toda a informação do app (sessão, usuários, notificações e configurações) é persistida em **um único arquivo JSON local (`data.json`)**, sem backend externo.

Principais fluxos entregues:
- Cadastro/login com validação de dados, código próprio único (5 dígitos) e opção de inserir código de indicação.
- Regras de indicação atribuindo +50 pontos por conversão e bônus adicionais conforme a meta configurada.
- Dashboard com saudação, total de pontos, botão para copiar o código e card de gamificação indicando quantas conversões faltam para o próximo bônus.
- Lista de notificações (conversões e bônus) filtrada pelo usuário logado, com datas formatadas.
- Edição de perfil (nome, e-mail, sexo, idade) com persistência no mesmo JSON.

## Estrutura do Código
```
lib/
  main.dart                 # Entrada da aplicação e rotas nomeadas
  routes.dart               # Constantes de navegação
  models/
    user.dart               # Modelo AppUser com toJson/fromJson e copyWith
    app_notification.dart   # Modelo AppNotification
  services/
    local_store.dart        # Acesso ao arquivo único data.json
    data_repository.dart    # Regras de negócio, sessão, pontos e notificações
  screens/
    login_signup_screen.dart
    dashboard_screen.dart
    notifications_screen.dart
    profile_screen.dart
```

## Como Executar
1. **Pré-requisitos**: Flutter 3.x instalado e configurado.
2. Acesse o diretório do app: `cd mgm_app`.
3. Instale dependências: `flutter pub get`.
4. Execute no dispositivo, emulador ou navegador desejado: `flutter run` (use `-d chrome` para web).
5. Para login rápido, use um usuário seed: `maria@example.com` + senha `senha123` ou `joao@example.com` + senha `123456`.

### Testes
- Há um teste básico garantindo que a tela de cadastro carregue: `flutter test`.

## Dados e Persistência
- O arquivo único `data.json` é gerenciado por `lib/services/local_store.dart`.
- O seed está versionado em `assets/data.json`; ele é carregado automaticamente na primeira inicialização (ou usado como fallback caso o arquivo real seja removido/corrompido).
- **Durante o desenvolvimento em macOS/Windows/Linux** o próprio `assets/data.json` atua como "banco" — qualquer cadastro/edição reflete imediatamente nesse arquivo.
- Em Android/iOS, o app grava no diretório de suporte do aplicativo (ex.: iOS simulators `Library/Application Support/data.json`, Android `/data/data/<package>/app_flutter/data.json`) e também tenta espelhar as alterações em `assets/data.json` quando possível.
- No Flutter web, os dados ficam apenas em memória (reiniciar/atualizar o navegador restaura o seed).
- O seed inicial inclui dois usuários de exemplo, notificações de conversão e bônus, além das configurações `{ bonus_every: 3, bonus_points: 50 }`.
- Toda interação (cadastro, edição, notificações, login) atualiza esse mesmo JSON, mantendo o MVP íntegro sem backend.

## Observações
- A lógica de gamificação e pontos está centralizada em `DataRepository.awardConversionPoints`, que também gera as notificações.
- O botão "Copiar código" utiliza `Clipboard.setData`, exibindo um `SnackBar` de confirmação.
- Caso necessário resetar o estado, basta apagar o arquivo `data.json`; o app recriará o seed automaticamente na próxima inicialização.
