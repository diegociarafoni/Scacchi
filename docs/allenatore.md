# Partita con l'allenatore

Equivalente locale di "Gioca con l'allenatore" di chess.com (requisiti RF-73…RF-75): si gioca contro il computer e, dopo ogni mossa, l'allenatore la valuta con Stockfish sul telefono, senza server.

## Stato

Questa prima parte contiene la logica pura (`lib/coach/coach_session.dart`). Il collegamento alla schermata di gioco, con avviso, ripresa della mossa e suggerimento, arriva in una PR successiva.

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
