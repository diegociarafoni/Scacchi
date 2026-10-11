# Bot con personalità

I bot (requisito RF-23) sono avversari con un nome, un avatar, un Elo, uno stile di gioco,
un'apertura preferita e brevi frasi di reazione, sul modello dei bot di chess.com. Ogni bot è
costruito sopra uno degli 8 livelli del motore descritti in [avversario-computer.md](avversario-computer.md):
la forza viene dal livello, la personalità dal resto. Sono in `lib/engine/bots.dart`.

## La scala

Gli 8 bot sono in ordine di forza e formano la scala da superare uno dopo l'altro (RG-04).

| # | Bot | Livello | Elo indicativo | Stile | Apertura preferita |
|---|-----|--------:|---------------:|-------|--------------------|
| 1 | Pino 🐣 | 1 | 600 | aggressivo | Italiana |
| 2 | Chiara 🌼 | 2 | 900 | posizionale | Gambetto di Donna |
| 3 | Rocco 🦊 | 3 | 1100 | gambettista | Gambetto di Re |
| 4 | Marta 🦉 | 4 | 1350 | posizionale | Inglese |
| 5 | Duilio 🔥 | 5 | 1600 | aggressivo | Siciliana |
| 6 | Elena 🦅 | 6 | 2000 | posizionale | Spagnola |
| 7 | Massimo 🐺 | 7 | 2400 | gambettista | Gambetto Evans |
| 8 | Stella ⭐ | 8 | ~3000 | aggressivo | Difesa Est-Indiana |

## Stile di gioco

Lo stile non cambia la forza del motore: sposta la scelta tra le prime candidate. Il bot chiede a
Stockfish almeno tre varianti (`MultiPV`) e somma alla valutazione di ciascuna un bonus in
centipedoni, poi sceglie con una piccola variabilità (temperatura 25). Un matto a favore non viene
mai scartato (`lib/engine/style.dart`).

| Stile | Premia |
|---|---|
| Aggressivo | catture (+40) e scacchi (+40) |
| Posizionale | arrocco (+60) e mosse tranquille, senza catture (+20) |
| Gambettista | mosse che mettono il pezzo su una casa attaccata, senza catturare (+60), cioè offrono materiale |

I bonus sono volutamente piccoli: un bot posiziona i pezzi a modo suo ma non regala la partita.
Nei livelli alti la differenza si vede poco, perché le candidate sono molto vicine tra loro.

## Libro d'apertura

Ogni bot ha due linee d'apertura in UCI dalla posizione iniziale, valide per entrambi i colori:
`Bot.bookMove(storia, random)` restituisce la mossa successiva di una linea compatibile con la
partita finora, scegliendo a caso tra più linee. Se l'avversario devia o la linea finisce,
restituisce `null` e si torna al motore.

## Frasi

`Bot.phrase(evento, random)` restituisce una frase per `BotEvent.start`, `check`, `capture`,
`mistake`, `win`, `loss`, `draw`. Il saluto è proprio del bot e riporta il suo nome; le altre frasi
dipendono dallo stile.

## Test

- `test/engine/bots_test.dart`: scala, dati, linee del libro legali, frasi.
- `test/engine/style_test.dart`: i bonus di stile.
- `test/engine/choose_test.dart` e `computer_player_test.dart`: il bonus nella scelta tra candidate.

## Stato

| Requisito | Stato |
|---|---|
| RF-23 bot con personalità | Dati, stile, libro e frasi pronti; manca la scelta del bot e la visualizzazione nella partita |
| RG-04 scala dei bot | Scala definita; mancano lo sblocco battendo il precedente e la collezione |
