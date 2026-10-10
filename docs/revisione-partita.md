# Revisione della partita

Equivalente locale di Game Review di chess.com (requisiti RF-60…RF-66): ogni mossa viene analizzata da Stockfish sul telefono e classificata, senza server e senza limiti.

## Componenti

| File | Ruolo |
|---|---|
| `lib/review/win_probability.dart` | Conversione della valutazione del motore in probabilità di vittoria |
| `lib/review/move_classification.dart` | Categorie di chess.com e regole di classificazione |
| `lib/review/sacrifice.dart` | Bilancio del materiale e riconoscimento dei sacrifici |
| `lib/review/accuracy.dart` | Precisione per mossa e per partita, stima indicativa dell'Elo |
| `lib/review/game_review.dart` | `reviewGame`: analisi di tutte le posizioni, avanzamento, interruzione |
| `lib/review/engine_evaluator.dart` | Collegamento a `ComputerPlayer.analyse` (lo stesso motore dell'avversario) |

Il nucleo è Dart puro: riceve un `PositionEvaluator` (FEN → varianti del motore), quindi si testa con un motore finto e, se installato, con Stockfish reale.

## Probabilità di vittoria

La classificazione usa la perdita di probabilità di vittoria e non i centipedoni grezzi (RF-61), con la curva logistica di Lichess:

```
win% = 50 + 50 × (2 / (1 + e^(−0.00368208 × cp)) − 1)      cp limitato a ±1000
```

Il matto a favore vale 100%, il matto subito 0%, stallo e materiale insufficiente 50%. Così passare da +12 a +8 in una posizione vinta non è un errore, mentre passare da +1 a −1 lo è.

## Classificazione

Per ogni mossa `perdita = win% con la mossa migliore − win% con la mossa giocata`, in punti percentuali dal punto di vista di chi muove. Le soglie riprendono gli "expected points" di chess.com.

| Categoria | Simbolo | Regola |
|---|---|---|
| Brillante | !! | Sacrificio (vedi sotto), mossa migliore o con perdita ≤ 2, dopo la mossa win% ≥ 50, prima < 97 |
| Ottima | ! | Mossa migliore; la seconda scelta del motore vale almeno 20 punti in meno e sotto il 60%; non è la semplice punizione di un errore grave dell'avversario |
| Libro | 📖 | Mossa di apertura nota con perdita ≤ 10 (il riconoscimento delle aperture è fornito dal modulo aperture) |
| Migliore | ★ | Prima scelta del motore |
| Eccellente | 👍 | Perdita ≤ 2 |
| Buona | ✓ | Perdita ≤ 5 |
| Imprecisione | ?! | Perdita ≤ 10 |
| Occasione mancata | ✗ | Perdita > 10 dopo un errore dell'avversario (perdita ≥ 10), senza finire sotto il 30% |
| Errore | ? | Perdita ≤ 20 |
| Errore grave | ?? | Perdita > 20 |

### Sacrificio

Si gioca la mossa e poi le prime risposte della variante principale del motore (fino a quattro semimosse, in numero pari per contare la ripresa). Se il bilancio del materiale (P=1, C=A=3, T=5, D=9) è sceso di almeno due pedoni, la mossa è un sacrificio. Un pedone offerto non basta, come su chess.com.

## Precisione e stima della forza

- Precisione della mossa (formula di Lichess): `103.17 × e^(−0.04354 × perdita) − 3.17`, limitata a 0–100.
- Precisione della partita: media tra media aritmetica e media armonica delle mosse del giocatore, così un errore grave isolato pesa più che nella media semplice.
- Stima della forza: interpolazione lineare indicativa (50% ≈ 400, 70% ≈ 1200, 80% ≈ 1700, 90% ≈ 2300, 95% ≈ 2700). È mostrata come stima, non come rating.

## Analisi con il motore

`ComputerPlayer.analyse(fen, depth:, multiPv:)` usa la stessa istanza di Stockfish dell'avversario (su telefono il motore nativo è uno solo) e imposta la forza piena (`Skill Level 20`, `UCI_LimitStrength false`); le opzioni del livello vengono ripristinate alla mossa successiva del computer. La revisione chiede due varianti per posizione a profondità 14 (RNF-05), salta le posizioni finali e si può interrompere tra una posizione e l'altra.

## Momenti chiave

`GameReview.keyMoments` elenca le mosse Brillanti, Ottime, Occasioni mancate, Errori ed Errori gravi, da evidenziare nel grafico della valutazione (`whiteWinCurve`, una probabilità per posizione dal punto di vista del Bianco).
