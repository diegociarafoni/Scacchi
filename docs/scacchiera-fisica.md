# Scacchiera fisica

Per giocare su una scacchiera vera l'app fa da orologio e da registro della partita (proposta del capitolo 7 dei requisiti). Si apre da **Tu → Scacchiera fisica**.

## Uso

1. Si scrivono i nomi dei giocatori e si sceglie la cadenza (le stesse della partita normale) oppure **Senza tempo**.
2. L'orologio del Bianco parte con **Inizia la partita**.
3. Dopo ogni mossa fatta sulla scacchiera si scrive nel campo (SAN inglese o italiana, per esempio `e4`, `Cf3`, `O-O`, o UCI `g1f3`) e si conferma, oppure si tocca una delle mosse legali proposte: l'elenco si restringe man mano che si digita. L'orologio passa all'avversario con l'incremento.
4. La mossa illegale o ambigua viene rifiutata con un avviso e non cambia nulla.

Il pannello del Nero è ruotato di 180° per chi gli siede di fronte. **Pausa**, **Annulla** (restituisce anche i tempi), **Patta** e **Abbandona** (con scelta di chi abbandona) sono sempre a portata.

## Mossa dalla foto (RP-08)

Invece di scrivere la mossa si può fotografare la scacchiera con **Mossa dalla foto**, tutto sul telefono e senza rete. L'app non riconosce i pezzi: confronta due foto della stessa scacchiera e vede quali caselle sono cambiate, poi sceglie tra le mosse legali quelle che cambiano proprio quelle caselle (arrocco e presa al varco comprese).

1. Prima foto: si trascinano i quattro cerchi sugli angoli della scacchiera e si indica quale colore sta in basso nella foto. È la foto di riferimento; l'inquadratura resta la stessa per tutta la partita.
2. Dopo ogni mossa si scatta un'altra foto: compaiono fino a quattro mosse, la più probabile con la spunta. Un tocco la gioca e la foto diventa il nuovo riferimento. Per una promozione si propongono donna, torre, alfiere, cavallo in quest'ordine.
3. Se la mossa è stata scritta o annullata, la vecchia foto non vale più: la foto successiva diventa il nuovo riferimento.

Limiti: la fotocamera va tenuta ferma e quasi dall'alto (un piccolo spostamento e un cambio di luce sono tollerati, la prospettiva forte no); due foto uguali non producono mosse. Le foto non vengono salvate né inviate. La scelta finale è sempre dell'utente.

Il riconoscimento dei pezzi da una foto singola, per analizzare una posizione qualunque, richiede un modello addestrato e resta fuori dall'app.

## Fine e archivio

La partita finisce con matto, stallo, materiale insufficiente, ripetizione, 50 mosse, abbandono, patta concordata o tempo scaduto. Quando finisce viene salvata nell'archivio con modo `fisica`; se dopo un annullamento finisce di nuovo, la nuova versione sostituisce la precedente, mentre un annullamento da solo non cambia l'archivio. La partita si può aprire, esportare in PGN e rivedere come le altre. Non entra nelle statistiche né nel rating, perché non ha un lato dell'utente.

## Codice

`lib/physical/physical_game.dart` (partita, suggerimenti, orologio, PGN), `lib/physical/physical_game_page.dart` (schermata), `lib/physical/board_photo.dart` (confronto tra foto e mosse probabili), `lib/physical/photo_source.dart` (fotocamera e decodifica) e `lib/physical/board_align_page.dart` (allineamento della scacchiera). Test in `test/physical/` e `integration_test/physical_test.dart`.
