# MGM App — Guia de Execução

Este documento resume como rodar o front-end Flutter e como exportar os dados (Hive) em JSON.

## Pré-requisitos
- Flutter 3.x com `dart` configurado no PATH.
- Dependências instaladas (`flutter pub get`).

## Rodando o app Flutter

```bash
cd /Users/pedro/Documents/Aplicações/CloudWalk/PedroPinheiro-Cloudwalk/mgm_app
flutter pub get
flutter run # -d chrome | -d macos | -d ios etc.
```

## Exportando dados Hive como JSON
1. **Simulador iOS/macOS** (recomendo a nova flag):
   ```bash
   dart run bin/export_server.dart \
     --sim-root="/Users/pedro/Library/Developer/CoreSimulator/Devices/<DEVICE_ID>/data/Containers/Data/Application" \
     --port=8090
   ```
2. **Web**: não persiste, export sempre retorna seed.
3. **macOS desktop**: `--hive-dir="$HOME/Library/Application Support/mgm_app"`.
4. **Android**: `/data/data/com.example.mgm_app/app_flutter` (via `adb` + `run-as`).

Depois use `curl` ou o navegador:
```bash
curl http://127.0.0.1:8090/export | python -m json.tool
```

## Export via UI
Na Dashboard existe o botão **Exportar** que mostra o JSON atual.

Para mais detalhes consulte a raiz `README.md`.
