# Regole di gioco

## Mosse

Le mosse legali sono generate da `dartchess` e comprendono tutte le regole degli scacchi standard: arrocco corto e lungo, presa en passant, promozione a donna, torre, alfiere o cavallo, divieto di lasciare il proprio re sotto scacco.

Ogni mossa giocata viene registrata in notazione algebrica standard (SAN), per esempio `e4`, `Nf3`, `O-O`, `exd5`, `e8=Q`, `Qxf7#`.

## Fine partita

| Motivo (`GameEndReason`) | Condizione | Risultato |
|---|---|---|
| `checkmate` | Il lato al tratto è sotto scacco e non ha mosse legali | Vince l'altro lato |
| `stalemate` | Il lato al tratto non è sotto scacco e non ha mosse legali | Patta |
| `insufficientMaterial` | Nessuno dei due lati ha materiale sufficiente per dare matto | Patta |
| `threefoldRepetition` | La stessa posizione si è presentata tre volte | Patta |
| `fiftyMoveRule` | 50 mosse per lato senza catture né mosse di pedone | Patta |
| `resignation` | Un giocatore abbandona | Vince l'altro lato |
| `agreement` | Un giocatore propone la patta e l'avversario accetta | Patta |

L'ordine di valutazione è quello della tabella: per esempio una mossa che dà matto e contemporaneamente completa le 50 mosse conta come matto.

### Triplice ripetizione

Due posizioni sono considerate uguali quando coincidono disposizione dei pezzi, lato al tratto, diritti di arrocco e casa di presa en passant. Quest'ultima conta solo se la presa en passant è effettivamente legale, come previsto dal regolamento FIDE. Nel conteggio rientra anche la posizione iniziale.

La patta viene dichiarata automaticamente alla terza occorrenza, senza richiesta del giocatore.

### Regola delle 50 mosse

Si usa il contatore di semimosse della posizione (`halfmoves`), che si azzera a ogni cattura o mossa di pedone. La patta scatta automaticamente quando il contatore raggiunge 100 semimosse.

## Annullamento, patta e abbandono

- "Annulla" toglie l'ultima mossa, anche a partita conclusa, e riporta la partita in corso.
- "Patta" chiede all'avversario del lato al tratto se accetta; se accetta, la partita finisce patta. Annullare una mossa riprende la partita.
- "Abbandona" chiede conferma e assegna la vittoria al lato che non è al tratto. Annullare dopo un abbandono riprende la partita.
