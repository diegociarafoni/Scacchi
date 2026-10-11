# Bot con personalità

I bot (requisito RF-23) sono avversari con un nome, un avatar, un Elo, uno stile di gioco,
un'apertura preferita e brevi frasi di reazione. Ogni bot è
costruito sopra uno degli 8 livelli del motore descritti in [avversario-computer.md](avversario-computer.md):
la forza viene dal livello, la personalità dal resto. Sono in `lib/engine/bots.dart`.

## Come si gioca

1. Toccare **Nuova** e scegliere **Bot**.
2. Scegliere il colore e il bot dall'elenco: ogni riga mostra avatar, nome, Elo, stile e apertura preferita.
3. Toccare la cadenza, "Senza tempo" o una cadenza: la partita inizia.

Durante la partita la barra del titolo mostra avatar, nome ed Elo del bot, che saluta all'inizio.
Il bot gioca le prime mosse dal proprio libro d'apertura finché l'avversario non devia (con una breve
attesa, come negli altri livelli); poi decide Stockfish con lo stile del bot. Commenta con una frase
i propri scacchi, ogni tanto le proprie catture, e la fine della partita (vittoria, sconfitta, patta).
Il bot gioca solo gli scacchi classici; le altre regole della partita contro il computer (annulla,
patta, orologio, abbandono) valgono anche qui, vedi [avversario-computer.md](avversario-computer.md).

## La scala e la collezione

Si comincia con Pino: gli altri bot sono bloccati (lucchetto). Battere un bot sblocca il successivo e
lo aggiunge alla **collezione**, dove nell'elenco compare con un segno di spunta e la data della prima
vittoria ("Battuto il 11/10/2026"). Un bot già battuto si può rigiocare quando si vuole. Una partita
conta solo se ha almeno una mossa; perdere o pattare non cambia la collezione. La collezione è salvata
sul dispositivo (chiave `botCollection`, `lib/engine/bot_collection.dart`).

## I bot

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
centipedoni. Un matto a favore non viene mai scartato e si gioca il più breve
(`lib/engine/style.dart`, `lib/engine/choose.dart`).

| Stile | Premia |
|---|---|
| Aggressivo | catture (+40) e scacchi (+40) |
| Posizionale | arrocco (+60) e mosse tranquille, senza catture (+20) |
| Gambettista | mosse che mettono il pezzo su una casa dove perderebbe materiale (+60): attaccato e indifeso, o attaccato da un pezzo di valore minore |

Come lo stile si combina con la forza dipende dal livello su cui è costruito il bot:

| Livelli | Come si ottiene la forza | Effetto dello stile |
|---|---|---|
| 1-4 (Pino, Chiara, Rocco, Marta) | scelta a caso tra le candidate con la temperatura del livello (35-300) | il bonus pesa sulla scelta; con temperature alte resta una tendenza più che una regola |
| 5-7 (Duilio, Elena, Massimo) | limitatore Elo di Stockfish | nessuno sulla mossa, che resta quella del motore alla forza dichiarata; lo stile si vede nel libro e nelle frasi |
| 8 (Stella) | piena forza | il bonus agisce solo tra candidate entro 30 cp dalla migliore, quindi la forza non cala |

## Libro d'apertura

Ogni bot ha due linee d'apertura in UCI dalla posizione iniziale, valide per entrambi i colori:
`Bot.bookMoveFor(posizione iniziale, mosse, random)` restituisce la mossa successiva di una linea
compatibile con la partita finora nel formato di dartchess, scegliendo a caso tra più linee. Le linee
sono in UCI standard (l'arrocco è `e1g1`): la conversione da e verso l'arrocco di dartchess
(re su torre) è in `lib/engine/uci_moves.dart`, la stessa usata per il motore. Se l'avversario devia o la linea finisce,
restituisce `null` e si torna al motore.

## Frasi

`Bot.phrase(evento, random)` restituisce una frase per `BotEvent.start`, `check`, `capture`,
`mistake`, `win`, `loss`, `draw`. Il saluto è proprio del bot e riporta il suo nome; le altre frasi
dipendono dallo stile.

## Test

- `test/engine/bots_test.dart`: scala, dati, linee del libro legali, frasi.
- `test/engine/bot_collection_test.dart`: sblocco, data della prima vittoria, salvataggio.
- `test/bot_game_test.dart`: la scelta del bot nel pannello, il libro in partita, saluto e frasi finali, vittoria e collezione.
- `test/engine/style_test.dart`: i bonus di stile.
- `test/engine/choose_test.dart` e `computer_player_test.dart`: il bonus nella scelta tra candidate.

## Stato

| Requisito | Stato |
|---|---|
| RF-23 bot con personalità | ✓ nome, avatar, Elo, stile, libro d'apertura e frasi su scacco, cattura e fine partita; manca la frase sull'errore, che richiede la valutazione della mossa dell'avversario |
| RG-04 scala dei bot | ✓ sblocco battendo il precedente e collezione con la data della vittoria |
