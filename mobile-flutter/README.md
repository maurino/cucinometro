# Cucinometro Mobile (Flutter)

Client mobile Flutter con le stesse funzionalita principali del client Django:

- Home con lista pasti e membri
- Creazione membro
- Creazione pasto
- Decisione lavapiatti con spiegazione
- Statistiche per combinazione partecipanti

## Requisiti

- Flutter SDK 3.22+
- Backend Cucinometro attivo (gateway su porta 8000)

## Struttura

- lib/main.dart: bootstrap app
- lib/api_service.dart: client REST verso API Gateway
- lib/models.dart: modelli dati
- lib/screens/: schermate principali

## Avvio rapido

Dalla cartella mobile-flutter:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api
```

Note connessione:

- Android emulator: usa `http://10.0.2.2:8000/api`
- iOS simulator: `http://localhost:8000/api`
- Dispositivo fisico: usa IP LAN del PC, es. `http://192.168.1.10:8000/api`

Esempio Android emulator:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

## Generazione file piattaforma

Se la cartella e stata creata senza Flutter CLI, genera i file piattaforma cosi:

```bash
flutter create .
```

Dopo il comando, rilancia:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api
```
