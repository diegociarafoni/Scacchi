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
attesa, come negli altri livelli); poi decide Stockfish con lo stile del bot. Il libro vale solo
nelle partite che partono dalla posizione iniziale, non da una posizione dell'editor. Commenta con una frase
i propri scacchi, ogni tanto le proprie catture, e la fine della partita (vittoria, sconfitta, patta).
Il bot gioca solo gli scacchi classici; le altre regole della partita contro il computer (annulla,
patta, orologio, abbandono) valgono anche qui, vedi [avversario-computer.md](avversario-computer.md).

## La scala e la collezione

Si comincia con Pino: gli altri bot sono bloccati (lucchetto). Battere un bot sblocca il successivo e
lo aggiunge alla **collezione**, dove nell'elenco compare con un segno di spunta e la data della prima
vittoria ("Battuto il 11/10/2026"). Un bot già battuto si può rigiocare quando si vuole. Una partita
conta solo se ha almeno una mossa ed è partita dalla posizione iniziale; perdere o pattare non cambia la collezione. La collezione è salvata
sul dispositivo (chiave `botCollection`, `lib/engine/bot_collection.dart`).

## Computer o bot?

Nella schermata Nuova partita una riga sotto la scelta spiega l'avversario selezionato: **Computer** è un avversario senza volto di cui si sceglie il livello (o si lascia che si adatti), **Bot** è un personaggio con nome, stile e apertura preferita, da sbloccare uno alla volta. Ogni bot bloccato dice quale bot battere per sbloccarlo («Si sblocca battendo Pino»). I testi sono localizzati (`opponentHint*`, `botUnlockHint` in `lib/l10n`).

## I bot

Gli 8 bot sono in ordine di forza e formano la scala da superare uno dopo l'altro (RG-04).

| # | Bot | Livello | Elo indicativo | Stile | Apertura preferita |
|---|-----|--------:|---------------:|-------|--------------------|
| 1 | Pino 🐣 | 1 | 700 | aggressivo | Italiana |
| 2 | Chiara 🌼 | 2 | 900 | posizionale | Gambetto di Donna |
| 3 | Rocco 🦊 | 3 | 1150 | gambettista | Gambetto di Re |
| 4 | Marta 🦉 | 4 | 1400 | posizionale | Inglese |
| 5 | Duilio 🔥 | 5 | 1600 | aggressivo | Siciliana |
| 6 | Elena 🦅 | 6 | 1850 | posizionale | Spagnola |
| 7 | Massimo 🐺 | 7 | 2250 | gambettista | Gambetto Evans |
| 8 | Stella ⭐ | 8 | 2700 | aggressivo | Difesa Est-Indiana |

### Tino, solo nella Storia

Tino 🐥 è il custode del Capitolo 0: livello 0, 400 Elo, scelta tra molte mosse con temperatura 600. Sta in `storyOnlyBots` e non nella scala: non si sblocca, non gioca nei tornei e non compare nella schermata Nuova partita. `botById` lo trova.

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
| 1-4 (Pino, Chiara, Rocco, Marta) | scelta a caso tra le candidate con la temperatura del livello (80-320) | il bonus pesa sulla scelta; con temperature alte resta una tendenza più che una regola |
| 5-6 (Duilio, Elena) | limitatore Elo di Stockfish | nessuno sulla mossa, che resta quella del motore alla forza dichiarata; lo stile si vede nel libro e nelle frasi |
| 7-8 (Massimo, Stella) | piena forza (profondità 10 e 2 secondi) | il bonus agisce solo tra candidate entro 30 cp dalla migliore, quindi la forza non cala |

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

## Profilo bambino

Con il profilo bambino attivo (RP-06, vedi [profilo-bambino.md](profilo-bambino.md)) si gioca solo contro
i bot amichevoli, `friendlyBots`: i primi tre della scala (Pino, Chiara, Rocco). L'elenco mostra avatar,
nome e una breve descrizione (chiavi `kidBot...Description` nei file `.arb`) al posto di Elo, stile e
apertura; la scala con i lucchetti resta, la spunta del bot battuto non riporta la data. Il titolo della
partita non mostra l'Elo. `GameSetup.forKids()` trasforma una scelta del computer o di un bot più forte in
una partita contro Pino. Una partita già iniziata non cambia se il profilo si attiva o si disattiva a metà:
le frasi seguono il profilo attivo all'inizio; l'Elo nel titolo resta nascosto finché il profilo è attivo, e per tutta la partita se è iniziata con il profilo. Le descrizioni sono in `friendlyBotDescriptions`.

Le frasi sono quelle di `Bot.phrases(evento, friendly: true)`: brevi, uguali per tutti gli stili e senza
prese in giro (niente «Grazie del regalo» o «hai sbagliato»); il saluto riporta il nome del bot ma non
l'apertura.

## Test

- `test/engine/bots_test.dart`: scala, dati, linee del libro legali, frasi.
- `test/engine/bot_collection_test.dart`: sblocco, data della prima vittoria, salvataggio.
- `test/bot_game_test.dart`: la scelta del bot nel pannello, il libro in partita, saluto e frasi finali, vittoria e collezione.
- `test/engine/style_test.dart`: i bonus di stile.
- `test/engine/kid_bots_test.dart`, `test/game/kid_opponent_picker_test.dart` e `test/kid_bot_game_test.dart`: i bot amichevoli del profilo bambino.
- `test/engine/choose_test.dart` e `computer_player_test.dart`: il bonus nella scelta tra candidate.

## Stato

| Requisito | Stato |
|---|---|
| RF-23 bot con personalità | ✓ nome, avatar, Elo, stile, libro d'apertura e frasi su scacco, cattura e fine partita; manca la frase sull'errore, che richiede la valutazione della mossa dell'avversario |
| RG-04 scala dei bot | ✓ sblocco battendo il precedente e collezione con la data della vittoria |
