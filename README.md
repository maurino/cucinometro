# Sistema Cucinometro - Guida all'Uso

## Panoramica
Il sistema Cucinometro è una applicazione web completa per la gestione dei pasti familiari e l'assegnazione intelligente dei compiti di lavapiatti.

## Installazione

Per la guida completa di installazione e avvio ambiente (incluso precaricamento opzionale dati di prova), vedi [install.md](install.md).

## Architettura
- **API Backend**: FastAPI con PostgreSQL
- **Web Frontend**: Django con interfaccia responsive
- **API Gateway**: Kong per routing e trasformazione
- **Database**: PostgreSQL
- **Containerizzazione**: Docker Compose

## Avvio del Sistema

1. **Avvia tutti i servizi**:
   ```bash
   docker-compose up -d
   ```

2. **Verifica che tutto sia funzionante**:
   ```powershell
   .\tests\test-complete.ps1
   ```

## URL di Accesso

- **Interfaccia Web**: http://localhost:8002
- **API Gateway**: http://localhost:8000
- **API Diretta**: http://localhost:8001
- **Database**: localhost:5432

## Funzionalità

### Gestione Membri Familiari
- Aggiungi nuovi membri della famiglia
- Visualizza lista membri esistenti

### Gestione Pasti
- Crea nuovi pasti con descrizione
- Assegna automaticamente il lavapiatti basato su turni equi
- Visualizza storico pasti **(ordinati dalla data più recente alla più vecchia)**

### Statistiche Combinazioni
- **📊 Pagina dedicata alle statistiche** per ogni combinazione di membri
- Mostra **quante volte ogni combo ha mangiato insieme**
- Indica **quante volte ogni membro ha lavato i piatti** per quella combinazione
- **Ordinamento per frequenza decrescente** delle combinazioni

### Algoritmo Lavapiatti
L'algoritmo intelligente:
- Tiene traccia dei turni precedenti
- **Considera tutti i pasti passati con esattamente gli stessi partecipanti** (indipendentemente da pranzo/cena)
- Conta quante volte ogni partecipante ha lavato i piatti in quei pasti
- Assegna il lavapiatti al membro con meno turni
- Gestisce i turni in modo equo
- **Fornisce spiegazioni dettagliate con tabella dei conteggi** (formato markdown visualizzato come tabella HTML)

## API Endpoints

### Membri
- `GET /api/members` - Lista membri
- `POST /api/members` - Crea membro
- `GET /api/members/{id}` - Dettagli membro
- `PUT /api/members/{id}` - Aggiorna membro
- `DELETE /api/members/{id}` - Elimina membro

### Pasti
- `GET /api/meals` - Lista pasti
- `POST /api/meals` - Crea pasto
- `GET /api/meals/{id}` - Dettagli pasto
- `PUT /api/meals/{id}` - Aggiorna pasto
- `DELETE /api/meals/{id}` - Elimina pasto

### Utility
- `GET /api/health` - Health check

## Testing

### Test Kong Gateway
```powershell
.\tests\test-kong.ps1
```

### Test Completo Sistema
```powershell
.\tests\test-complete.ps1
```

## Sviluppatori

### Struttura Progetto
```
├── api/              # Backend FastAPI
├── web/              # Frontend Django
├── gateway/          # Configurazione Kong
├── sql/              # Script database
├── tests/            # Script di test
├── compose.yaml      # Docker Compose
└── README.md
```

### Ambiente di Sviluppo
- Python 3.11+
- Node.js (per eventuali frontend assets)
- Docker & Docker Compose

## Gestione Dati Database

### Pulizia Database
Per cancellare tutti i dati esistenti e rimuovere automaticamente i membri di test creati durante il testing:
```bash
docker-compose exec db psql -U cucino -d cucinometro -f /app/sql/clear_data.sql
```

**Nota**: Lo script `clear_data.sql` mantiene automaticamente solo i membri originali della famiglia (mauro, daniela, silvia, claudia, alessandra, giulia, francesco) e rimuove tutti i membri di test creati durante l'esecuzione degli script di test.

### Creazione Dati di Test
Per popolare il database con dati di test realistici:
```bash
docker-compose exec db psql -U cucino -d cucinometro -f /app/sql/seed_test_data.sql
```

I dati di test includono:
- 7 membri della famiglia (mauro, daniela, silvia, claudia, alessandra, giulia, francesco)
- **148 pasti dal 1-1-2026 al 15-3-2026 (74 giorni × 2 pasti al giorno)**
- **Combinazioni completamente casuali**: ogni pasto ha un numero casuale di partecipanti (1-7) e combinazione casuale di membri
- **602 partecipazioni totali** distribuite casualmente
- **Assegnazioni lavapiatti con distribuzione irregolare** (non equa, alcuni membri lavano molto più spesso)