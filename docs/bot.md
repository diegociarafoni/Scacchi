# Bot con personalità

I bot (requisito RF-23) sono avversari con un nome, un avatar, un Elo, uno stile di gioco,
un'apertura preferita e brevi frasi di reazione. Ogni bot è
costruito sopra uno dei livelli del motore (gli 8 della scala più il livello 0 a 400 Elo) descritti in [avversario-computer.md](avversario-computer.md):
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

I bot sono 17, in ordine di Elo non decrescente, e più bot possono avere lo stesso Elo (a parità l'ordine è quello dell'elenco). Si comincia con i bot dei due gradini più bassi (Lia a 400, Pino e Nico a 700): gli altri sono bloccati (lucchetto). Battere un bot qualunque di un gradino sblocca tutti i bot del gradino di Elo successivo (`BotCollection.isUnlocked`, `unlockedBy`); chi aveva già battuto Pino, Chiara e così via non perde l'accesso a nessun bot. Ogni vittoria aggiunge il bot alla **collezione**, dove nell'elenco compare con un segno di spunta e la data della prima
vittoria ("Battuto il 11/10/2026"). Un bot già battuto si può rigiocare quando si vuole. Una partita
conta solo se ha almeno una mossa ed è partita dalla posizione iniziale; perdere o pattare non cambia la collezione. La collezione è salvata
sul dispositivo (chiave `botCollection`, `lib/engine/bot_collection.dart`).

## Computer o bot?

Nella pagina «Partita personalizzata» del foglio Nuova partita una riga sotto la scelta spiega l'avversario selezionato (dal menu, **Scegli il bot** apre direttamente la galleria): **Bot** raccoglie due tipi di avversario: **Adattivo**, in cima alla lista, è il motore senza volto che segue i tuoi risultati (non c'è nel profilo bambino), e i bot, ciascuno un personaggio con nome, stile e apertura preferita, da sbloccare uno alla volta. Ogni bot bloccato dice quale bot battere per sbloccarlo («Si sblocca battendo Pino»). I testi sono localizzati (`opponentHint*`, `botUnlockHint` in `lib/l10n`).

## I bot

I 17 bot sono in ordine di Elo e formano la scala da superare a gradini (RG-04).

| # | Bot | Livello | Elo indicativo | Stile | Apertura preferita |
|---|-----|--------:|---------------:|-------|--------------------|
| 1 | Lia 🦋 | 0 | 400 | gambettista | Gambetto di Re |
| 2 | Pino 🐣 | 1 | 700 | aggressivo | Italiana |
| 3 | Nico 🐢 | 1 | 700 | posizionale | Sistema Londra |
| 4 | Chiara 🌼 | 2 | 900 | posizionale | Gambetto di Donna |
| 5 | Viola 🎻 | 2 | 900 | aggressivo | Scozzese |
| 6 | Rocco 🦊 | 3 | 1150 | gambettista | Gambetto di Re |
| 7 | Ettore 🦁 | 3 | 1150 | aggressivo | Spagnola di cambio |
| 8 | Marta 🦉 | 4 | 1400 | posizionale | Inglese |
| 9 | Bruna 🐻 | 4 | 1400 | posizionale | Difesa Francese |
| 10 | Duilio 🔥 | 5 | 1600 | aggressivo | Siciliana |
| 11 | Carlo 🦝 | 5 | 1600 | gambettista | Gambetto Budapest |
| 12 | Elena 🦅 | 6 | 1850 | posizionale | Spagnola |
| 13 | Ada 🔭 | 6 | 1850 | posizionale | Inglese |
| 14 | Luna 🐇 | 6 | 1850 | posizionale | Catalana |
| 15 | Massimo 🐺 | 7 | 2250 | gambettista | Gambetto Evans |
| 16 | Cosmo 🐈 | 7 | 2250 | aggressivo | Scozzese |
| 17 | Stella ⭐ | 8 | 2700 | aggressivo | Difesa Est-Indiana |

Lia gioca al livello 0 (400 Elo), lo stesso di Tino; gli altri nuovi bot riusano i livelli esistenti, quindi non servono nuove calibrazioni. Le frasi dipendono dallo stile, non dal bot: i nuovi bot non ne hanno di proprie.

