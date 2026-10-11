# Archivio delle partite e PGN

Requisiti RF-100 (salvataggio e ripresa), RF-101 (storico) e RF-102 (import ed export PGN). Il codice è in `lib/archive/`.

## Salvataggio

Le partite stanno in `games.json` nella cartella dati dell'app (`getApplicationSupportDirectory`), tramite `JsonFile` (`lib/storage/json_file.dart`):

- versione dello schema nel file (oggi 1);
- scrittura su file temporaneo e rinomina finale, così un'interruzione non lascia il file a metà;
- salvataggi accodati: vince sempre l'ultimo;
- un file non valido (JSON rotto, versione futura, voce incompleta) viene rinominato in `games.json.bad-<ms>` invece di essere sovrascritto; un errore di lettura del disco, invece, non tocca il file e la schermata mostra un messaggio;
- `GameArchive.open()` restituisce sempre la stessa istanza, così tutte le schermate condividono cache e coda dei salvataggi.

Ogni partita (`SavedGame`) conserva identificativo, data di creazione e di aggiornamento, nomi dei giocatori, tipo (`locale`, `computer`, `importata`), risultato PGN e il PGN completo; facoltativamente colore dell'utente, cadenza, Elo del bot, precisione e apertura, usati dalle statistiche (vedi [statistiche.md](statistiche.md)). Le mosse stanno solo nel PGN, che è anche il formato di export: una sola fonte di verità.

`GameArchive.save` inserisce o sostituisce la partita con lo stesso identificativo, quindi la schermata di gioco può salvare a ogni mossa (RF-100) con lo stesso id. `GameArchive.unfinished` restituisce la partita propria non conclusa più recente da riprendere all'avvio; le partite importate sono escluse.

Quando arriverà il database locale (RNF-08), il file sarà importato alla prima migrazione.

## PGN

`lib/archive/pgn.dart`, basato sul parser e sul generatore PGN di `dartchess`.

**Export** (`exportPgn`): intestazioni standard (Event, Site, Date, Round, White, Black, Result), linea principale in SAN, `FEN` e `SetUp` se la partita parte da una posizione diversa da quella iniziale della variante (sempre per Chess960), `Variant` (`Chess960`, `King of the Hill`, `Three-check`) per le partite non classiche. Il risultato viene dalla partita: matto, abbandono e patte producono `1-0`, `0-1` o `1/2-1/2`; una partita in corso ha `*`.

**Import** (`importPgn`): una o più partite nello stesso testo, aggiunte all'archivio nell'ordine del file e con tutte le intestazioni originali (evento, data, Elo...). Commenti, annotazioni (`??`, `{[%clk ...]}`) e varianti si ignorano, si tiene la linea principale. Se il risultato dichiarato non corrisponde a un matto o a una patta sulla scacchiera, la partita si chiude con l'abbandono del lato perdente o con la patta concordata. Le mosse si ricostruiscono con `ChessGame.replay`, che non si ferma a una triplice ripetizione o alle 50 mosse non reclamate. Le partite con mosse illegali, FEN malformato o non valido e varianti non supportate (supportate: classica, Chess960, Re della collina, Tre scacchi, riconosciute anche con i nomi alternativi di altri programmi come `Fischerandom`) vengono scartate e contate, senza bloccare le altre. I PGN esportati da Lichess e chess.com si importano così come sono.

## Schermata Partite

`ArchivePage` (`lib/archive/archive_page.dart`):

- elenco dalla partita più recente, con giocatori, data, tipo e risultato (o "In corso");
- ricerca per nome dei giocatori o tipo di partita;
- per ogni partita: condividi il PGN con il menu di condivisione del sistema, copia negli appunti, elimina con conferma;
- in alto: importa (incollando il testo, con pulsante "Incolla") ed esporta tutto l'archivio in un unico PGN;
- tocco su una partita: callback `onOpen`. Dalla scheda Tu la partita si apre nella revisione (vedi [revisione-partita.md](revisione-partita.md)): il PGN si rilegge con `importPgn`, l'analisi usa il motore e vale XP come le altre revisioni. Dove il motore non c'è (desktop) un avviso lo spiega.

## Integrazione prevista

L'archivio si apre dalla scheda Tu. A fine partita `GamePage` salva la partita da sola (modalità `locale` o `computer`, con colore, cadenza ed Elo del livello), indipendentemente dai progressi: si archiviano anche le partite brevi e quelle da una posizione dell'editor, non quelle senza mosse. L'`id` resta lo stesso per tutta la partita: se si annulla l'abbandono e la partita finisce in altro modo, la voce si aggiorna invece di duplicarsi. Salvataggio a ogni mossa, ripresa della partita non finita e apertura di una partita salvata sulla scacchiera arrivano in una modifica separata. Filtri per data e risultato, apertura e copia del FEN (RF-101 e RF-102, P1) seguiranno.
