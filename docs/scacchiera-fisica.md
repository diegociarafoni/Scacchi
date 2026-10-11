# Scacchiera fisica

Per giocare su una scacchiera vera l'app fa da orologio e da registro della partita (proposta del capitolo 7 dei requisiti). Si apre da **Tu → Scacchiera fisica**.

## Uso

1. Si scrivono i nomi dei giocatori e si sceglie la cadenza (le stesse della partita normale) oppure **Senza tempo**.
2. L'orologio del Bianco parte con **Inizia la partita**.
3. Dopo ogni mossa fatta sulla scacchiera si scrive nel campo (SAN inglese o italiana, per esempio `e4`, `Cf3`, `O-O`, o UCI `g1f3`) e si conferma, oppure si tocca una delle mosse legali proposte: l'elenco si restringe man mano che si digita. L'orologio passa all'avversario con l'incremento.
4. La mossa illegale o ambigua viene rifiutata con un avviso e non cambia nulla.

Il pannello del Nero è ruotato di 180° per chi gli siede di fronte. **Pausa**, **Annulla** (restituisce anche i tempi), **Patta** e **Abbandona** (con scelta di chi abbandona) sono sempre a portata.

## Fine e archivio

La partita finisce con matto, stallo, materiale insufficiente, ripetizione, 50 mosse, abbandono, patta concordata o tempo scaduto. Appena finisce, e a ogni modifica successiva (per esempio un annullamento), viene salvata nell'archivio con modo `fisica`, quindi si può aprire, esportare in PGN e rivedere come le altre. Non entra nelle statistiche né nel rating, perché non ha un lato dell'utente.

## Codice

`lib/physical/physical_game.dart` (partita, suggerimenti, orologio, PGN) e `lib/physical/physical_game_page.dart` (schermata). Test in `test/physical/` e `integration_test/physical_test.dart`.