### Tino, solo nella Storia

Tino 🐥 è il custode del Capitolo 0: livello 0, 400 Elo, scelta tra molte mosse con temperatura 600. Sta in `storyOnlyBots` e non nella scala: non si sblocca e non compare nella schermata Nuova partita. I tornei non usano i bot ma i livelli del motore. `botById` lo trova.

## La galleria dei bot (RG-18)

Dalla scelta dell'avversario, con **Bot** selezionato, il bottone «Apri la galleria dei bot» apre `BotGalleryPage` (`lib/bot_gallery/`), che restituisce con «Gioca» un `BotGalleryResult` (bot, colore, e se si è scelto il computer adattivo). `BotGalleryResult.applyTo(GameSetup)` lo riporta nella configurazione della partita; un'altra schermata può aprire la galleria con `Navigator.push<BotGalleryResult>` e il testo del bottone di conferma in `confirmLabel`.

Struttura, dall'alto:

- **Il bot scelto**: avatar grande con l'espressione dello stato (saluto, contento se già battuto, neutro se bloccato), fumetto con la battuta nel carattere del bot, nome, Elo e stile. Un bot bloccato si vede lo stesso, dice come si sblocca e il bottone «Gioca» è spento.
- **Le fasce** (`lib/bot_gallery/bot_tiers.dart`), per Elo: Neofita (fino a 799), Principiante (800-1299), Intermedio (1300-1699), Avanzato (1700-2099), Maestro (da 2100). Ogni bot è una cella con lucchetto se bloccato e corona se già battuto; la cella scelta ha il bordo evidenziato.
- **Adattivo**: la carta del computer che si adatta ai risultati (RF-26), con l'Elo del livello attuale.
- **I custodi della Storia**: i nove custodi dei capitoli con una barra di avanzamento «n di 9 custodi incontrati»; un custode è incontrato quando il capitolo ha il bot battuto. Tino, che sta solo nella Storia, si può scegliere dopo il Capitolo 0 (`storyOnlyBots`). La galleria legge la Storia da sola (`loadStory`).
- **Colore** in basso: Bianco, a sorte (predefinito), Nero, sempre accanto a «Gioca».
- **Opzioni**: il bottone «Opzioni» in basso apre un pannello a comparsa con le opzioni della partita, che si scelgono dopo aver scelto chi sfidare: cadenza (Nessun timer, Bullet, Blitz, Rapid), variante (classica, Chess960, Re della collina, Tre scacchi), handicap (pezzo in meno, tempo di chi concede e chi concede, come nel foglio «Nuova partita»; il pezzo in meno vale solo nella classica) e l'allenatore acceso dall'inizio. Le scelte sono in `GameOptions` (`lib/bot_gallery/game_options.dart`) dentro il `BotGalleryResult`. Nel profilo bambino il pannello ha solo «Nessun timer» e la cadenza lenta 15+10. Quando la galleria si apre dal foglio «Nuova partita» (`OpponentPicker.onGalleryPlay`), «Gioca» avvia direttamente la partita con queste opzioni: per i bot il foglio non le ripete. Aperta senza `onGalleryPlay` (per esempio dalla scelta dell'avversario di una posizione dell'editor) la galleria nasconde «Opzioni» e restituisce solo bot e colore (`showOptions: false`). Non esiste ancora una barra di valutazione: non c'è fra le opzioni.

I saluti e le battute di rivincita di ogni bot, e tutti i testi della galleria, sono in `lib/l10n/<lingua>/bot_gallery.arb` (italiano e inglese); `lib/bot_gallery/bot_greetings.dart` li associa agli id. Ogni bot ha un personaggio disegnato in codice con le sei espressioni (`lib/progress/avatar_art.dart`, `guardianCharacter`): Lia farfalla, Nico tartaruga, Viola fiore viola con nota, Ettore leone, Bruna orsa, Carlo procione, Ada con gli occhiali, Luna coniglio lunare, Cosmo gatto astronauta, Tino pulcino nel guscio.

