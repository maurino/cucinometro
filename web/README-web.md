# Cucinometro - Sito Web Django

Interfaccia web per il sistema Cucinometro, che permette di gestire pasti familiari e assegnare automaticamente i compiti di lavapiatti.

## 🚀 Come avviare

### Con Docker Compose (Raccomandato)
```bash
docker-compose up --build
```

Il sito sarà disponibile su: http://localhost:8002

### Sviluppo Locale
```bash
cd web
pip install django requests
python manage.py migrate
python manage.py runserver
```

Il sito sarà disponibile su: http://localhost:8000

## 📋 Funzionalità

### 🏠 Homepage
- **Lista pasti recenti**: Visualizza tutti i pasti con partecipanti e lavapiatti assegnato
- **Lista membri**: Mostra tutti i membri della famiglia
- **Azioni rapide**: Pulsanti per creare pasti, decidere lavapiatti e aggiungere membri

### ➕ Creazione Pasto
- Seleziona data e tipo di pasto (colazione, pranzo, cena, spuntino)
- Scegli partecipanti tra i membri esistenti
- Il sistema crea automaticamente il pasto

### 🧽 Decisione Lavapiatti
- Algoritmo intelligente che considera:
  - Turni equi tra partecipanti
  - Storico dei lavaggi precedenti
  - Partecipanti al pasto corrente
- Mostra spiegazione della decisione

### 👤 Gestione Membri
- Aggiungi nuovi membri della famiglia
- Nomi univoci nel sistema

## 🏗️ Architettura

```
Frontend Django (porta 8002)
    ↓
Kong Gateway (porta 8000)
    ↓
API Python/FastAPI (porta 8001)
    ↓
Database PostgreSQL (porta 5432)
```

## 🔧 Configurazione

### API_BASE_URL
Il frontend Django comunica con l'API attraverso la variabile d'ambiente:
- **Docker**: `API_BASE_URL=http://gateway:8000/api`
- **Sviluppo locale**: `API_BASE_URL=http://localhost:8000/api`

### Dipendenze
- Django 4.2+
- requests (per chiamate API)

## 🎨 Template

I template HTML sono responsive e ottimizzati per dispositivi mobili, con:
- Design moderno e intuitivo
- Emoji per migliore user experience
- Messaggi di errore/successo
- Form validation lato client

## 🧪 Testing

Usa lo script `tests/test-kong.ps1` per verificare che Kong e l'API funzionino correttamente prima di testare il frontend.

## 📱 User Experience

- **Intuitivo**: Interfaccia semplice con azioni chiare
- **Responsive**: Funziona su desktop e mobile
- **Real-time**: Aggiornamenti immediati dopo ogni azione
- **Error handling**: Messaggi chiari in caso di problemi