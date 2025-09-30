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
- A camada de armazenamento usa **Hive** (ver `lib/services/hive_store.dart`).
- Na primeira inicialização abrimos a box `mgm_data_box` e carregamos o seed (`assets/data.json`) se necessário.
- Os dados ficam guardados em um único registro Hive (`root`) que espelha a estrutura original do JSON.
- No mobile/desktop, os arquivos `.hive` residem no diretório de suporte da aplicação (ex.: iOS `Library/Application Support/mgm_data_box.hive`).
- No Flutter web, os dados permanecem em memória enquanto a sessão estiver ativa.
- É possível exportar todo o conteúdo em JSON chamando `DataRepository.exportAsJson()` (útil para backups ou inspeção manual).
- Há um utilitário CLI em `bin/export_server.dart`. Rode `dart run bin/export_server.dart --hive-dir=<pasta>` para subir um servidor local (padrão http://127.0.0.1:8080/export) e baixar o dump JSON; o script copia os arquivos `.hive` para uma pasta temporária antes de gerar o snapshot (não precisa encerrar o app). 
- Todos os fluxos (cadastro, edição de perfil, gamificação, notificações) trabalham sobre essa camada Hive, preservando a estrutura `{ settings, session, users, notifications }`.

## Observações
- A lógica de gamificação e pontos está centralizada em `DataRepository.awardConversionPoints`, que também gera as notificações.
- O botão "Copiar código" utiliza `Clipboard.setData`, exibindo um `SnackBar` de confirmação.
- Caso necessário resetar o estado, basta apagar o arquivo `data.json`; o app recriará o seed automaticamente na próxima inicialização.