Profilo bambino: solo i tre bot amici in una fascia «I tuoi amici», senza Elo, Adattivo né custodi. Accessibilità: ogni cella è un bottone con nome, Elo e stato («bloccato», «battuto», «disponibile») letti dai lettori di schermo; bersagli da almeno 48 dp; nessun overflow col testo al 130%. Il layout orizzontale fa scorrere anche il bot in alto.

Golden in `test/golden/bot_gallery_golden_test.dart` (tre dimensioni di telefono, tema chiaro e scuro, testo al 130%, inglese, bambino, bot bloccato, tabella dei personaggi con le sei espressioni).

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
| 0-4 (Lia, Pino, Nico, Chiara, Viola, Rocco, Ettore, Marta, Bruna) | scelta a caso tra le candidate con la temperatura del livello (80-320) | il bonus pesa sulla scelta; con temperature alte resta una tendenza più che una regola |
| 5-6 (Duilio, Carlo, Elena, Ada, Luna) | limitatore Elo di Stockfish | nessuno sulla mossa, che resta quella del motore alla forza dichiarata; lo stile si vede nel libro e nelle frasi |
| 7-8 (Massimo, Cosmo, Stella) | piena forza (profondità 10 e 2 secondi) | il bonus agisce solo tra candidate entro 30 cp dalla migliore, quindi la forza non cala |

## Libro d'apertura

Ogni bot ha due linee d'apertura in UCI dalla posizione iniziale, valide per entrambi i colori:
`Bot.bookMoveFor(posizione iniziale, mosse, random)` restituisce la mossa successiva di una linea
compatibile con la partita finora nel formato di dartchess, scegliendo a caso tra più linee. Le linee
sono in UCI standard (l'arrocco è `e1g1`): la conversione da e verso l'arrocco di dartchess
(re su torre) è in `lib/engine/uci_moves.dart`, la stessa usata per il motore. Se l'avversario devia o la linea finisce,
restituisce `null` e si torna al motore.

## Frasi

`Bot.phrase(evento, random)` restituisce una frase per `BotEvent.start`, `check`, `capture`,
`mistake`, `win`, `loss`, `draw`, `chat` (battute di compagnia, ogni tanto dopo una mossa del bot). Il saluto è proprio del bot e riporta il suo nome; le altre frasi
dipendono dallo stile.

## Profilo bambino

Con il profilo bambino attivo (RP-06, vedi [profilo-bambino.md](profilo-bambino.md)) si gioca solo contro
i bot amichevoli, `friendlyBots`: Pino, Chiara e Rocco (`friendlyBots`, scelti per id). L'elenco mostra avatar,
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
- `test/engine/bot_collection_test.dart`: sblocco per gradino di Elo, compatibilità con le collezioni già salvate, data della prima vittoria, salvataggio.
- `test/bot_game_test.dart`: la scelta del bot nel pannello, il libro in partita, saluto e frasi finali, vittoria e collezione.
- `test/bot_gallery/`: fasce, saluti in italiano e inglese, la pagina della galleria (scelta, blocchi, corone, custodi, Adattivo, bambino, accessibilità) e l'entrata dalla scelta dell'avversario.
- `test/engine/style_test.dart`: i bonus di stile.
- `test/engine/kid_bots_test.dart`, `test/game/kid_opponent_picker_test.dart` e `test/kid_bot_game_test.dart`: i bot amichevoli del profilo bambino.
- `test/engine/choose_test.dart` e `computer_player_test.dart`: il bonus nella scelta tra candidate.

## Stato

| Requisito | Stato |
|---|---|
| RF-23 bot con personalità | ✓ nome, avatar, Elo, stile, libro d'apertura e frasi su scacco, cattura e fine partita; manca la frase sull'errore, che richiede la valutazione della mossa dell'avversario |
| RG-18 galleria dei bot | ✓ fasce per Elo, saluto nel fumetto in italiano e inglese, lucchetti e corone, Adattivo, custodi della Storia con avanzamento, colore; personaggi disegnati per tutti i bot |
| RG-04 scala dei bot | ✓ sblocco battendo il precedente e collezione con la data della vittoria |
