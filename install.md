# Installazione Ambiente Cucinometro

Questa guida descrive come installare e avviare tutto l'ambiente partendo da un checkout da GitHub.

## Prerequisiti

- Git
- Docker Desktop (con Docker Engine e Docker Compose v2)
- PowerShell (Windows) o terminale equivalente
- Porte libere: 5432, 8000, 8001, 8002, 8080

## 1. Checkout del progetto da GitHub

```bash
git clone <URL_REPOSITORY_GITHUB>
cd cucinometro
```

## 2. Avvio servizi con Docker Compose

```bash
docker compose -f compose.yaml up -d --build
```

Servizi avviati:
- Database PostgreSQL
- API FastAPI
- API Gateway Kong
- Frontend Django
- MCP Server (streamable-http)

Nota:
- Se in precedenza hai avviato container manualmente con `docker run` (es. `cucinometro-mcp`), fermali/rimuovili prima del compose per evitare conflitti di nome:

```powershell
docker rm -f cucinometro-mcp
```

## 3. Inizializzazione schema database

Eseguire lo script SQL di init una volta dopo il primo avvio (o quando il volume DB e' vuoto):

```powershell
docker exec -i cucinometro-db psql -U cucino -d cucinometro < .\sql\001_init.sql
```

## 4. Verifica rapida ambiente

Apri questi URL:
- Web: http://localhost:8002
- Gateway API: http://localhost:8000/api/health
- API diretta: http://localhost:8001/internal/health
- MCP endpoint: http://localhost:8080/mcp

## 5. Dati di prova (opzionale)

Se vuoi popolare il DB con dati dal 2025-01-01 a oggi (2 pasti al giorno: pranzo e cena), esegui:

```powershell
docker exec -i cucinometro-db psql -U cucino -d cucinometro < .\sql\seed_test_data.sql
```

Nota:
- Lo script cancella i dati correnti e ricarica membri, pasti, partecipanti e assegnazioni.

## 6. Esecuzione test

Dalla root del progetto:

```powershell
.\tests\test-kong.ps1
.\tests\test-complete.ps1
python .\tests\test_api.py
.\tests\test-mcp.ps1
```

Dettagli test in tests/README.md.

## Comandi utili

Arrestare i servizi:

```bash
docker compose -f compose.yaml down
```

Arrestare e cancellare anche i volumi (reset completo DB):

```bash
docker compose -f compose.yaml down -v
```

Ricostruire i container:

```bash
docker compose -f compose.yaml up -d --build
```
