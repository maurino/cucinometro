# Cucinometro Mobile Client (Flutter)

Client mobile Flutter con le stesse funzionalita principali del client Django:

- Home con lista pasti e membri
- Creazione membro
- Creazione pasto
- Decisione lavapiatti con spiegazione
- Statistiche per combinazione partecipanti

## Nota Repository

In GitHub sono versionati solo i sorgenti applicativi.
Le cartelle piattaforma generate automaticamente (`android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`) non sono incluse.

## Requisiti

- Flutter SDK 3.22+
- Backend Cucinometro attivo (gateway su porta 8000)
- Emulatore Android disponibile (es. `cucinometro_api_35`)

## Struttura

- `lib/main.dart`: bootstrap app
- `lib/api_service.dart`: client REST verso API Gateway
- `lib/models.dart`: modelli dati
- `lib/screens/`: schermate principali

## Rigenerazione progetto Flutter

Dalla cartella `mobile-client`:

```powershell
flutter create .
flutter pub get
```

## Avvio su emulatore Android

1. Avvia backend e gateway dalla root progetto:

```powershell
docker compose -f compose.yaml up -d --build
```

2. Avvia emulatore Android:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd cucinometro_api_35 -no-snapshot-load -no-boot-anim
```

3. Avvia app mobile:

```powershell
cd .\mobile-client
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

## Note connessione API

- Android emulator: usa `http://10.0.2.2:8000/api`
- iOS simulator: `http://localhost:8000/api`
- Dispositivo fisico: usa IP LAN del PC, es. `http://192.168.1.10:8000/api`
