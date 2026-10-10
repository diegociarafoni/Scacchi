# Archivio delle partite e PGN

Requisiti RF-100 (salvataggio e ripresa), RF-101 (storico) e RF-102 (import ed export PGN). Il codice è in `lib/archive/`.

## Salvataggio

Le partite stanno in `games.json` nella cartella dati dell'app (`getApplicationSupportDirectory`), tramite `JsonFile` (`lib/storage/json_file.dart`):

- versione dello schema nel file (oggi 1);
- scrittura su file temporaneo e rinomina finale, così un'interruzione non lascia il file a metà;
- salvataggi accodati: vince sempre l'ultimo;
- un file illeggibile o di una versione futura viene rinominato in `games.json.bad-<ms>` invece di essere sovrascritto.

Ogni partita (`SavedGame`) conserva identificativo, data di creazione e di aggiornamento, nomi dei giocatori, tipo (`locale`, `computer`, `importata`), risultato PGN e il PGN completo. Le mosse stanno solo nel PGN, che è anche il formato di export: una sola fonte di verità.

`GameArchive.save` inserisce o sostituisce la partita con lo stesso identificativo, quindi la schermata di gioco può salvare a ogni mossa (RF-100) con lo stesso id. `GameArchive.unfinished` restituisce la partita non conclusa più recente da riprendere all'avvio.

Quando arriverà il database locale (RNF-08), il file sarà importato alla prima migrazione.

## PGN

`lib/archive/pgn.dart`, basato sul parser e sul generatore PGN di `dartchess`.

**Export** (`exportPgn`): intestazioni standard (Event, Site, Date, Round, White, Black, Result), linea principale in SAN, `FEN` e `SetUp` se la partita parte da una posizione diversa da quella iniziale. Il risultato viene dalla partita: matto, abbandono e patte producono `1-0`, `0-1` o `1/2-1/2`; una partita in corso ha `*`.

**Import** (`importPgn`): una o più partite nello stesso testo. Commenti, annotazioni (`??`, `{[%clk ...]}`) e varianti si ignorano, si tiene la linea principale. Se il risultato dichiarato non corrisponde a un matto o a una patta sulla scacchiera, la partita si chiude con l'abbandono del lato perdente o con la patta concordata. Le partite con mosse illegali, posizione FEN non valida o varianti diverse dagli scacchi classici vengono scartate e contate. I PGN esportati da Lichess e chess.com si importano così come sono.

## Schermata Partite

`ArchivePage` (`lib/archive/archive_page.dart`):

- elenco dalla partita più recente, con giocatori, data, tipo e risultato (o "In corso");
- ricerca per nome dei giocatori o tipo di partita;
- per ogni partita: condividi il PGN con il menu di condivisione del sistema, copia negli appunti, elimina con conferma;
- in alto: importa (incollando il testo, con pulsante "Incolla") ed esporta tutto l'archivio in un unico PGN;
- tocco su una partita: callback `onOpen`, per aprirla nella schermata di gioco.

## Integrazione prevista

Salvataggio a ogni mossa, ripresa all'avvio e accesso alla schermata Partite dalla schermata di gioco arrivano in una modifica separata, per non sovrapporsi al lavoro in corso sulla partita contro il computer. Filtri per data e risultato, apertura e copia del FEN (RF-101 e RF-102, P1) seguiranno.
