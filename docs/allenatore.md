# Partita con l'allenatore

Equivalente locale di "Gioca con l'allenatore" di chess.com (requisiti RF-73…RF-75): si gioca contro il computer e, dopo ogni mossa, l'allenatore la valuta con Stockfish sul telefono, senza server.

## In partita

Nelle partite contro il computer o un bot la barra dei comandi ha il pulsante **Allenatore** (acceso/spento, spento di default). Da acceso:

- dopo ogni mossa dell'utente, e prima della risposta del computer, l'allenatore la giudica; con orologio e computer fermi durante il giudizio;
- se è un errore o un errore grave compare un riquadro con la spiegazione e due scelte: **Riprova** (la mossa viene annullata, anche per l'orologio) o **Continua** (la partita prosegue);
- nelle altre mosse il commento viene solo annunciato ai lettori di schermo;
- il giudizio della mossa compare anche sulla scacchiera come nella revisione e su chess.com: il simbolo (`!!`, `!`, `★`, `?!`, `?`, `??`…) con il suo colore sulla casa d'arrivo. Resta finché non muove di nuovo l'utente, sparisce se la risposta del computer occupa quella casa, se si annulla la mossa, si sfoglia la cronologia o si spegne l'allenatore;
- il pulsante **Aiuto** dà un suggerimento a livelli: al primo tocco il pezzo da muovere, al secondo la mossa.

Se il motore non risponde l'allenatore tace e la partita prosegue. Nella partita tra due persone il pulsante non c'è.

## `CoachSession`

| Metodo | Ruolo |
|---|---|
| `judge(posizione, mossa)` | Giudica la mossa riusando `reviewGame` e `explainMove` della revisione: restituisce classificazione, spiegazione testuale e `shouldWarn` |
| `hint(posizione, livello)` | Suggerimento a livelli: `HintLevel.piece` dà solo la casa del pezzo da muovere, `HintLevel.move` anche la destinazione e la notazione |
| `hintsUsed` | Numero di suggerimenti richiesti |

## Quando avvisa

`shouldWarn` è vero per errore ed errore grave (soglia `warnFrom`, per default `MoveClass.mistake`; si può abbassare a imprecisione). Le occasioni mancate non fermano la partita: il commento resta disponibile. Le soglie di classificazione sono quelle della [revisione](revisione-partita.md).

Limite noto: la mossa è giudicata sulla sola posizione, senza cronologia, quindi ripetizione e regola delle 50 mosse non sono riconosciute e le mosse di libro non sono marcate.

## Costo

Le valutazioni sono memorizzate per posizione dentro la sessione (quelle fallite no): chiedere un suggerimento e poi giocare la mossa non analizza due volte la stessa posizione (RF-75). I suggerimenti si contano una volta per posizione.
