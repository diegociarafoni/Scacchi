# Percorso a tappe

Requisito RG-03: una mappa di capitoli e tappe sul modello di Duolingo e del modulo "Impara" di Lichess, con valutazione da 1 a 3 stelle. Il codice è in `lib/path/`.

## Capitoli

| Capitolo | Tappe |
|---|---|
| Il movimento dei pezzi | Torre, alfiere, donna, re, cavallo, pedone (con promozione), catturare (con il valore dei pezzi) |
| Le regole | Lo scacco, via dallo scacco (spostare il re, catturare, mettere in mezzo), l'arrocco, la presa al varco, la promozione, lo stallo |
| Matti elementari | Matto in una (primi esempi), il matto del corridoio (con la donna e attirando via il difensore), donna e re, le torri a scala in due mosse, matti famosi (Anastasia, arabo, Boden, Damiano), matto in due (anche il matto affogato con sacrificio di donna), guardiano (400 Elo) |
| Tattiche | Pezzi indifesi, forchetta (cavallo, pedone, forchetta reale, donna), inchiodatura, infilata (torre e alfiere), attacco di scoperta, scacco doppio, elimina il difensore, guardiano (800) |
| Finali | Matto di donna, matto di torre, la regola del quadrato, l'opposizione, lo sfondamento, guardiano (1000) |
| Aperture | Il centro, lo sviluppo (con la Partita Italiana), l'arrocco, il matto del barbiere (darlo e pararlo), guardiano (1200) |

Ogni tappa è breve (2-5 minuti) e si apre con una spiegazione di due o tre frasi, scritta in modo semplice perché valga anche per il profilo bambino; la scacchiera accetta mosse solo dopo «Inizia». I contenuti sono originali (posizioni costruite per il progetto) e in italiano. Durante la stesura le posizioni tattiche sono state analizzate con Stockfish: la mossa richiesta è la migliore e la risposta automatica del Nero è una difesa ragionevole, non un errore che regala il punto. Il test automatico controlla legalità e matti, non la qualità delle risposte: chi aggiunge esercizi tattici ripete questa verifica.

Una tappa si apre quando la lezione precedente è completata, oppure quando è già completata una lezione che viene dopo: così le lezioni aggiunte con un aggiornamento restano aperte per chi era già più avanti e non richiudono le tappe successive. Senza tappe saltate equivale a «tutte le lezioni precedenti completate». I guardiani sono sfide facoltative e non bloccano il percorso. Il pulsante "Continua" porta alla prima lezione non completata (anche una appena aggiunta) e, finite le lezioni, al primo guardiano non battuto. Un doppio tocco non apre due tappe.

## Esercizi

**A stelle** (`StarsExercise`): un pezzo bianco da solo su scacchiera vuota raccoglie le stelle, in qualunque ordine. Il minimo di mosse si calcola da solo con una ricerca in ampiezza sugli stati (casa, pezzo, stelle raccolte), quindi i contenuti non contengono numeri da tenere aggiornati. Stelle: 3 al minimo, 2 con al massimo due mosse in più, 1 altrimenti. Il pedone avanza di uno o di due dalla seconda traversa e in ottava diventa donna (la scacchiera promuove a donna senza chiedere).

**A linea** (`LineExercise`): una posizione FEN e una sequenza di passi. I passi pari sono del giocatore, con alternative separate da `|`; i dispari sono le risposte automatiche dell'avversario. Le mosse si confrontano in SAN, così l'arrocco è riconosciuto sia come re su g1 sia come re sulla torre. Con l'obiettivo "matto" all'ultimo passo vale qualunque mossa che dà matto, con l'obiettivo "scacco" qualunque scacco dato con lo stesso pezzo della soluzione. Una mossa sbagliata non viene giocata e conta come errore. Stelle: 3 senza errori, 2 con uno, 1 con più errori.

La tappa vale la media delle stelle dei suoi esercizi, arrotondata per difetto.

## Bot guardiano

L'ultima tappa dei capitoli dai Matti elementari in poi è una partita contro un bot dell'Elo indicato. `PathPage` riceve `playGuardian`, che gioca la partita e restituisce le stelle (o `null` se non vinta). Il percorso si apre dalla scheda Tu e, dove gira Stockfish (Android e iOS), toccare il guardiano apre una partita già impostata: l'utente ha il Bianco, il livello è quello del motore con l'Elo più vicino a quello del guardiano (`engineLevelForElo`), senza orologio, e non si possono ricominciare, usare l'editor, il coach o l'analisi; **Annulla** funziona (`GameChallenge.allowUndo`), perché il guardiano è allenamento, mentre nelle partite dei tornei resta disattivato. Uscire a partita in corso chiede conferma e conta come persa; dopo una sconfitta si riprova riaprendo la tappa. I livelli del motore partono da 600 Elo, quindi il guardiano da 400 gioca al livello 1 (600) e quello da 1000 al livello 2 (900): il livello effettivo è scritto sotto il titolo. Altrove la tappa mostra un avviso.

Stelle (`challengeStars`): vittoria in al massimo 40 mosse 3 stelle, fino a 60 mosse 2, oltre 1; patta e sconfitta non ne danno e si può riprovare. La partita registra XP e archivio come le altre (vedi [gamification.md](gamification.md)). Il percorso non si completa col guardiano: le stelle restano le migliori ottenute.

## Verifica dei contenuti

`test/path/curriculum_test.dart` controlla ogni esercizio: mosse della soluzione e risposte legali, risposte forzate (unica mossa legale) negli esercizi di matto, ogni prima mossa che forza il matto accettata tra le alternative, ultima mossa che dà matto (o scacco, per l'obiettivo scacco), una spiegazione per ogni lezione, stelle raggiungibili e mai sulla casa di partenza. Un errore in un FEN o in una soluzione fa fallire la CI.

## Salvataggio e XP

`PathController` salva le stelle migliori per tappa in `path.json` (tramite `JsonFile`, vedi [archivio.md](archivio.md)) e registra `LessonCompleted` nella gamification, con la durata, la prima volta che una lezione è completata (rigiocarla migliora le stelle ma non dà altro XP; le partite dei guardiani registrano l'XP da sé), se riceve `recordActivity`:

```dart
final progress = await ProgressController.open();
final path = await PathController.open(recordActivity: progress.record);
```

## Componenti

| File | Ruolo |
|---|---|
| `exercise.dart` | Esercizi a stelle e a linea, loro svolgimento e stelle |
| `curriculum.dart` | Capitoli, tappe e contenuti |
| `path_progress.dart` | Stelle per tappa, sblocco, tappa successiva |
| `path_controller.dart` | Caricamento, salvataggio, registrazione dell'XP |
| `path_page.dart` | Mappa del percorso |
| `stage_page.dart` | Svolgimento di una tappa sulla scacchiera |

Le stelle di tappe rimosse in un aggiornamento dei contenuti restano nel file ma non contano nel totale.

La schermata della tappa usa la scacchiera a tutta larghezza in verticale e affianca testo e comandi in orizzontale; il pannello sotto la scacchiera scorre se lo spazio non basta.
