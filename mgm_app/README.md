# MGM App — Documentação do MVP

## Visão Geral
Este projeto Flutter implementa um front-end de Member-Get-Member seguindo o roteiro definido. Toda a informação do app (sessão, usuários, notificações e configurações) é persistida localmente usando **Hive**, mantendo a mesma estrutura JSON (armazenada dentro da chave `root`) e dispensando backend externo.

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
    hive_store.dart         # Gateway para o Hive (open/seed/export)
    local_store_seed.dart   # Conteúdo inicial do banco (seed JSON)
    data_repository.dart    # Regras de negócio, sessão, pontos e notificações
  screens/
    login_signup_screen.dart
    dashboard_screen.dart
    notifications_screen.dart
    profile_screen.dart
```

## Como Executar o Front-end
1. **Pré-requisitos**: Flutter 3.x configurado no PATH.
2. Entre na pasta do app e instale dependências:
   ```bash
   cd /Users/pedro/Documents/Aplicações/CloudWalk/PedroPinheiro-Cloudwalk/mgm_app
   flutter pub get
   ```
3. Rode o aplicativo no dispositivo/simulador que preferir:
   ```bash
   flutter run              # usa o dispositivo padrão
   flutter run -d chrome    # web
   flutter run -d macos     # desktop
   flutter run -d ios       # simulador iOS
   ```
4. Logins seed disponíveis: `maria@example.com / senha123` e `joao@example.com / 123456`.

### Testes
- `flutter test` executa tanto o widget smoke test quanto o teste de integração do Hive (`test/hive_store_test.dart`).

## Dados e Persistência
- A camada de armazenamento usa **Hive** (ver `lib/services/hive_store.dart`).
- Na primeira inicialização abrimos a box `mgm_data_box` e carregamos o seed (`assets/data.json`) se necessário.
- Os dados ficam guardados em um único registro Hive (`root`) que espelha a estrutura original do JSON.
- No mobile/desktop, os arquivos `.hive` residem no diretório de suporte da aplicação (ex.: iOS `Library/Application Support/mgm_data_box.hive`).
- No Flutter web, os dados permanecem em memória enquanto a sessão estiver ativa.
- É possível exportar todo o conteúdo em JSON chamando `DataRepository.exportAsJson()` (útil para backups ou inspeção manual).
- Há um utilitário CLI em `bin/export_server.dart`. Rode `dart run bin/export_server.dart --hive-dir=<pasta>` para subir um servidor local (padrão http://127.0.0.1:8080/export) e baixar o dump JSON; o script copia os arquivos `.hive` para uma pasta temporária antes de gerar o snapshot (não precisa encerrar o app). Para simuladores iOS, você pode apontar para a raiz `.../Application/` com `--sim-root=<caminho>` que ele resolve automaticamente o container mais recente.
- Todos os fluxos (cadastro, edição de perfil, gamificação, notificações) trabalham sobre essa camada Hive, preservando a estrutura `{ settings, session, users, notifications }`.

### Exportando dados Hive (detalhado)
Quando executado em modo debug, o app já sobe um servidor local em `http://127.0.0.1:8090/export` (caso a porta esteja livre), facilitando a inspeção do JSON sem precisar rodar o script manualmente.

1. **Descobrir o diretório atual do Hive**: quando o app inicia, o log mostra `Hive dir: <caminho>`. No simulador iOS esse caminho muda a cada reinstalação; use `--sim-root` para que o script encontre automaticamente o último container.
2. **Rodar o servidor de export** (exemplos):
   ```bash
   # macOS / desktop
   dart run bin/export_server.dart --hive-dir="$HOME/Library/Application Support/mgm_app"

   # simulador iOS (resolver automaticamente o container mais recente)
   dart run bin/export_server.dart \
     --sim-root="/Users/pedro/Library/Developer/CoreSimulator/Devices/<DEVICE_ID>/data/Containers/Data/Application" \
     --port=8090
   ```
3. **Baixar o JSON**:
   ```bash
   curl http://127.0.0.1:8090/export | python -m json.tool
   ```
   (ou abra a URL no navegador para salvar o arquivo).

## Observações
- A lógica de gamificação e pontos está centralizada em `DataRepository.awardConversionPoints`, que também gera as notificações.
- O botão "Copiar código" utiliza `Clipboard.setData`, exibindo um `SnackBar` de confirmação.
- Caso necessário resetar o estado, exclua os arquivos `mgm_data_box.*` (ou apague a box via botão de export/CLI); na próxima execução o seed será recriado automaticamente.
