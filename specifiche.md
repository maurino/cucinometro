# Cucinometro

## Obiettivo

voglio creare un programma (cucinometro) per decidere chi lava i piatti dopo il pasto, che può essere pranzo o cena. La mia famiglia ha 7 membri (mauro, daniela, silvia,claudia,alessandra,giulia francesco) e ognuno deve lavare i piatti circa quanto gli altri componenti

## Funzionalità

Il programma tiene traccia in un database di

* chi partecipa ad ogni pasto
* chi lava i piatti per quel pasto
* data del pasto
* se il pasto è pranzo o cena

questi dati devono poter essere inseriti e modificati per ogni pasto a richiesta dell'utente

quando decide chi lava i piatti per il pasto corrente, il programma deve

1. chiedere il nome dei partecipanti al pasto
2. cercare nel database tutti i pasti con esattamente quei partecipanti
3. calcolare quante volte ogni partecipante ha lavato  i piatti
4. assegnare il lavaggio dei piatti al partecipante che li ha lavati meno volte

Il programma deve inoltre fornire una funzionalità di **spiegazione della scelta** del lavapiatti per il pasto corrente, mostrando:

* quali pasti storici sono stati considerati per effettuare il calcolo (solo quelli con esattamente gli stessi partecipanti del pasto corrente)
* per ciascun partecipante, quante volte ha lavato i piatti in quei pasti considerati
* la regola usata per decidere (ad esempio: scelta della persona con il numero minimo di lavaggi tra i partecipanti)

## Architettura del programma

Il programma deve memorizzare i dati in un database relazionale open source come postgresql

Il database deve esporre delle api rest per l'esecuzione delle funzionalità

L'interfaccia web deve chiamare le api rest sopracitate, mentre la parte grafica può essere realizzata in uno strumento basato su python, come Django o Flask. I dati devono viaggiare fra l'interfaccia e le api in formato json

In futuro vorrei aggiungere altri client al programma, come ad esempio un client mobile o un server mcp.
Per questo motivo il database NON deve contenere oggetti con l'ORM di Django, perchè altrimenti il client mobile dovrebbe passare da django e ciò è male

### Introduzione di un API Gateway

Voglio aggiungere un API Gateway open source che faccia da filtro fra tutti i client e il servizio di dominio:

* Django non parla direttamente con il servizio FastAPI, ma interroga l'API Gateway.
* L'API Gateway riceve la richiesta dai client e la inoltra al servizio FastAPI che gestisce la logica del cucinometro e l’accesso al database.
* Questo permette di disaccoppiare i prodotti: Django, i client futuri e il servizio FastAPI possono essere riconfigurati o sostituiti senza incidere direttamente uno sull'altro.
* I client futuri (come il client mobile o il server MCP) parleranno direttamente con l'API Gateway, usando le stesse API esposte verso Django.

### Organizzazione del prodotto

Pertanto il prodotto dovrebbe essere cosi organizzato

1. un database postgresql
2. un servizio di dominio con api rest scritta in python (con fastapi) che effettua la gestione dei dati nel database
3. un API Gateway open source che espone le API “pubbliche” ai client e inoltra le richieste al servizio FastAPI
4. un backend (sito web) scritto in Django o che interroga l'API Gateway al punto 3 e fornisce i dati al browser

il backend al punto 4 può usare l'orm di django per i dati propri locali ma NON per i dati dei pasti, che deve richiedere all'API Gateway (che a sua volta inoltra al rest server FastAPI)
