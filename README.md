# Scacchi

Un'applicazione di scacchi offline, open source e completamente gratuita, per Android, iOS e desktop (Windows, macOS, Linux). Nessuna pubblicità, nessun account, nessun dato che lascia il dispositivo.

## Stato

Prima versione giocabile:

- partita tra due persone sullo stesso dispositivo;
- mosse per trascinamento o con due tocchi, evidenziazione delle mosse legali, dell'ultima mossa e dello scacco;
- promozione con scelta del pezzo;
- fine partita: scacco matto, stallo, materiale insufficiente, triplice ripetizione, regola delle 50 mosse, abbandono;
- annullamento delle mosse, nuova partita, lista delle mosse in notazione algebrica;
- capovolgimento della scacchiera, anche automatico a ogni turno;
- partita contro il computer (Stockfish sul dispositivo, Android e iOS) con 8 livelli di difficoltà.

In arrivo: orologio, salvataggio delle partite e PGN.

La documentazione completa è in [`docs/`](docs/), ad esempio [avversario computer](docs/avversario-computer.md).

## Sviluppo

Serve [Flutter](https://docs.flutter.dev/get-started/install) (canale stable, 3.47 o successivo).

```sh
flutter pub get
flutter run          # sul dispositivo o emulatore collegato
flutter analyze
flutter test
```

Struttura:

- `lib/game/chess_game.dart`: stato della partita e regole di fine partita, senza dipendenze dall'interfaccia.
- `lib/game/game_page.dart`: schermata di gioco.
- `test/`: test delle regole e dell'interfaccia.

Le regole di movimento vengono da [dartchess](https://pub.dev/packages/dartchess) e la scacchiera da [chessground](https://pub.dev/packages/chessground), entrambe librerie di Lichess.

## Licenza

GPL-3.0, vedi [LICENSE](LICENSE), con un permesso aggiuntivo per la pubblicazione sugli store (vedi [NOTICE.md](NOTICE.md)). Le risorse di terze parti sono elencate in [CREDITS.md](CREDITS.md).
