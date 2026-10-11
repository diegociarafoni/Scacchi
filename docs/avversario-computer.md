# Avversario computer

La partita contro il computer usa **Stockfish 19**, eseguito interamente sul dispositivo:
nessuna connessione, nessun server, nessun dato che esce dal telefono.

## Come si gioca

1. Toccare **Nuova**.
2. Scegliere **Computer**.
3. Scegliere il colore: Bianco, Nero o a caso. La scacchiera si orienta dal lato del giocatore.
4. Scegliere il livello con il cursore (da 1 a 8).
5. Toccare la cadenza, "Senza tempo" o una cadenza (vedi [interfaccia.md](interfaccia.md)): la partita inizia. Se il giocatore ha il Nero, il computer muove per primo.

Contro il computer si gioca solo la variante classica e senza nomi dei giocatori: varianti e nomi compaiono nel pannello solo scegliendo **Due giocatori**. Anche una posizione creata con l'editor (vedi [editor-posizione.md](editor-posizione.md)) si gioca in due: aprire l'editor durante una partita contro il computer la chiude.

Durante la riflessione del computer la scacchiera è bloccata e compare la scritta
"Il computer sta pensando…".

- **Annulla** ritira la mossa del giocatore e la risposta del computer, così il turno
  torna al giocatore. Se il computer sta ancora pensando, la ricerca viene interrotta.
- **Abbandona** fa abbandonare il giocatore, non il computer.
- **Annulla** dopo un abbandono o una patta concordata riapre la partita senza togliere mosse.
- **Patta**: il computer valuta la posizione attuale a piena forza e accetta solo se si giudica in svantaggio di almeno mezzo pedone (50 centipedoni); altrimenti rifiuta (requisito RF-25). Durante la valutazione compare "Il computer valuta la patta…" e la scacchiera è bloccata.
- Se il motore non risponde, o propone una mossa che le regole rifiutano, compare il messaggio "Il computer non risponde." con il pulsante **Riprova**, sopra la barra dei comandi; il motore viene riavviato alla richiesta successiva. Il messaggio sparisce con una nuova partita o un annullamento.
- La patta si può offrire solo nel proprio turno.
- La rotazione automatica della scacchiera è disattivata contro il computer.
- Con l'orologio, il tempo del computer scorre mentre pensa e riceve l'incremento come il giocatore; se il tempo scade durante la riflessione la ricerca viene interrotta. **Annulla** ripristina gli orologi di entrambe le mosse ritirate, anche dopo un tempo scaduto alla prima mossa.
- Con l'orologio il computer non pensa più di un trentesimo del tempo residuo più tre quarti dell'incremento (minimo 50 ms): riflessione e ritardo artificiale del livello vengono ridotti di conseguenza (`EngineLevel.withinClock`), così anche il livello 8 non perde per tempo nelle cadenze brevi.
- Mentre è aperta una finestra (nuova partita, abbandono, patta) o l'app è in background, orologio e computer sono fermi: la ricerca in corso viene interrotta, il suo tempo restituito al computer, e riparte alla chiusura o al ritorno nell'app.
- Mentre il computer valuta una patta l'orologio è fermo, perché il giocatore non può muovere. Se il motore non risponde, l'orologio del computer resta fermo, senza il tempo della ricerca fallita, fino a **Riprova**.

## Piattaforme

| Piattaforma | Contro il computer |
|---|---|
| Android | Sì |
| iOS | Sì |
| Windows, macOS, Linux | Sì, se Stockfish è installato; altrimenti l'opzione appare disattivata |

