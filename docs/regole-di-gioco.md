# Regole di gioco

## Mosse

Le mosse legali sono generate da `dartchess` e comprendono tutte le regole degli scacchi standard: arrocco corto e lungo, presa en passant, promozione a donna, torre, alfiere o cavallo, divieto di lasciare il proprio re sotto scacco.

Una mossa di pedone che raggiunge l'ultima traversa senza indicare il pezzo di promozione è rifiutata. Il controllo è in `isPlayableMove` (`lib/game/chess_game.dart`), usato da `ChessGame.play`, `ChessGame.replay`, dall'inserimento testuale delle mosse, dalla conferma della mossa e dall'esploratore delle aperture. La scacchiera (`chessground`) chiede sempre il pezzo prima di inviare la mossa.

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
| `timeout` | Il tempo di un giocatore è esaurito | Vince l'avversario; patta se l'avversario non ha materiale sufficiente per dare matto |

L'ordine di valutazione è quello della tabella: per esempio una mossa che dà matto e contemporaneamente completa le 50 mosse conta come matto.

### Triplice ripetizione

Due posizioni sono considerate uguali quando coincidono disposizione dei pezzi, lato al tratto, diritti di arrocco e casa di presa en passant. Quest'ultima conta solo se la presa en passant è effettivamente legale, come previsto dal regolamento FIDE. Nel conteggio rientra anche la posizione iniziale. Si confrontano solo le posizioni successive all'ultima cattura o mossa di pedone, perché quelle precedenti non possono ripetersi.

La patta viene dichiarata automaticamente alla terza occorrenza, senza richiesta del giocatore, come su chess.com. Il regolamento FIDE prevede invece che la patta per triplice ripetizione e per 50 mosse vada reclamata dal giocatore, e diventi automatica solo alla quinta ripetizione e a 75 mosse; si è scelto il comportamento di chess.com indicato nei requisiti.

### Regola delle 50 mosse

Si usa il contatore di semimosse della posizione (`halfmoves`), che si azzera a ogni cattura o mossa di pedone. La patta scatta automaticamente quando il contatore raggiunge 100 semimosse.

## Annullamento, patta e abbandono

- "Annulla" toglie l'ultima mossa, anche a partita conclusa, e riporta la partita in corso. Se la partita è finita per abbandono o patta concordata, revoca solo l'abbandono o la patta, senza togliere mosse; funziona anche prima della prima mossa.
- "Patta" chiede all'avversario del lato al tratto se accetta; se accetta, la partita finisce patta.
- Con l'orologio, "Annulla" ripristina anche i tempi di entrambi i giocatori a prima della mossa annullata, incremento compreso; dopo un tempo scaduto annulla l'ultima mossa e restituisce il tempo di quella mossa.
- "Abbandona" chiede conferma e assegna la vittoria al lato che non è al tratto.

## Varianti

"Nuova" chiede la variante (RF-120, RF-121). Le regole sono quelle di `dartchess`, le stesse di Lichess; `lib/game/variant.dart` sceglie la posizione iniziale e `ChessGame` conosce la variante della partita.

| Variante | Differenze |
|---|---|
| Classica | Nessuna |
| Chess960 | Prima traversa mescolata, uguale per i due colori: re tra le torri, alfieri su case di colore opposto. 960 posizioni numerate secondo Scharnagl (la 518 è quella classica), estratte a caso; il numero compare nel titolo. |
| Re della collina | Vince anche chi porta il re in d4, e4, d5 o e5, purché la casa non sia attaccata (il re non può andare sotto scacco). |
| Tre scacchi | Vince anche chi dà il terzo scacco; il titolo mostra gli scacchi dati da ciascun colore. |

**Arrocco in Chess960.** Il re va dove andrebbe negli scacchi classici (g1/c1, g8/c8) e la torre accanto a lui (f1/d1, f8/d8). Sulla scacchiera si arrocca portando il re sulla torre con cui si vuole arroccare, il modo che funziona in ogni posizione; se il re parte dalla colonna e e la torre è in un angolo vale anche la mossa classica di due case. Le case tra re, torre e le loro destinazioni devono essere libere, a parte il re e la torre stessi, e il re non può attraversare case attaccate.

**Fine della partita.** Matto, stallo, ripetizione e 50 mosse valgono come negli scacchi classici. La vittoria propria della variante ha il motivo "Re al centro" o "Terzo scacco". A Tre scacchi la ripetizione confronta anche gli scacchi rimasti. Il materiale insufficiente non vale a Re della collina, dove un re solo può ancora vincere.

## Verifica delle regole

La conformità alle regole è verificata dai test in `test/regole/`:

- `perft_test.dart`: conta le sequenze di mosse legali (perft) generate da `dartchess` e le confronta con i valori di riferimento di [chessprogramming.org](https://www.chessprogramming.org/Perft_Results) e con la suite di casi speciali di Martin Sedlak (en passant illegali, arrocchi che danno scacco, promozioni e sottopromozioni, autostallo).
- `partita_test.dart`: verifica su `ChessGame` scacco, pezzi inchiodati, scaccomatto, stallo, arrocco (diritti, case attaccate, pezzi in mezzo), en passant, promozione, regola delle 50 mosse, triplice ripetizione (tratto, diritti di arrocco, presa en passant legale o no) e materiale insufficiente.
