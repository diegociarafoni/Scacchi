# Avversario computer

La partita contro il computer usa **Stockfish 19**, eseguito interamente sul dispositivo:
nessuna connessione, nessun server, nessun dato che esce dal telefono.

## Come si gioca

1. Toccare **Nuova partita**.
2. Scegliere **Computer**.
3. Scegliere il colore: Bianco, Nero o a caso. La scacchiera si orienta dal lato del giocatore.
4. Scegliere il livello con il cursore (da 1 a 8).
5. Toccare **Gioca**. Se il giocatore ha il Nero, il computer muove per primo.

Durante la riflessione del computer la scacchiera è bloccata e compare la scritta
"Il computer sta pensando…".

- **Annulla mossa** ritira la mossa del giocatore e la risposta del computer, così il turno
  torna al giocatore. Se il computer sta ancora pensando, la ricerca viene interrotta.
- **Abbandona** fa abbandonare il giocatore, non il computer.
- La rotazione automatica della scacchiera non si applica contro il computer.

## Piattaforme

| Piattaforma | Contro il computer |
|---|---|
| Android | Sì |
| iOS | Sì |
| Windows, macOS, Linux | Non ancora: l'opzione appare disattivata |

Il motore arriva dal plugin [multistockfish](https://github.com/lichess-org/dart-multistockfish)
di Lichess, che oggi supporta solo Android e iOS. Per il desktop si potrà aggiungere in futuro
un'altra implementazione di `UciTransport`, ad esempio un eseguibile Stockfish incluso nell'app.

## Livelli

| # | Nome | Elo indicativo | Come si ottiene |
|---|------|---------------:|-----------------|
| 1 | Principiante | 600 | profondità 1, sceglie tra 6 candidate, temperatura 300 |
| 2 | Esordiente | 900 | profondità 3, 5 candidate, temperatura 160 |
| 3 | Dilettante | 1100 | profondità 5, 4 candidate, temperatura 80 |
| 4 | Giocatore di circolo | 1350 | profondità 8, 3 candidate, temperatura 35 |
| 5 | Agonista | 1600 | limitatore Elo di Stockfish a 1600 |
| 6 | Esperto | 2000 | limitatore Elo a 2000 |
| 7 | Maestro | 2400 | limitatore Elo a 2400 |
| 8 | Campione | ~3000 | piena forza, 2 secondi a mossa |

Il livello predefinito è il 3.

### Perché i livelli bassi funzionano così

Stockfish ha un limitatore di forza (`UCI_LimitStrength` / `UCI_Elo`), ma non scende sotto i
1320 Elo: troppo per un principiante. Per i livelli 1–4 l'app chiede quindi al motore le migliori
N mosse (`MultiPV`) con la loro valutazione e ne sceglie una a caso, con probabilità

```
p(mossa) ∝ exp((valutazione_mossa − valutazione_migliore) / temperatura)
```

Con temperatura alta anche mosse sensibilmente peggiori hanno buone probabilità; con temperatura
bassa quasi sempre esce la migliore. Il risultato sono errori plausibili, come quelli di una
persona, invece di pezzi regalati a caso. Due regole fisse:

- un matto a favore non viene mai scartato;
- con temperatura 0 o una sola candidata si gioca sempre la mossa migliore.

I livelli bassi aspettano inoltre qualche centinaio di millisecondi prima di muovere, perché una
risposta istantanea risulta innaturale.

Gli Elo dei livelli 1–4 sono stime: vanno tarati giocando, modificando i parametri in
`lib/engine/levels.dart`.

## Architettura

```
lib/engine/
  uci.dart            parsing del protocollo UCI (bestmove, info, score)
  levels.dart         definizione degli 8 livelli
  choose.dart         scelta "umana" tra le candidate
  uci_transport.dart  canale verso il motore; StockfishTransport usa multistockfish
  computer_player.dart ComputerPlayer: coda delle richieste, opzioni, ricerca
lib/game/
  new_game_dialog.dart scelta di avversario, colore e livello
  game_page.dart       integrazione nella schermata di gioco
```

- `ComputerPlayer` riceve una posizione FEN e un `EngineLevel` e restituisce un `EngineMove`
  (mossa già nel formato di dartchess, variante prevista, valutazione), oppure `null` se non
  ci sono mosse legali. Non applica la mossa: lo fa `ChessGame`, che resta l'unica fonte delle regole.
- Le richieste vanno in coda: il motore esegue una ricerca alla volta.
- Le opzioni UCI del livello vengono inviate solo quando cambiano.
- `stop()` chiede al motore di rispondere subito. La schermata di gioco scarta le risposte
  arrivate per una posizione non più attuale (dopo un annullamento o una nuova partita).
- Le mosse di arrocco arrivano da Stockfish come `e1g1` e vengono convertite nel formato di
  dartchess (re su torre, `e1h1`).
- `UciTransport` separa la logica dal motore concreto: in produzione `StockfishTransport`,
  nei test un motore finto o un processo Stockfish.

## Test

```sh
flutter test
```

- `test/engine/uci_test.dart`, `choose_test.dart`: parsing e scelta delle mosse.
- `test/engine/computer_player_test.dart`: con un motore finto e, se installato, con Stockfish
  vero (`apt install stockfish`, oppure la variabile `STOCKFISH_PATH`). Senza Stockfish i test
  d'integrazione vengono saltati; in CI Stockfish è installato, quindi girano sempre.
- `test/computer_game_test.dart`: la partita contro il computer nell'interfaccia.

## Licenza

Stockfish è GPL-3.0, come l'app. Il permesso aggiuntivo per la pubblicazione sugli store è
descritto in [NOTICE.md](../NOTICE.md).
