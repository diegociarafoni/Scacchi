# Archivio delle partite e PGN

Requisiti RF-100 (salvataggio e ripresa), RF-101 (storico) e RF-102 (import ed export PGN). Il codice è in `lib/archive/`.

## Salvataggio

Le partite stanno in `games.json` nella cartella dati dell'app (`getApplicationSupportDirectory`), tramite `JsonFile` (`lib/storage/json_file.dart`):

- versione dello schema nel file (oggi 1);
- scrittura su file temporaneo e rinomina finale, così un'interruzione non lascia il file a metà;
- salvataggi accodati: vince sempre l'ultimo;
- un file non valido (JSON rotto, versione futura, voce incompleta) viene rinominato in `games.json.bad-<ms>` invece di essere sovrascritto; un errore di lettura del disco, invece, non tocca il file e la schermata mostra un messaggio;
- `GameArchive.open()` restituisce sempre la stessa istanza, così tutte le schermate condividono cache e coda dei salvataggi.

Ogni partita (`SavedGame`) conserva identificativo, data di creazione e di aggiornamento, nomi dei giocatori, tipo (`locale`, `computer`, `importata`, `fisica`, `analisi`), risultato PGN e il PGN completo; facoltativamente colore dell'utente, cadenza, Elo del bot, precisione e apertura, usati dalle statistiche (vedi [statistiche.md](statistiche.md)). Le mosse stanno solo nel PGN, che è anche il formato di export: una sola fonte di verità.

`GameArchive.save` inserisce o sostituisce la partita con lo stesso identificativo, quindi la schermata di gioco può salvare a ogni mossa (RF-100) con lo stesso id. `GameArchive.unfinished` restituisce la partita propria non conclusa più recente: la Home la propone come prossimo passo («Riprendi la partita»). Le partite importate sono escluse.

Quando arriverà il database locale (RNF-08), il file sarà importato alla prima migrazione.

## PGN

`lib/archive/pgn.dart`, basato sul parser e sul generatore PGN di `dartchess`.

**Export** (`exportPgn`): intestazioni standard (Event, Site, Date, Round, White, Black, Result), linea principale in SAN con `{ [%clk h:mm:ss] }` dopo le mosse di cui si conosce il tempo residuo (RF-67), `FEN` e `SetUp` se la partita parte da una posizione diversa da quella iniziale della variante (sempre per Chess960), `Variant` (`Chess960`, `King of the Hill`, `Three-check`) per le partite non classiche. Il risultato viene dalla partita: matto, abbandono e patte producono `1-0`, `0-1` o `1/2-1/2`; una partita in corso ha `*`. Simbolo e commento della mossa si scrivono come NAG e `{ commento }`, insieme al tempo residuo nello stesso commento; un `}` nel testo diventa `)` perché chiuderebbe il commento. In una partita con orologio `GamePage` registra a ogni mossa il tempo residuo di chi l'ha giocata, incremento compreso (la prima mossa avvia l'orologio e non lo incrementa), quindi i tempi finiscono nel PGN salvato e in quello passato con QR.

**Import** (`importPgn`): una o più partite nello stesso testo, aggiunte all'archivio nell'ordine del file e con tutte le intestazioni originali (evento, data, Elo...). Il tempo residuo di ogni mossa (`{ [%clk 0:04:58] }`, RF-67) si conserva in `PlayedMove.clock`; la partita ha la sola linea principale, mentre le varianti tra parentesi restano nell'albero del record (`PgnRecord.tree`, solo scacchi classici) e l'archivio le conserva nel PGN salvato (RF-52, vedi [analisi.md](analisi.md#salvare-e-condividere-rf-52)); annotando la linea principale dalla revisione le varianti non si perdono (`PgnRecord.annotate`, `toPgn`). Simbolo (`!!`, `!`, `!?`, `?!`, `?`, `??`, cioè i NAG da `$1` a `$6`) e commento di testo di ogni mossa si conservano in `PlayedMove.note` (`MoveNote`, RF-55); gli altri NAG si ignorano e più commenti sulla stessa mossa si uniscono. Se il risultato dichiarato non corrisponde a un matto o a una patta sulla scacchiera, la partita si chiude con l'abbandono del lato perdente o con la patta concordata. Le mosse si ricostruiscono con `ChessGame.replay`, che non si ferma a una triplice ripetizione o alle 50 mosse non reclamate. Le partite con mosse illegali, FEN malformato o non valido e varianti non supportate (supportate: classica, Chess960, Re della collina, Tre scacchi, riconosciute anche con nomi alternativi come `Fischerandom`) vengono scartate e contate, senza bloccare le altre.

## Schermata Partite

`ArchivePage` (`lib/archive/archive_page.dart`):

- elenco dalla partita più recente, con giocatori, data, tipo e risultato (o "In corso");
- ricerca per nome dei giocatori o tipo di partita;
- per ogni partita: apri nell'analisi (se la schermata la collega), condividi il PGN con il menu di condivisione del sistema, copia negli appunti, elimina con conferma;
- in alto: importa (incollando il testo, con pulsante "Incolla") ed esporta tutto l'archivio in un unico PGN;
- tocco su una partita: callback `onOpen`. Dalla scheda Tu la partita si apre nella revisione (vedi [revisione-partita.md](revisione-partita.md)): il PGN si rilegge con `importPgn`, l'analisi usa il motore e vale XP come le altre revisioni. Dove il motore non c'è (macOS, oppure Windows e Linux senza Stockfish installato) un avviso lo spiega.
- per ogni partita, **Passa con QR**, e in alto **Ricevi con QR** per importare una partita letta con la fotocamera da un altro telefono (vedi [scambio-qr.md](scambio-qr.md)).

## Integrazione

**Invito alla prima revisione (U10).** In testa alla scheda Tu, sotto «Continua da dove eri», compare una scheda «Rivedi la tua prima partita» finché esiste una partita giocata e conclusa e nessuna partita è mai stata rivista (nessuna ha una precisione salvata). «Rivedi» apre la prima partita conclusa nella revisione; «Non ora», oppure aprire la revisione, spegne l'invito per sempre (preferenza `reviewInviteDismissed`). Non compare nel profilo bambino. La logica sta in `lib/home/review_invite.dart`.

L'archivio si apre dalla scheda Tu; la Home mostra le ultime partite concluse e le apre nella stessa revisione. `GamePage` salva la partita da sola a ogni mossa e a fine partita (modalità `locale` o `computer`, con colore, cadenza ed Elo del livello), indipendentemente dai progressi: si archiviano anche le partite brevi e quelle da una posizione dell'editor, non quelle senza mosse. Lo stesso vale per una partita ricevuta con **Ricevi con QR** dal menu della partita, che si continua tra due persone. L'`id` resta lo stesso per tutta la partita: se si annulla l'abbandono e la partita finisce in altro modo, la voce si aggiorna invece di duplicarsi. Una partita conclusa si apre nella revisione. Una partita "In corso" propone **Riprendi la partita** (`GamePage(resume: ...)`: si rilegge il PGN, si ripristina la posizione e si continua con lo stesso `id` e la stessa data di inizio) oppure **Rivedi la partita**. Limiti: l'orologio non si ripristina, e contro il computer il livello si ricava dall'Elo salvato (non la personalità del bot); una partita abbandonata con **Nuova** resta "In corso" e si può eliminare dall'elenco. Filtri per data e risultato, apertura e copia del FEN (RF-101 e RF-102, P1) seguiranno.
