# Scacchiera fisica

Per giocare su una scacchiera vera l'app fa da orologio e da registro della partita. Si apre da **Scacchiera fisica** nel gruppo Gioca della Home e nel foglio Nuova partita (sotto «Altre modalità»); non c'è nel profilo bambino.

## Uso

1. Si scrivono i nomi dei giocatori e si sceglie la cadenza (le stesse della partita normale) oppure **Senza tempo**.
2. L'orologio del Bianco parte con **Inizia la partita**.
3. Dopo ogni mossa fatta sulla scacchiera si scrive nel campo (SAN inglese o italiana, per esempio `e4`, `Cf3`, `O-O`, o UCI `g1f3`) e si conferma, oppure si tocca una delle mosse legali proposte: l'elenco si restringe man mano che si digita. L'orologio passa all'avversario con l'incremento.
4. La mossa illegale o ambigua viene rifiutata con un avviso e non cambia nulla.

Il pannello del Nero è ruotato di 180° per chi gli siede di fronte. **Pausa**, **Annulla** (restituisce anche i tempi), **Patta** e **Abbandona** (con scelta di chi abbandona) sono sempre a portata.

## Mossa dalla foto (RP-08)

**Stato:** la funzione è completa ma nelle versioni di rilascio è spenta (flag di compilazione `ROKKO_PHOTO_MOVE`, di norma falso): il pulsante non compare. Per provarla: `flutter run --dart-define=ROKKO_PHOTO_MOVE=true`. Il codice e i test restano, quindi riaccenderla è questione di un parametro; in quel caso il testo del permesso della fotocamera in `ios/Runner/Info.plist` deve tornare a citare anche la foto della scacchiera.

Invece di scrivere la mossa si può fotografare la scacchiera con **Mossa dalla foto**, tutto sul telefono e senza rete. L'app non riconosce i pezzi: confronta due foto della stessa scacchiera e vede quali caselle sono cambiate, poi sceglie tra le mosse legali quelle che cambiano proprio quelle caselle (arrocco e presa al varco comprese).

1. Prima foto: si trascinano i quattro cerchi sugli angoli della scacchiera e si indica quale colore sta in basso nella foto. È la foto di riferimento; l'inquadratura resta la stessa per tutta la partita.
2. Dopo ogni mossa si scatta un'altra foto: compaiono fino a quattro mosse, la più probabile con la spunta. Un tocco la gioca e la foto diventa il nuovo riferimento. Una promozione compare una sola volta, con la donna; le altre si scrivono (`e8=T`). **Riallinea** chiede di nuovo gli angoli se il telefono o la scacchiera si sono spostati; una nuova partita riparte da zero.
3. Se la mossa è stata scritta o annullata, la vecchia foto non vale più: la foto successiva diventa il nuovo riferimento.

Limiti: la fotocamera va tenuta ferma e quasi dall'alto (un piccolo spostamento e un cambio di luce sono tollerati, la prospettiva forte no); due foto uguali non producono mosse. Se la fotocamera non è disponibile compare un avviso. Le foto non vengono salvate né inviate. La scelta finale è sempre dell'utente.

Il riconoscimento dei pezzi da una foto singola, per analizzare una posizione qualunque, richiede un modello addestrato e resta fuori dall'app.

## Fine e archivio

La partita finisce con matto, stallo, materiale insufficiente, ripetizione, 50 mosse, abbandono, patta concordata o tempo scaduto. La partita viene salvata nell'archivio con modo `fisica` a ogni mossa (risultato `*` finché è aperta) e di nuovo dopo ogni annullamento, così uscendo a metà non si perde nulla e un risultato revocato non resta in archivio; annullate tutte le mosse, il record sparisce. La partita si può aprire, esportare in PGN e rivedere come le altre. Non entra nelle statistiche né nel rating, perché non ha un lato dell'utente.

## Lingue

I testi sono in italiano e inglese in `lib/l10n/<lingua>/physical.arb` (prefisso `physical`); i nomi predefiniti dei giocatori seguono la lingua dell'app. L'intestazione `Site` del PGN resta «Scacchiera fisica» in ogni lingua, perché è un dato dell'archivio.

## Codice

`lib/physical/physical_game.dart` (partita, suggerimenti, orologio, PGN), `lib/physical/physical_game_page.dart` (schermata), `lib/physical/board_photo.dart` (confronto tra foto e mosse probabili), `lib/physical/photo_source.dart` (fotocamera e decodifica) e `lib/physical/board_align_page.dart` (allineamento della scacchiera). Test in `test/physical/` e `integration_test/physical_test.dart`.
