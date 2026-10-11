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

Il matto a favore vale 100%, il matto subito 0%; stallo, materiale insufficiente, triplice ripetizione e regola delle 50 mosse valgono 50%. Ripetizione e 50 mosse dipendono dalla cronologia, che il motore non vede, perciò la revisione le riconosce da sé. Così passare da +12 a +8 in una posizione vinta non è un errore, mentre passare da +1 a −1 lo è.

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
| Occasione mancata | ✗ | Perdita > 10 dopo un errore dell'avversario (perdita ≥ 10), restando almeno in parità (win% ≥ 50) |
| Errore | ? | Perdita ≤ 20 |
| Errore grave | ?? | Perdita > 20 |

### Sacrificio

Una mossa è un sacrificio se cede almeno due pedoni di materiale (P=1, C=A=3, T=5, D=9), in uno dei due modi:

- **Pezzo offerto**: il pezzo mosso (almeno un cavallo) resta in presa e l'avversario ci guadagnerebbe prendendolo, anche se il motore preferisce non farlo (il caso classico della donna offerta che non si può prendere per via del matto).
- **Materiale perso nella variante**: si giocano le prime risposte della variante principale del motore (fino a quattro semimosse); se la variante si ferma su una presa avversaria si conta la nostra ripresa immediata.

Un pedone offerto non basta, come su chess.com.

## Precisione e stima della forza

- Precisione della mossa (formula di Lichess): `103.17 × e^(−0.04354 × perdita) − 3.17`, limitata a 0–100.
- Precisione della partita: media tra media aritmetica e media armonica delle mosse del giocatore, così un errore grave isolato pesa più che nella media semplice.
- Stima della forza (assente se il giocatore non ha mosse): interpolazione lineare indicativa (50% ≈ 400, 70% ≈ 1200, 80% ≈ 1700, 90% ≈ 2300, 95% ≈ 2700). È mostrata come stima, non come rating.

## Analisi con il motore

`ComputerPlayer.analyse(fen, depth:, multiPv:)` usa la stessa istanza di Stockfish dell'avversario (su telefono il motore nativo è uno solo) e imposta la forza piena (`Skill Level 20`, `UCI_LimitStrength false`); le opzioni del livello vengono ripristinate alla mossa successiva del computer. La revisione chiede due varianti per posizione a profondità 14 (RNF-05) e salta le posizioni finali.

- **Interruzione**: `reviewGame` controlla `isCancelled` prima e dopo ogni posizione e restituisce `null`; chi interrompe chiama anche `ComputerPlayer.stopAnalysis`, che ferma subito l'analisi in corso e quella in coda senza toccare la mossa del computer. Così, tornando alla partita con la revisione ancora in corso, il computer gioca la sua mossa a piena profondità. La revisione si apre con orologio e computer fermi e solo negli scacchi classici.
- **Punteggi parziali**: le righe `lowerbound` e `upperbound` del motore vengono ignorate.
- **Tempo massimo**: se una ricerca supera il limite, `ComputerPlayer` chiude il motore e la richiesta successiva ne avvia uno nuovo, così una risposta tardiva non viene scambiata per quella di una nuova ricerca.
- **Valutazione mancante**: se il motore non restituisce un punteggio, la revisione fallisce con un errore invece di supporre una patta.

## Momenti chiave

`GameReview.keyMoments` elenca le mosse Brillanti, Ottime, Occasioni mancate, Errori ed Errori gravi, da evidenziare nel grafico della valutazione (`whiteWinCurve`, una probabilità per posizione dal punto di vista del Bianco).

## Schermata di revisione

Si apre dal menu della partita (⋮ → **Revisione della partita**), disponibile quando il motore è presente e c'è almeno una mossa. Il codice è in `lib/review/review_page.dart`.

| Elemento | Requisito | Comportamento |
|---|---|---|
| Avanzamento | RF-60 | "Analisi in corso: n di N" con barra; **Interrompi** ferma il motore e mostra "Revisione interrotta." |
| Riepilogo | RF-63 | Precisione ed Elo stimato per Bianco e Nero; "Mosse per categoria" apre il conteggio per categoria |
| Grafico | RF-64 | Probabilità di vittoria del Bianco per posizione, momenti chiave colorati per categoria; un tocco porta alla posizione |
| Barra di valutazione | RF-50 | Verticale accanto alla scacchiera, parte bianca proporzionale alla probabilità del Bianco, valore numerico (`+0.3`, `M3`, `#`) |
| Scacchiera | RF-54, RF-61 | Posizione dopo la mossa scelta, simbolo della categoria sulla casa d'arrivo, freccia verde della mossa migliore quando non è stata giocata |
| Mossa scelta | RF-61 | "3… Cf6 è un errore grave" e "Migliore: g6" |
| Riprova | RF-65 | Sugli errori (imprecisione, errore, occasione mancata, errore grave) si rigioca la posizione critica finché si trova la mossa del motore; **Soluzione** mostra la freccia |
| Lista mosse | RF-61 | Ogni mossa con il simbolo della categoria, bordo del colore della categoria |
| Navigazione | RM-01 | Barra in basso: inizio, precedente, successiva, fine |

**Cache** (RF-66): la revisione calcolata resta in memoria per la sessione (`ReviewCache`), quindi riaprirla è immediato. Il salvataggio nel database locale arriverà con l'archivio delle partite.

