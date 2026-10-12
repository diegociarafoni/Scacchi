# Partite dei grandi maestri

Requisiti RF-87 (raccolta di partite storiche da sfogliare con commento) e RF-88 («Indovina la mossa»). Il codice è in `lib/masters/`. Funziona senza rete e senza motore, quindi la voce **Grandi maestri** della scheda Tu c'è su ogni piattaforma e anche nel profilo bambino.

## La raccolta

`masterGames` (`lib/masters/master_games.dart`) elenca le partite in ordine cronologico. Ogni `MasterGame` ha giocatori, luogo, anno, risultato, una breve introduzione, la linea principale in notazione algebrica (SAN) e un commento facoltativo per le mosse chiave, indicato per semimossa (da 1). `positions` e `moveList` rigiocano la partita con le regole di `dartchess`; una mossa illegale lancia `FormatException`, quindi un errore di trascrizione non arriva all'utente.

| Partita | Anno | Nome |
|---|---|---|
| Légal – Saint-Brie, Parigi | 1750 | Il matto di Légal |
| Anderssen – Kieseritzky, Londra | 1851 | La partita immortale |
| Anderssen – Dufresne, Berlino | 1852 | La sempreverde |
| Morphy – Duca di Brunswick e conte Isouard, Parigi | 1858 | La partita all'opera |
| Réti – Tartakower, Vienna | 1910 | La miniatura di Réti |
| Capablanca – Burn, San Sebastián | 1911 | — |
| Capablanca – Teichmann, Berlino | 1913 | — |
| Marshall – Capablanca, New York | 1918 | — |
| Donald Byrne – Fischer, New York | 1956 | La partita del secolo |
| Kasparov – Topalov, Wijk aan Zee | 1999 | Il sacrificio di torre di Kasparov |

### Fonte e licenza

- Le **mosse** di una partita sono fatti storici e non sono protette dal diritto d'autore; lo stesso vale per le intestazioni (giocatori, luogo, anno, risultato). Nessun file è copiato da un database: le linee sono trascritte nel codice e verificate dal test `test/masters/master_games_test.dart`, che le rigioca con le regole e controlla che il risultato indicato coincida con la fine della partita sulla scacchiera (o, se la partita è finita per abbandono, che il risultato sia 1-0, 0-1 o 1/2-1/2).
- I **commenti** e le introduzioni sono scritti per Rokko e seguono la licenza GPL-3.0 del progetto (vedi [licenza.md](licenza.md)).
- Le tre partite di Capablanca vengono dalla seconda parte («Illustrative games») del libro *Chess Fundamentals* di J. R. Capablanca, 1921, di pubblico dominio (Project Gutenberg #33870). Il libro usa la notazione descrittiva: le mosse sono state convertite in SAN e il test le rigioca tutte. Introduzioni e commenti sono scritti per Rokko e riprendono a parole nostre le idee di Capablanca, cosa possibile perché il testo è di pubblico dominio.
- Prima di aggiungere una partita si controlla che la fonte permetta il riuso: le partite storiche si possono aggiungere liberamente; per i testi di commento di altri autori serve una licenza compatibile con la GPL-3.0.

Per aggiungere una partita basta una nuova voce in `masterGames`: il test la prende da solo.

## Sfogliare una partita

`MasterGamePage` mostra la scacchiera (quella degli esercizi, con tema e pezzi scelti dall'utente) con l'ultima mossa evidenziata. Sotto ci sono il numero e la mossa corrente, il commento se c'è (all'inizio l'introduzione), i pulsanti per inizio, mossa precedente, mossa successiva e fine, e l'elenco di tutte le mosse da toccare per saltare. Il pulsante in alto gira la scacchiera. In fondo ci sono i due pulsanti «Indovina la mossa con il Bianco / con il Nero», con prima il lato che ha vinto.

## Indovina la mossa

`GuessRun` gioca un lato della partita:

- Se tocca al lato scelto, l'utente muove sulla scacchiera. La mossa è confrontata con quella del maestro; l'arrocco vale sia scritto come re di due case sia come re sulla torre (`normalizeMove`). Una mossa illegale non viene accettata dalla scacchiera.
- Sia che coincida o no, in scacchiera si gioca la mossa del maestro e un messaggio dice «Come il maestro!» oppure «Il maestro ha giocato …», con il commento se c'è. Dopo una breve pausa si gioca la risposta storica dell'avversario.
- A fine partita compaiono la percentuale di mosse uguali al maestro e le stelle (`guessStars`): tre da 70%, due da 50%, altrimenti una.

`MastersProgress` tiene la migliore percentuale per partita, in `masters.json` (`JsonFile`, versione 1). `MastersController` registra un `LessonCompleted` (XP e obiettivo giornaliero) solo la prima volta che una partita è conclusa. Il profilo bambino non mostra percentuali né conteggi, solo le stelle.

## Test

`test/masters/` (vedi [sviluppo.md](sviluppo.md)): legalità e risultato di ogni partita, `GuessRun`, progresso e controller, schermate; `test/home/home_masters_test.dart` per la voce della scheda Tu e `integration_test/masters_test.dart` per il percorso completo sull'app reale.
