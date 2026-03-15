# Test delle Componenti

Questa cartella contiene i test per API Gateway, API e test end-to-end del sistema.

## Prerequisiti

- Docker e Docker Compose attivi
- Stack avviato con `docker compose up -d`
- PowerShell 5.1+ (per gli script `.ps1`)
- Python con `requests` installato (per `test_api.py`)

## Esecuzione test

Esegui i comandi dalla root del progetto.

### 1) Test Kong Gateway

```powershell
.\tests\test-kong.ps1
```

Con URL personalizzato:

```powershell
.\tests\test-kong.ps1 -KongUrl "http://localhost:8000"
```

### 2) Test completo end-to-end

```powershell
.\tests\test-complete.ps1
```

Con URL personalizzati:

```powershell
.\tests\test-complete.ps1 -WebUrl "http://localhost:8002" -ApiUrl "http://localhost:8000/api"
```

### 3) Test API rapido (Python)

```powershell
python .\tests\test_api.py
```

## Cosa verificano

- `test-kong.ps1`: routing e endpoint principali tramite Kong
- `test-complete.ps1`: pagine web + endpoint API principali
- `test_api.py`: chiamata rapida a `decide-dishwasher` con explanation