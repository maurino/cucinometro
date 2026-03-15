# MCP Server - Cucinometro

Server MCP dedicato al Cucinometro.

## Cosa fa

Espone tool MCP che interrogano l'API Gateway del progetto:

- `choose_dishwasher`: decide chi lava i piatti per il pasto corrente
- `choose_dishwasher_from_text`: accetta frase libera in italiano, estrae i partecipanti e decide chi lava
- `health_check`: verifica raggiungibilita del gateway

### Frase libera

Con `choose_dishwasher_from_text` puoi passare frasi tipo:

- "oggi abbiamo mangiato mauro, daniela e alessandra"
- "oggi abbiamo mangiato io, daniela e alessandra" (in questo caso passa anche `requester_name`)

Per default i nomi riconosciuti sono: mauro, daniela, silvia, claudia, alessandra, giulia, francesco.
Puoi sovrascrivere la lista con la variabile ambiente `FAMILY_MEMBERS` (valori separati da virgola).

## Build Docker

```powershell
docker build -t cucinometro-mcp ./mcp-server
```

## Run con Docker Compose (consigliato)

```powershell
docker compose -f compose.yaml up -d --build mcp
```

## Run Docker standalone (alternativa)

```powershell
docker run --rm -p 8080:8080 --name cucinometro-mcp \
  -e CUCINOMETRO_API_BASE_URL=http://host.docker.internal:8000/api \
  cucinometro-mcp
```

## Endpoint MCP

Transport: streamable-http

URL locale: http://localhost:8080/mcp

## Nota

Se usi la modalita standalone, avvia prima il sistema principale (db, api, gateway) con Docker Compose, cosi il gateway risponde su `http://localhost:8000`.
