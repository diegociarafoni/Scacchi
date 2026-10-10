# Architettura

## Stack

| Livello | Tecnologia | Ruolo |
|---|---|---|
| Linguaggio e framework | Dart, Flutter (canale stable, 3.47 o successivo) | Un solo codice per Android, iOS, Windows, macOS e Linux |
| Regole degli scacchi | [dartchess](https://pub.dev/packages/dartchess) | Generazione delle mosse legali, notazione SAN, scacco, matto, stallo, materiale insufficiente |
| Scacchiera | [chessground](https://pub.dev/packages/chessground) | Disegno della scacchiera, trascinamento e tocco, animazioni, evidenziazioni, scelta della promozione |
| File locali | [path_provider](https://pub.dev/packages/path_provider) | Cartella dati dell'app per i salvataggi |
| Condivisione | [share_plus](https://pub.dev/packages/share_plus) | Menu di condivisione del sistema per il PGN |

Entrambe le librerie sono sviluppate da Lichess e sono usate dalla sua app mobile.

La piattaforma web non è supportata: `dartchess` usa interi a 64 bit (bitboard) che il compilatore JavaScript di Flutter non può rappresentare.

## Struttura delle cartelle

```
lib/
  main.dart               Avvio dell'app, tema chiaro e scuro
  game/
    chess_game.dart       Stato della partita, senza dipendenze dall'interfaccia
    game_page.dart        Schermata di gioco
  progress/               Gamification: XP, livelli, serie, traguardi (vedi gamification.md)
  archive/                Archivio delle partite e PGN (vedi archivio.md)
  storage/                File JSON locali con versione e scrittura atomica
test/
  chess_game_test.dart    Test delle regole e della fine partita
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
- `endReason` e `outcome` descrivono come e con quale risultato è finita la partita.

`dartchess` non rileva da sola la triplice ripetizione né la regola delle 50 mosse, perché richiedono la cronologia della partita: `ChessGame` le calcola a partire dalla lista delle posizioni. I dettagli sono in [regole-di-gioco.md](regole-di-gioco.md).

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
