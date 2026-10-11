# Aperture

Riconoscimento delle aperture, mosse di libro, explorer ridotto e repertorio con ripetizione dilazionata (requisiti RF-90, RF-91, RF-92, RF-93).

## Dati

`assets/openings/openings.tsv` deriva dal dataset [chess-openings](https://github.com/lichess-org/chess-openings) di Lichess (CC0): 3.865 righe `eco\tname\tuci`, circa 380 KB. Lo script `tool/datasets/build_openings.py` scarica i cinque file del dataset e converte le mosse da SAN a UCI, così l'app non deve interpretare la notazione algebrica all'avvio. Viene rigenerato dallo stesso workflow dei puzzle (`docs/puzzle.md`).

I nomi restano in inglese, come nel dataset: sono i nomi con cui le aperture si cercano nei libri e online.

## Libro delle aperture

`lib/openings/opening_book.dart` costruisce all'avvio, in un isolate separato, un grafo di posizioni:

- ogni posizione è identificata dall'EPD (i primi quattro campi della FEN: pezzi, tratto, arrocchi, en passant), quindi le trasposizioni portano allo stesso nome;
- ogni posizione con nome conserva codice ECO e nome; se più righe arrivano alla stessa posizione vale la prima;
- ogni mossa tra due posizioni del libro conta quante righe del dataset passano di lì.

Il libro si carica una volta sola (`openingBook()` in `opening_assets.dart`), in anticipo all'apertura dell'app; se il caricamento fallisce si riprova alla richiesta successiva. Il file è letto ignorando i fine riga Windows (`\r\n`).

### Riconoscimento in partita (RF-90)

`OpeningBook.classify(mosse)`, o `classifyPositions(posizioni)` quando le posizioni sono già calcolate come nella schermata di gioco, ripercorre la partita all'indietro e restituisce l'ultima posizione con nome, come suggerisce il dataset. Nella schermata di gioco il titolo "Scacchi" diventa il codice ECO e il nome dell'apertura appena la partita entra nel libro (widget `OpeningName`), con un'etichetta per i lettori di schermo ("Apertura: ..."). Il widget riceve le posizioni della partita a partire da quella iniziale, quindi una partita da posizione personalizzata non viene confusa con una dalla posizione standard.

### Mosse di libro (RF-91)

`OpeningBook.bookPlies(mosse)` restituisce quante semimosse iniziali restano nel libro; dopo la prima uscita non si rientra. La revisione della partita può usarlo per marcare le mosse "Libro".

### Explorer ridotto (RF-92)

Dalla scheda **Aperture**, l'Explorer mostra la posizione corrente con il nome dell'apertura, la sequenza delle mosse e le continuazioni del libro. Per ogni continuazione indica la mossa in SAN, il nome dell'apertura raggiunta e la quota delle varianti del libro che proseguono così.

Le statistiche di vittoria dei database online non sono disponibili offline (sono escluse dai requisiti): la percentuale misura quanto è ricca di varianti con nome una continuazione, non quanto è giocata. Si può muovere anche fuori dal libro; l'Explorer lo segnala.

### Repertorio (RF-93)

Ogni colore ha il suo repertorio: un elenco di linee con nome (es. "Italiana: 1. e4 e5 2. Nf3 Nc6 3. Bc4"). Le linee si aggiungono:

- dall'Explorer, con il pulsante **Aggiungi al repertorio**: nome proposto dall'apertura raggiunta, colore proposto in base a chi ha giocato l'ultima mossa;
- incollando un PGN nella schermata del repertorio: ogni variante diventa una linea, i rami illegali si scartano dal punto dell'errore.

Una linea è rifiutata se in una posizione già presente il repertorio prevede un'altra mossa per il proprio colore: il ripasso deve avere una sola risposta giusta. Le linee possono condividere l'inizio; le trasposizioni sono riconosciute tramite l'EPD.

**Carte.** Ogni mossa del proprio colore è una carta, identificata da colore ed EPD della posizione in cui va giocata, quindi due linee che passano dalla stessa posizione condividono la carta. Le carte usano la stessa coda di Leitner degli errori dei puzzle (`ReviewQueue`, intervalli di 1, 3, 7, 14 e 30 giorni) con due differenze: le carte nuove sono subito da ripassare e una carta arrivata all'ultimo intervallo resta nella coda ogni 30 giorni invece di uscirne.

**Ripasso.** "Ripassa N mosse" sceglie la prima linea con carte in scadenza e la gioca dall'inizio: le mosse dell'avversario e quelle del giocatore non in scadenza si giocano da sole. Per una carta nuova una freccia mostra la mossa da giocare; una mossa diversa da quella del repertorio rimanda la carta al primo intervallo e mostra la freccia, poi si deve giocare la mossa giusta per proseguire. Una carta nuova giocata correttamente passa al primo intervallo.

Linee e carte sono salvate in `training.json`, lo stesso file dei puzzle (`JsonFileStore`, istanza unica per evitare scritture concorrenti), con le chiavi `openings.repertoire.v1` e `openings.repertoire.review.v1`.

## Componenti

| File | Ruolo |
|---|---|
| `lib/openings/opening_book.dart` | Grafo delle posizioni, riconoscimento, mosse di libro, continuazioni |
| `lib/openings/opening_assets.dart` | Caricamento del dataset incluso |
| `lib/openings/opening_name.dart` | Nome dell'apertura per la schermata di gioco |
| `lib/openings/explorer_page.dart` | Explorer |
| `lib/openings/openings_hub_page.dart` | Scheda Aperture |
| `lib/openings/repertoire.dart` | Linee, carte, ripasso, import PGN |
| `lib/openings/repertoire_page.dart` | Linee di un colore, import PGN |
| `lib/openings/repertoire_drill_page.dart` | Ripasso sulla scacchiera |
