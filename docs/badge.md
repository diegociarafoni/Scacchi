# Badge

Requisito RG-17. Una raccolta di 64 badge legati a ciò che si impara e si gioca, distinta dai [traguardi](gamification.md#traguardi-rg-05): i traguardi sono contatori che sbloccano temi, pezzi e cornici; i badge sono un riconoscimento tematico e non danno né XP né ricompense (RG-12). Il codice è in `lib/badges/`.

## Famiglie

| Famiglia | Badge | Da dove vengono i dati |
|---|---|---|
| Imparare (16) | un badge per ogni capitolo della Storia (le sue lezioni), tre guardiani battuti, tutti i puzzle della Storia, tutte le posizioni dei finali, tutte le partite dei maestri, 25 revisioni, il primo ripasso del repertorio e 10 sessioni di ripasso | Salvataggi di Percorso (le lezioni sono quelle della Storia), finali, maestri e Storia; `reviewsCompleted`; contatore `repertoire` |
| Puzzle (9) | 500 puzzle, 10 temi diversi, cinque temi singoli, punteggio 1800, 10 punti nella modalità a serie | `puzzleThemes`, `puzzlesSolved`, record |
| Partite (13) | matto del barbiere, matto del pazzo, matto con tutti i pezzi, en passant, sottopromozione, stallo, maratona, 100 vittorie, podio, 5 tornei, la prima partita con un amico su un altro telefono, 10 partite e la prima vittoria | Contatori degli eventi (`tally`), `wins`; contatori `online` e `online:win` |
| Storia (13) | un badge per capitolo con il bot battuto, uno per la storia intera, «Si parte!», «Metà del viaggio» e tre capitoli completati | Salvataggi di Storia e Percorso (lezioni) |
| Costanza (13) | livelli 3, 8, 15 e 20, serie di 14, 60, 100 e 365 giorni, 30 e 100 giorni di gioco, ritorno dopo una pausa, 7 giornate perfette, 25 sessioni di minigioco | `xp` (livello), `bestStreak`, `perfectDays`, `tally` |

I badge di livello (3, 8, 15, 20) affiancano i traguardi «Livello 5» e «Livello 10», che restano. I badge a gradini (livelli, serie e giorni di gioco) sono badge distinti con una scritta Bronzo, Argento o Oro: il gradino è solo estetico e c'è sempre anche il testo, non solo il colore.

## Modello

- `BadgeDef` (`badge_def.dart`): identificativo stabile, famiglia, icona di Material, soglia e funzione che dà l'avanzamento. I badge «a evento» hanno soglia 1. L'identificativo si salva nei progressi e non va cambiato.
- `BadgeFacts`: i dati su cui si decide, cioè `ProgressState` e `BadgeSources`.
- `BadgeSources` (`badge_sources.dart`): avanzamenti che stanno nei salvataggi di Percorso, finali, maestri e Storia. La Storia è l'unico percorso di apprendimento: i badge delle lezioni e dei guardiani contano solo i capitoli e i guardiani della Storia, perciò le lezioni di strategia e della scuola di Capablanca non hanno badge. Si ricalcolano a ogni modifica di quei salvataggi, quindi chi ha già finito un capitolo prima dell'arrivo dei badge lo ottiene al primo avvio.
- `ProgressState.badges`: identificativo del badge e giorno di calendario in cui è stato ottenuto. `ProgressState.tally`: contatori degli eventi che nessun altro archivio tiene. `ProgressState.lastActiveDay`: ultimo giorno con un'attività, per i giorni di gioco e il ritorno. I file salvati prima dei badge si leggono senza perdere nulla; valori non numerici si ignorano.

### Contatori degli eventi

| Chiave | Quando cresce |
|---|---|
| `game:<evento>` | A fine partita contro il computer, per ogni evento in `GamePlayed.highlights`: `scholarsMate`, `foolsMate`, `enPassant`, `underpromotion`, `stalemate`, `marathon` |
| `mate:<pezzo>` | Vittoria per matto con quel pezzo (`queen`, `rook`, `bishop`, `knight`, `pawn`) |
| `tournaments`, `podium` | Torneo concluso; podio se tra i primi tre con almeno 4 giocatori |
| `minigames` | Sessione di minigioco con almeno un punto |
| `days` | Primo evento registrato in un nuovo giorno di calendario |
| `comeback` | Attività dopo almeno 14 giorni senza attività |

Gli eventi di partita li calcola `gameActivity` (`lib/progress/game_activity.dart`) rigiocando la partita; le partite tra due persone non ne hanno. Chi gioca da prima dei badge parte da zero sui contatori: le partite passate non si rileggono dall'archivio.

## Sblocco

`ProgressTracker.record` valuta tutti i badge dopo i traguardi, con le fonti correnti, e li scrive nello stato insieme al resto. `ProgressTracker.refreshBadges` fa lo stesso quando cambiano solo le fonti (per esempio dopo una lezione). Con la gamification spenta non si sblocca nulla. Un badge ottenuto non si perde, anche se poi un avanzamento cala.

`ProgressController.badgeUnlocks` è un flusso con i badge appena ottenuti; `HomeShell` lo ascolta e mostra un avviso «Nuovo badge: …» con il pulsante «Vedi», che apre la raccolta. L'avviso è l'unico: non si aggiunge al riepilogo degli XP delle schermate di gioco. Nel profilo bambino non c'è avviso né raccolta (niente numeri), ma i badge si registrano comunque.

## Interfaccia

La scheda Tu ha la voce **Badge** (accanto a Profilo e Statistiche, nel gruppo «I miei dati»). `BadgesPage` ha due schede, **Badge** e **Libri**, ciascuna con il contatore «X su Y raggiunti» e la barra di avanzamento.

- **Badge**: card a griglia (almeno 3 colonne, di più su schermi larghi) raggruppate per famiglia, righe alla stessa altezza anche con il testo ingrandito. Una card ottenuta ha la medaglia colorata e lo sfondo tinto con il colore della famiglia; una da ottenere è grigia con il lucchetto, mostra comunque il nome (è la caccia al tesoro) e l'avanzamento «3 / 10». Toccata apre la scheda con medaglia grande, famiglia, gradino, come si ottiene e data o avanzamento.
- **Libri**: vedi sotto.

Ogni riquadro ha un'etichetta per i lettori di schermo («Alla francese, ottenuto» o «…, da ottenere, 3 su 10») e un'area di tocco ben oltre 48 dp.

### Medaglie

`BadgeArt` (`badge_art.dart`) disegna la medaglia in codice, senza immagini: ogni famiglia ha la sua sagoma (scudo per Imparare, esagono per Puzzle, rombo smussato per Partite, cerchio per Storia, rosetta per Costanza) e il suo colore (`badgePalette`), con gradiente, riflesso e bordo bronzo, argento o oro per i badge a gradini. Il simbolo al centro è un'icona di Material in bianco. Da ottenere la medaglia è grigia, con la stessa sagoma e il lucchetto.

`RecentBadges` (`recent_badges.dart`) è una fascia riutilizzabile con gli ultimi badge ottenuti, vuota se non ce n'è nessuno; nessuna schermata la usa ancora.

## Libri delle aperture

Ogni apertura giocata in una partita diventa un libro della collezione. `openingVolumes` (`opening_volumes.dart`) elenca 37 libri: un identificativo stabile, il nome dell'apertura, le famiglie del dataset che lo sbloccano (per esempio «Queen's Gambit Declined» e «Accepted» per il Gambetto di donna) e le mosse della copertina, che mostrano la posizione tipica dell'apertura.

