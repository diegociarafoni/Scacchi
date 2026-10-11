# Architettura

## Stack

| Livello | Tecnologia | Ruolo |
|---|---|---|
| Linguaggio e framework | Dart, Flutter (canale stable, 3.47 o successivo) | Un solo codice per Android, iOS, Windows, macOS e Linux |
| Regole degli scacchi | [dartchess](https://pub.dev/packages/dartchess) | Generazione delle mosse legali, notazione SAN, scacco, matto, stallo, materiale insufficiente |
| Salvataggio impostazioni | [shared_preferences](https://pub.dev/packages/shared_preferences) | Memorizzazione locale delle impostazioni |
| Audio | [audioplayers](https://pub.dev/packages/audioplayers) | Riproduzione dei suoni |
| Scacchiera | [chessground](https://pub.dev/packages/chessground) | Disegno della scacchiera, trascinamento e tocco, animazioni, evidenziazioni, scelta della promozione |
| File locali | [path_provider](https://pub.dev/packages/path_provider) | Cartella dati dell'app per i salvataggi |
| Condivisione | [share_plus](https://pub.dev/packages/share_plus) | Menu di condivisione del sistema per il PGN |

Entrambe le librerie sono sviluppate da Lichess e sono usate dalla sua app mobile.

La piattaforma web non è supportata: `dartchess` usa interi a 64 bit (bitboard) che il compilatore JavaScript di Flutter non può rappresentare.

## Struttura delle cartelle

```
lib/
  main.dart               Avvio dell'app, tema chiaro e scuro
  home/home_shell.dart    Barra di navigazione in basso (Gioca, Puzzle, Aperture)
  game/
    chess_game.dart       Stato della partita, senza dipendenze dall'interfaccia
    variant.dart          Varianti e posizioni iniziali Chess960 (vedi regole-di-gioco.md)
    material.dart         Pezzi catturati e vantaggio di materiale
    clock.dart            Cadenze e orologio a due lati
    sounds.dart           Scelta e riproduzione di suoni e vibrazione
    move_label.dart       Numerazione delle mosse nella lista
    move_input.dart       Lettura di una mossa scritta (SAN inglese o italiana, UCI)
    move_speech.dart      Frase da annunciare al lettore di schermo per ogni mossa
    game_page.dart        Schermata di gioco
  progress/               Gamification: XP, livelli, serie, traguardi (vedi gamification.md)
  archive/                Archivio delle partite e PGN (vedi archivio.md)
  path/                   Percorso a tappe con stelle (vedi percorso.md)
  stats/                  Statistiche e rating locale (vedi statistiche.md)
  minigames/              Minigiochi di allenamento (vedi minigiochi.md)
  tournament/             Tornei offline contro bot (vedi tornei.md)
  storage/                File JSON locali con versione e scrittura atomica
  settings/
    settings.dart         Impostazioni, valori predefiniti e salvataggio locale
    settings_page.dart    Schermata delle impostazioni
  puzzles/                Puzzle: modello, punteggio, schermate (vedi puzzle.md)
  openings/               Aperture: libro, nome in partita, explorer, repertorio (vedi aperture.md)
  training/               Scacchiera per esercizi condivisa
assets/
  puzzles/puzzles.csv     Puzzle Lichess inclusi (CC0)
  openings/openings.tsv   Nomi delle aperture Lichess (CC0)
tool/datasets/            Script che generano i dataset in assets/
test/
  chess_game_test.dart    Test delle regole e della fine partita
  material_test.dart      Test del materiale catturato
  clock_test.dart         Test di cadenze, orologio e tempo scaduto
  sound_test.dart         Test della scelta del suono per ogni mossa
  move_label_test.dart    Test della numerazione delle mosse
  move_input_test.dart    Test della lettura delle mosse scritte
  move_speech_test.dart   Test delle frasi per il lettore di schermo
assets/sounds/            Suoni dell'app (WAV)
tool/generate_sounds.py   Generatore dei suoni
  settings_test.dart      Test delle impostazioni e del salvataggio
  training/               Test della scacchiera per esercizi
  widget_test.dart        Test di avvio dell'interfaccia
integration_test/
  app_test.dart           Test end-to-end sull'app reale
docs/                     Questa documentazione
android/ ios/ linux/ macos/ windows/
                          Progetti nativi generati da Flutter
.github/workflows/ci.yml  Integrazione continua
```

## Componenti

### `ChessGame` (`lib/game/chess_game.dart`)

Modello della partita, in Dart puro e quindi testabile senza interfaccia.

- Conserva la posizione iniziale e la lista delle mosse giocate (`PlayedMove`: mossa, notazione SAN, posizione risultante).
- `play(move)` accetta solo mosse legali e rifiuta qualsiasi mossa a partita conclusa.
- `undo()` revoca l'abbandono o la patta concordata, se presenti; altrimenti annulla l'ultima mossa.
- `agreeDraw()` chiude la partita con una patta concordata.
- `resign(side)` registra l'abbandono del lato indicato.
- `ChessGame.replay(initial, moves)` ricostruisce una partita già giocata (import PGN) senza fermarsi a ripetizioni o 50 mosse non reclamate.
- `endReason` e `outcome` descrivono come e con quale risultato è finita la partita.

`dartchess` non rileva da sola la triplice ripetizione né la regola delle 50 mosse, perché richiedono la cronologia della partita: `ChessGame` le calcola a partire dalla lista delle posizioni. I dettagli sono in [regole-di-gioco.md](regole-di-gioco.md).

### `MaterialBalance` (`lib/game/material.dart`)

Calcola da una partita i pezzi catturati da ciascun lato, ripercorrendo le mosse (comprese le prese en passant), e la differenza di materiale presente sulla scacchiera. È Dart puro e si testa senza interfaccia.

### Orologio (`lib/game/clock.dart`)

`TimeControl` descrive una cadenza (minuti e incremento). `ChessClock` tiene il tempo residuo dei due lati e fa scorrere solo quello del lato attivo; l'ora corrente è iniettabile per i test. Offre istantanee e ripristino, usate da `GamePage` per annullare le mosse. `GamePage` aggiorna la visualizzazione ogni 100 ms ridisegnando solo gli orologi, registra il tempo scaduto con `ChessGame.flag` e ferma l'orologio a fine partita.

### Suoni (`lib/game/sounds.dart`)

`soundForLastMove` sceglie l'effetto dell'ultima mossa a partire dalla posizione precedente, in Dart puro. `SoundPlayer` riproduce l'effetto con un lettore a bassa latenza per suono e, se attiva, la vibrazione tramite `HapticFeedback`; un errore di riproduzione non interrompe la partita.

### Mossa scritta e annunci (`lib/game/move_input.dart`, `move_speech.dart`)

`parseMoveInput` prova il testo come UCI, poi come SAN inglese e come SAN con le iniziali italiane (R re, D donna, T torre, A alfiere, C cavallo) tramite `Position.parseSan` di dartchess. Se le due letture danno mosse legali diverse restituisce `MoveInputAmbiguous`. `describeSan` trasforma la SAN in una frase italiana che `GamePage` invia con `SemanticsService.sendAnnouncement` dopo ogni mossa.

### Impostazioni (`lib/settings/`)

`AppSettings` è un valore immutabile con tutte le opzioni e la loro traduzione in `ChessboardSettings` di chessground. `SettingsController` lo carica all'avvio da `shared_preferences`, lo espone come `ValueNotifier` e lo salva a ogni modifica; valori salvati sconosciuti o di tipo errato tornano al predefinito, e se la memoria locale non è disponibile l'app parte con i valori predefiniti. Vengono scritti solo i valori modificati. L'app carica le impostazioni prima di mostrare la partita, e `GamePage` si ridisegna quando cambiano. `SettingsScope` (un `InheritedNotifier` messo nel `builder` di `MaterialApp`, sopra il Navigator) espone le stesse impostazioni a tutte le pagine: `TrainingBoard` lo legge, così puzzle, esploratore e repertorio seguono le scelte dell'utente senza ricevere il controller come parametro. Fuori dall'app, per esempio nei test, usa i valori predefiniti.

### `GamePage` (`lib/game/game_page.dart`)

Schermata di gioco. Possiede un `ChessGame` e un `ChessboardController` di chessground.

Flusso di una mossa:

1. Il giocatore muove un pezzo sulla scacchiera; chessground consente solo le mosse legali che riceve in `GameData.validMoves` e gestisce da sé la scelta del pezzo di promozione.
2. chessground chiama `onMove` con la mossa completa.
3. `GamePage` passa la mossa a `ChessGame.play`.
4. Se la mossa è accettata, `GamePage` costruisce un nuovo `GameData` (posizione, ultima mossa, re sotto scacco, mosse legali) e aggiorna il controller; poi ridisegna lista mosse, stato e comandi.

A partita conclusa `GameData.playerSide` vale `PlayerSide.none`, quindi la scacchiera non accetta altre mosse.

## Evoluzioni previste

- Il motore Stockfish per la partita contro il computer si aggancerà a `GamePage` come secondo giocatore, ricevendo la posizione FEN e restituendo una mossa da passare a `ChessGame.play`.