Su Android e iOS il motore arriva dal plugin [multistockfish](https://github.com/lichess-org/dart-multistockfish)
di Lichess (Stockfish 19 incluso nell'app). Sui computer l'app usa lo Stockfish installato,
avviato come processo esterno (`ProcessTransport`): lo cerca in `STOCKFISH_PATH`, poi nelle
cartelle di `PATH` (`stockfish.exe` su Windows), poi in `/usr/games`, `/usr/bin`, `/usr/local/bin`
e `/opt/homebrew/bin`. Per installarlo: `sudo apt install stockfish` su Debian e Ubuntu,
`brew install stockfish` su macOS, l'eseguibile di [stockfishchess.org](https://stockfishchess.org/download/)
su Windows. La ricerca avviene una volta all'avvio dell'app.

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
  uci_transport.dart  canale verso il motore; StockfishTransport usa multistockfish o il processo
  process_transport.dart Stockfish installato sul computer, come processo esterno
  computer_player.dart ComputerPlayer: coda delle richieste, opzioni, ricerca
lib/game/
  opponent_picker.dart scelta di avversario, colore e livello
  game_page.dart       integrazione nella schermata di gioco
```

- `ComputerPlayer.bestMove` riceve la posizione iniziale (FEN), la cronologia delle mosse e un `EngineLevel` e restituisce un `EngineMove`
  (mossa già nel formato di dartchess, variante prevista, valutazione), oppure `null` se non
  ci sono mosse legali. Non applica la mossa: lo fa `ChessGame`, che resta l'unica fonte delle regole.
- Al motore si invia `position fen <iniziale> moves ...`: con la cronologia Stockfish riconosce le ripetizioni, come fa `ChessGame`.
- `ComputerPlayer.evaluate` valuta una posizione a piena forza (300 ms), usata per decidere sulla patta.
- Le richieste vanno in coda: il motore esegue una ricerca alla volta.
- Dopo un errore (timeout, avvio fallito) il motore viene chiuso e la richiesta successiva ne avvia uno nuovo, così una risposta tardiva non viene scambiata per quella di una nuova ricerca. `dispose()` fa fallire subito le richieste in corso.
- Le opzioni UCI del livello vengono inviate solo quando cambiano.
- `stop()` fa terminare subito la ricerca in corso e quelle già in coda (che diventano ricerche a profondità 1), senza il ritardo artificiale dei livelli bassi. La schermata di gioco scarta le risposte
  arrivate per una posizione non più attuale (dopo un annullamento o una nuova partita).
- L'arrocco viaggia come `e1g1` verso e da Stockfish e come re su torre (`e1h1`) in dartchess;
  `ComputerPlayer` converte in entrambe le direzioni.
- Su Android e iOS `Stockfish.create()` ammette un solo motore alla volta: se il precedente non ha
  ancora liberato il posto, l'avvio riprova ogni mezzo secondo per circa dieci secondi.
- Se il motore si chiude o va in errore, le richieste in corso falliscono subito invece di attendere il timeout.
- Per la scelta "umana" si usano le candidate dell'ultima iterazione completa (la profondità più alta in cui il motore ha valutato tutte le varianti), così non si confrontano valutazioni di profondità diverse.
- Passando a una partita tra due persone il motore viene chiuso, liberando memoria.
- `UciTransport` separa la logica dal motore concreto: in produzione `StockfishTransport`,
  nei test un motore finto o un processo Stockfish.

## Test

```sh
flutter test
```

- `test/engine/uci_test.dart`, `choose_test.dart`: parsing e scelta delle mosse.
- `test/engine/stockfish_location_test.dart`: ricerca di Stockfish sui computer.
- `test/engine/computer_player_test.dart`: con un motore finto e, se installato, con Stockfish
  vero (`apt install stockfish`, oppure la variabile `STOCKFISH_PATH`). Senza Stockfish i test
  d'integrazione vengono saltati; in CI Stockfish è installato, quindi girano sempre.
- `test/computer_game_test.dart`: la partita contro il computer nell'interfaccia, con un motore finto.
- `integration_test/computer_test.dart`: test end-to-end sull'app desktop contro un vero Stockfish
  (colore, livello, scacchiera bloccata, annullamento, patta), con lo Stockfish installato.

Nuove funzioni del computer si sviluppano partendo dai test, con nel nome il requisito
(vedi [sviluppo.md](sviluppo.md)).

## Requisiti coperti

| Requisito | Stato |
|---|---|
| RF-20 scelta di colore e livello | ✓ (8 livelli, Elo indicativo 600–3000) |
| RF-21 motore in isolate separato, ritardo artificiale ai livelli bassi | ✓ |
| RF-25 patta accettata dal bot in base alla valutazione | ✓ |
| RNF-03 Stockfish nativo via FFI in isolate, 1 thread | ✓ (Android, iOS) |
| RF-22 modalità Allenamento (suggerimento, barra di valutazione) | Da fare: `EngineMove` espone già variante e valutazione |
| RF-23 bot con personalità | Da fare: lo stile si può ottenere con `chooseCandidate` e un libro d'apertura |
| RF-26 avversario adattivo | Da fare |

## Licenza

Stockfish è GPL-3.0, come l'app. Il permesso aggiuntivo per la pubblicazione sugli store è
descritto in [NOTICE.md](../NOTICE.md).