A fine partita contro il computer o tra due persone, `gameActivity` classifica la partita con il libro delle aperture già caricato (`loadedOpeningBook`; la home lo scalda all'avvio) e mette in `GamePlayed.openingBook` l'identificativo del libro; il tracker aumenta il contatore `book:<id>`. Le partite brevi che non contano per i progressi non sbloccano libri. Se il libro non è ancora caricato la partita non sblocca nulla, mai un errore. Chi gioca da prima dei libri parte da zero.

Nella scheda **Libri** un libro sbloccato ha la copertina colorata con la scacchiera in miniatura e il nome; uno da sbloccare è grigio con la posizione sbiadita e il lucchetto, così si intuisce l'apertura da cercare. Toccato mostra la posizione, il nome e quante volte l'hai giocata, oppure come sbloccarlo. I libri non sono badge: non hanno data, non danno XP né ricompense.

## Testi e icone

I testi sono in `lib/l10n/it/badges.arb` e `lib/l10n/en/badges.arb`, con chiavi `badge<Id>Name` e `badge<Id>Desc` e il prefisso `badges…` e `books…` per la schermata. Le soglie delle descrizioni sono segnaposto riempiti dalla definizione, così testo e regola non divergono. `badges_l10n.dart` collega gli identificativi ai testi; un test verifica che ogni badge abbia nome e descrizione in tutte le lingue. I nomi dei libri sono quelli delle aperture (`opening_names.dart`) nella lingua dei contenuti caricati: in inglese quelli originali, nelle lingue con `opening_names.json` quelli tradotti. Le icone al centro delle medaglie sono quelle di Material; sagome e colori sono disegnati in codice.

Golden su tre taglie di telefono, chiaro e scuro, in `test/golden/badges_golden_test.dart`.

## Aggiungere un badge

1. Aggiungere la riga in `badges` (`badge_def.dart`), con un identificativo nuovo e mai riusato.
2. Se serve un dato nuovo, un contatore in `ProgressTracker._count` o un campo di `BadgeSources`.
3. Aggiungere `badge<Id>Name` e `badge<Id>Desc` nei due `badges.arb` e il ramo corrispondente in `badges_l10n.dart`.
4. Aggiungere il test in `test/badges/badge_defs_test.dart` e aggiornare il numero atteso nel test del catalogo e i conteggi in questo documento.

## Partite in rete e ripasso

Due attività dei progressi alimentano i badge nuovi (A-24):

- `OnlineGameFinished(result)`: la partita a due telefoni (`MultiplayerGamePage`, anche dal foglio «Nuova partita») la registra una sola volta, nel momento in cui passa a «finita»; una partita già conclusa che si riapre non conta di nuovo. L'esito è dal punto di vista di chi gioca: vittoria, patta o sconfitta. Non incrementa `gamesPlayed`, `wins` né l'obiettivo giornaliero «partite», per non cambiare le statistiche già raccolte. Vale XP come una partita normale (15, 12, 10).
- `RepertoireReviewed()`: la sessione di ripasso (`RepertoireDrillPage`) la registra quando si esce, se si è risposto ad almeno una mossa. Vale 10 XP.

Tutti i badge di questa sezione contano dal momento dell'aggiornamento: le partite passate non sono state registrate e non si recuperano.