**Progressi**: `ReviewPage.onReviewed` viene chiamata solo per un'analisi nuova, per registrare `ReviewCompleted` nei progressi una volta per partita.

**Accessibilità**: la barra di valutazione ha un'etichetta descrittiva ("Bianco avanti di 1.5", "Matto in 2 per il Nero"), le mosse della lista sono pulsanti con mossa e categoria, la precisione è letta come percentuale.

## Coach testuale

`explainMove` (`lib/review/coach.dart`) produce una frase breve per ogni mossa, con regole a modello e senza modelli linguistici (RF-70, RF-71). Sulla schermata di revisione compare sotto la mossa scelta quando è un errore; viene calcolata una sola volta per mossa. Ogni frase ha un tema (`CoachTheme`) che servirà a raggruppare gli errori ricorrenti.

Le regole si applicano in quest'ordine, e vale la prima che riconosce qualcosa:

| Tema | Quando | Esempio |
|---|---|---|
| Matto concesso | Dopo la mossa l'avversario ha il matto | "Dopo Nf6 il Bianco dà matto in 1 con Qxf7#." |
| Matto mancato | La mossa migliore dava matto e quella giocata no | "Avevi il matto in 1 con Qxf7#." |
| Pezzo in presa | La risposta prevista cattura un pezzo (non un pedone) e, contando la ripresa, si resta sotto di almeno due pedoni rispetto a prima della mossa (gli scambi alla pari non contano) | "Hai lasciato l'alfiere in presa in e5: la donna nera lo cattura." |
| Forchetta concessa | Il pezzo che risponde, senza poter essere catturato, attacca insieme due pezzi: il re, pezzi che valgono più di lui o pezzi indifesi | "Dopo Nc2+ il cavallo nero attacca insieme il re e la torre: è una forchetta." |
| Ripresa mancata | La mossa migliore riprende sulla casa dove l'avversario ha appena catturato | "Potevi riprendere il pezzo: bxc6 cattura l'alfiere." |
| Cattura netta mancata | La mossa migliore cattura con un guadagno di almeno due pedoni | "Potevi vincere materiale: Qxd5 cattura la torre." |
| Doppio attacco mancato | La mossa migliore attacca due pezzi con le stesse condizioni della forchetta | "Potevi fare un doppio attacco con Nc7+: il cavallo attacca il re e la torre." |
| Scoperta mancata | Dopo la mossa migliore un pezzo rimasto fermo attacca una casa occupata che prima non attaccava (l'arrocco è escluso) | "Potevi fare un attacco di scoperta con Nc6+: l'alfiere attacca la donna." |
| Perdita di materiale | Rispetto a prima della mossa, dopo la variante prevista (quattro semimosse) si hanno almeno due pedoni in meno | "Questa mossa perde materiale: circa 3 pedoni nella variante prevista." |
| Generica | Nessuna delle precedenti | "Meglio e4: la tua posizione peggiora." |

Le mosse non sbagliate ricevono una frase di lode per categoria ("È la mossa migliore.").

Non ancora coperti: inchiodatura e re esposto (RF-70) e il commento in tempo reale durante la partita (RF-72).

## Puzzle dagli errori

Proposta "Allenamento dagli errori" del capitolo 7 dei requisiti: `puzzlesFromReview` (`lib/review/personal_puzzles.dart`) trasforma gli errori, gli errori gravi e le occasioni mancate del giocatore in puzzle personali (`MistakePuzzle`) nello stesso formato dei puzzle Lichess usati dal modulo puzzle.

- **Posizione**: quella prima della mossa precedente dell'avversario; la prima mossa del puzzle è quella dell'avversario, come nel database Lichess.
- **Soluzione**: la variante del motore, fino a tre mosse del giocatore, oppure l'intero matto se il giocatore aveva il matto in 5 o meno. Si ferma alla prima mossa illegale e finisce sempre con una mossa del giocatore.
- **Soluzione unica**: se la seconda scelta del motore vale meno di 10 punti di probabilità in meno della prima, l'errore non diventa un puzzle, perché ci sarebbero più risposte giuste.
- **Esclusi**: gli errori alla prima semimossa (partite da posizione personalizzata), perché manca la mossa dell'avversario richiesta dal formato.
- **Temi**: `mateInN` solo se la soluzione arriva davvero al matto, altrimenti dal tema del coach (`defensiveMove` per ciò che si è concesso, `hangingPiece`, `fork`, `discoveredAttack` per ciò che si è mancato) più la fase (`opening` fino alla decima mossa, `endgame` con al massimo quattro pezzi oltre a re e pedoni, altrimenti `middlegame`).
- **Punteggio**: indicativo, 900 + 200 per mossa del giocatore, oppure 800 + 300 × N per il matto in N.
- **Identificativo**: `mio-<partita>-<semimossa>`, con i caratteri diversi da lettere, cifre, `_` e `-` sostituiti da `_`; così lo stesso errore non viene aggiunto due volte e la riga CSV resta valida.
- **Spiegazione**: la frase del coach sull'errore originale, da mostrare dopo la soluzione.

`toCsv()` produce la riga `id,fen,mosse,punteggio,temi` con l'arrocco nella forma standard (`e1g1`), leggibile da `Puzzle.parseCsv`. Il salvataggio e la ripetizione dilazionata useranno il ripasso del modulo puzzle (sistema di Leitner) quando sarà su `main`.
