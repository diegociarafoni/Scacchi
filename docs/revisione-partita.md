# Revisione della partita

Revisione completa della partita (requisiti RF-60…RF-66): ogni mossa viene analizzata da Stockfish sul telefono e classificata, senza server e senza limiti.

## Componenti

| File | Ruolo |
|---|---|
| `lib/review/win_probability.dart` | Conversione della valutazione del motore in probabilità di vittoria |
| `lib/review/move_classification.dart` | Categorie delle mosse e regole di classificazione |
| `lib/review/sacrifice.dart` | Bilancio del materiale e riconoscimento dei sacrifici |
| `lib/review/accuracy.dart` | Precisione per mossa e per partita, stima indicativa dell'Elo |
| `lib/review/game_review.dart` | `reviewGame`: analisi di tutte le posizioni, avanzamento, interruzione |
| `lib/review/engine_evaluator.dart` | Collegamento a `ComputerPlayer.analyse` (lo stesso motore dell'avversario) |
| `lib/review/move_time.dart` | Tempo speso su ogni mossa (`timeSpent`) e errori giocati in fretta (`hastyPlies`) |
| `lib/review/game_phase.dart` | Fase della partita (apertura, mediogioco, finale) per la precisione per fase e i temi dei puzzle |
| `lib/review/coach.dart` | Coach testuale: `explainMove` e temi degli errori |
| `lib/review/personal_puzzles.dart` | Puzzle personali dagli errori (`puzzlesFromReview`) |
| `lib/review/error_themes.dart` | Conteggio degli errori per tema del coach (`errorThemeCounts`) |
| `lib/review/review_activity.dart` | Attività `ReviewCompleted` registrata a revisione finita (XP, errori ricorrenti) |
| `lib/review/review_l10n.dart` | Nomi tradotti di categorie e temi |
| `lib/review/board_utils.dart` | Utilità sulla scacchiera: mosse del motore, arrocco, `threatFen` per la minaccia |
| `lib/review/eval_bar.dart`, `score_format.dart` | Barra di valutazione e formato dei punteggi |
| `lib/review/review_page.dart` | Schermata di revisione, con le note personali sulle mosse |

Il nucleo è Dart puro: riceve un `PositionEvaluator` (FEN → varianti del motore), quindi si testa con un motore finto e, se installato, con Stockfish reale.

## Probabilità di vittoria

La classificazione usa la perdita di probabilità di vittoria e non i centipedoni grezzi (RF-61), con questa curva logistica:

```
win% = 50 + 50 × (2 / (1 + e^(−0.00368208 × cp)) − 1)      cp limitato a ±1000
```

Il matto a favore vale 100%, il matto subito 0%; stallo, materiale insufficiente, triplice ripetizione e regola delle 50 mosse valgono 50%. Ripetizione e 50 mosse dipendono dalla cronologia, che il motore non vede, perciò la revisione le riconosce da sé. Così passare da +12 a +8 in una posizione vinta non è un errore, mentre passare da +1 a −1 lo è.

## Classificazione

Per ogni mossa `perdita = win% con la mossa migliore − win% con la mossa giocata`, in punti percentuali dal punto di vista di chi muove. Le soglie sono espresse in punti attesi.

| Categoria | Simbolo | Regola |
|---|---|---|
| Brillante | !! | Sacrificio (vedi sotto), mossa migliore o con perdita ≤ 2, dopo la mossa win% ≥ 50, prima < 97 |
| Ottima | ! | Mossa migliore; la seconda scelta del motore vale almeno 20 punti in meno e sotto il 60%; non è la semplice punizione di un errore grave dell'avversario; dopo la mossa win% ≥ 30 |
| Libro | 📖 | Mossa di apertura nota con perdita ≤ 10. `ReviewPage` passa a `reviewGame` `isBook`: sono di libro le prime `OpeningBook.bookPlies` semimosse, cioè finché la posizione resta nel libro delle aperture (RF-91). Vale solo partendo dalla posizione iniziale e con il libro già caricato (l'app lo carica all'avvio e alla prima partita); altrimenti nessuna mossa è di libro. Lo stesso commento dell'allenatore (`reviewCoachBook`) e il conteggio per categoria usano questa classe |
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

Un pedone offerto non basta.

## Precisione e stima della forza

- Precisione della mossa: `103.17 × e^(−0.04354 × perdita) − 3.17`, limitata a 0–100.
- Precisione della partita: media tra media aritmetica e media armonica delle mosse del giocatore, così un errore grave isolato pesa più che nella media semplice.
- Stima della forza (assente se il giocatore non ha mosse): interpolazione lineare indicativa tra punti fissi (per esempio 50% ≈ 400, 70% ≈ 1200, 80% ≈ 1700, 90% ≈ 2300, 95% ≈ 2700, 100% ≈ 3200). È mostrata come stima, non come rating.

## Precisione per fase

Sotto il riepilogo, il riquadro **Precisione per fase** (RF-68) mostra la precisione di Bianco e Nero in apertura, mediogioco e finale, per capire cosa allenare. `GameReview.accuracyByPhase(side)` raggruppa le mosse del giocatore per la fase della posizione di partenza e applica la stessa media della precisione complessiva; una fase senza mosse mostra «—». La regola di fase (`phaseOf`, `lib/review/game_phase.dart`) è la stessa dei temi dei puzzle personali: apertura fino alla decima mossa, finale con al massimo quattro pezzi oltre a re e pedoni, altrimenti mediogioco. Nel profilo bambino il riquadro non compare.

## Tempo per mossa

Se la partita aveva l'orologio, sotto il riepilogo compare il riquadro **Tempo per mossa** (RF-67): un istogramma con il tempo speso su ogni mossa (un tocco porta alla mossa) e l'elenco degli errori giocati in fretta. `timeSpent` ricava il tempo dai residui registrati a ogni mossa: residuo precedente dello stesso lato, più l'incremento, meno il residuo attuale; la prima mossa di ogni lato parte dal tempo iniziale della cadenza e non prende incremento. Un errore (imprecisione, errore, occasione mancata, errore grave) è «in fretta» se è durato meno del 40% del tempo medio di quel lato (`hastyPlies`); servono almeno quattro mosse cronometrate e una media di 3 secondi, altrimenti non si giudica. Il riquadro non compare senza tempi registrati (partite senza orologio, PGN importati senza `[%clk]`) né nel profilo bambino. Dall'archivio la cadenza viene da quella salvata con la partita; se manca, la prima mossa di ogni lato non ha durata. Nelle partite a handicap di tempo (RF-27) il tempo iniziale di chi concede viene dall'intestazione PGN `Handicap` (`Handicap.startTimesFromPgn`) o dall'orologio della partita in corso (`ChessClock.startTimes`).

## Annotazioni personali

Su ogni mossa si può scrivere una nota (RF-55): un simbolo (`!`, `?`, `!!`, `??`, `!?`, `?!`) e un commento. Nella schermata di revisione, sotto la mossa scelta, **Aggiungi nota** (o **Modifica nota**) apre una finestra con i sei simboli e il campo di testo; salvare una nota vuota la toglie. La nota compare come «La tua nota: …» e nella lista la mossa porta un ✎. Il pulsante c'è solo quando la revisione sa dove salvare (`ReviewPage.onNoteChanged`): aprendo una partita dall'**Archivio** la nota entra nel PGN salvato (`SavedGame.copyWith(pgn:)`, con le intestazioni originali) e resta in export; dalla partita appena giocata le note non si modificano.

## Analisi con il motore

`ComputerPlayer.analyse(fen, depth:, multiPv:)` usa la stessa istanza di Stockfish dell'avversario (su telefono il motore nativo è uno solo) e imposta la forza piena (`Skill Level 20`, `UCI_LimitStrength false`); le opzioni del livello vengono ripristinate alla mossa successiva del computer. La revisione chiede due varianti per posizione a profondità 14 (RNF-05) e salta le posizioni finali.

- **Interruzione**: `reviewGame` controlla `isCancelled` prima e dopo ogni posizione e restituisce `null`; chi interrompe chiama anche `ComputerPlayer.stopAnalysis`, che ferma subito l'analisi in corso e quella in coda senza toccare la mossa del computer. Così, tornando alla partita con la revisione ancora in corso, il computer gioca la sua mossa a piena profondità. La revisione si apre con orologio e computer fermi e solo negli scacchi classici.
- **Punteggi parziali**: le righe `lowerbound` e `upperbound` del motore vengono ignorate.
- **Tempo massimo**: se una ricerca supera il limite, `ComputerPlayer` chiude il motore e la richiesta successiva ne avvia uno nuovo, così una risposta tardiva non viene scambiata per quella di una nuova ricerca.
- **Valutazione mancante**: se il motore non restituisce un punteggio, la revisione fallisce con un errore invece di supporre una patta.

## Momenti chiave

`GameReview.keyMoments` elenca le mosse Brillanti, Ottime, Occasioni mancate, Errori ed Errori gravi, da evidenziare nel grafico della valutazione (`whiteWinCurve`, una probabilità per posizione dal punto di vista del Bianco).

## Schermata di revisione

Si apre dal menu della partita (⋮ → **Revisione della partita**: c'è il motore, c'è almeno una mossa e il computer non sta pensando; la voce manca nelle partite di tornei e percorso e nel profilo bambino) oppure toccando una partita nell'**Archivio** della scheda Tu o tra le «Ultime partite» della Home. Il codice è in `lib/review/review_page.dart`.

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
| Navigazione | RM-01 | Barra in basso: inizio, precedente, riproduzione, successiva, fine |
| Riproduzione | A-35 | **Play** fa avanzare la partita di una mossa ogni 0,9 secondi (`playbackStep`) e si ferma alla prossima mossa con un commento; se non ce ne sono più va alla fine. Il pulsante diventa **Pausa**; scegliere una mossa a mano, riprovare o la pausa interrompono. Con le animazioni ridotte (impostazione dell'app o del telefono) salta direttamente alla mossa, senza passi intermedi |

**Mosse con un commento** (`nextCommentedIndex` in `lib/review/autoplay.dart`): imprecisioni, errori, occasioni mancate ed errori gravi, mosse brillanti e ottime, note personali e l'ingresso nel libro (delle mosse Libro consecutive conta solo la prima).

**Cache** (RF-66): le ultime 20 revisioni restano in memoria per la sessione (`ReviewCache`) e le ultime 50 anche su disco (`ReviewStore`, `reviews.json` nella cartella dati, scritto con `JsonFile`), quindi riaprirle è immediato anche dopo il riavvio. La chiave (`ReviewStore.key`) contiene la versione dello schema di classificazione, il motore (`reviewEngine`, oggi `stockfish-19`), la profondità (`reviewDepth`), l'uso del libro delle aperture, la posizione iniziale e le mosse: cambiando una di queste cose la revisione si rifà. Un file illeggibile viene messo da parte (`.bad-<ms>`) e si riparte vuoti; un errore di lettura o scrittura non impedisce la revisione. Quando cambiano le regole di classificazione si aumenta `ReviewStore.schema`. Il file di backup non include le revisioni: si rigenerano.

**Risultato**: `ReviewPage.onResult` è chiamata ogni volta che la revisione è pronta (nuova o già calcolata) e serve a salvare precisione e precisione per fase sulla partita dell'archivio (vedi [statistiche.md](statistiche.md)). Anche la revisione aperta a fine partita dalla pagina di gioco la salva (contro il computer).

**Progressi**: `ReviewPage.onReviewed` viene chiamata solo per un'analisi nuova, quindi una revisione vale XP una volta per sessione della schermata di partita (riaprirla dalla cache non ne dà altri; una nuova sessione sulla stessa partita è già coperta dall'anti-abuso delle attività). `GamePage` registra `ReviewCompleted` tramite `ActivityRecorder`, con la precisione di chi ha giocato contro il computer e il numero di mosse brillanti, e mostra il riepilogo con `showProgressFeedback`. Nella partita tra due persone la precisione non è di nessuno in particolare e non viene registrata. Dall'archivio la revisione vale XP allo stesso modo, con la precisione del lato del giocatore salvato, senza il riepilogo a schermo.

**Accessibilità**: la barra di valutazione ha un'etichetta descrittiva ("Bianco avanti di 1.5", "Matto in 2 per il Nero"), le mosse della lista sono pulsanti con mossa e categoria, la precisione è letta come percentuale.

Nel profilo bambino (RP-06) la precisione diventa da una a cinque stelle con un giudizio a parole, spariscono Elo stimato, conteggi per categoria e cifre della barra di valutazione, e il coach (`explainMove(..., kid:)`) spiega matti e perdite di materiale senza «matto in N» né «circa N pedoni»: vedi [profilo-bambino.md](profilo-bambino.md#niente-numeri).

## Coach testuale

`explainMove` (`lib/review/coach.dart`) produce una frase breve per ogni mossa, con regole a modello e senza modelli linguistici (RF-70, RF-71). Sulla schermata di revisione compare sotto la mossa scelta quando è un errore; viene calcolata una sola volta per mossa. Ogni frase ha un tema (`CoachTheme`) che servirà a raggruppare gli errori ricorrenti. Il commento tiene il tema e compone il testo (`CoachComment.text(l)`) con la lingua dell'app: le frasi sono messaggi interi in `lib/l10n/<lingua>/review.arb`, con pezzi e colori scelti da `select` ICU perché articoli e generi cambiano da lingua a lingua.

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
| Inchiodatura concessa | Il pezzo che risponde (alfiere, torre o donna) inchioda al re un tuo pezzo non pedone, non si può catturare e non inchiodava già lo stesso pezzo (si controlla dopo la perdita di materiale: è un danno più lieve) | "Dopo Bb4 l'alfiere nero inchioda il cavallo in d2 contro il re." |
| Re scoperto | Mossa del re (un passo, senza arrocco) o di un pedone entro la terza traversa davanti al re ancora sulla traversa di partenza, a cui l'avversario risponde con uno scacco che prima della mossa non era possibile (dopo l'inchiodatura) | "Dopo f3 il tuo re resta scoperto: Qd4+ è scacco." |
| Generica | Nessuna delle precedenti | "Meglio e4: la tua posizione peggiora." |

Le mosse non sbagliate ricevono una frase di lode per categoria ("È la mossa migliore.").

Il commento in tempo reale durante la partita (RF-72) è dell'allenatore: vedi [allenatore.md](allenatore.md).

## Puzzle dagli errori

"Allenamento dagli errori": `puzzlesFromReview` (`lib/review/personal_puzzles.dart`) trasforma gli errori, gli errori gravi e le occasioni mancate del giocatore in puzzle personali (`MistakePuzzle`) nello stesso formato dei puzzle inclusi nell'app.

- **Posizione**: quella prima della mossa precedente dell'avversario; la prima mossa del puzzle è quella dell'avversario, come nella raccolta di puzzle inclusa.
- **Soluzione**: la variante del motore, fino a tre mosse del giocatore, oppure l'intero matto se il giocatore aveva il matto in 5 o meno. Si ferma alla prima mossa illegale e finisce sempre con una mossa del giocatore.
- **Soluzione unica**: se la seconda scelta del motore vale meno di 10 punti di probabilità in meno della prima, l'errore non diventa un puzzle, perché ci sarebbero più risposte giuste.
- **Esclusi**: gli errori alla prima semimossa (partite da posizione personalizzata), perché manca la mossa dell'avversario richiesta dal formato.
- **Temi**: `mateInN` solo se la soluzione arriva davvero al matto, altrimenti dal tema del coach (`defensiveMove` per ciò che si è concesso, `hangingPiece`, `fork`, `discoveredAttack` per ciò che si è mancato) più la fase (`opening` fino alla decima mossa, `endgame` con al massimo quattro pezzi oltre a re e pedoni, altrimenti `middlegame`).
- **Punteggio**: indicativo, 900 + 200 per mossa del giocatore, oppure 800 + 300 × N per il matto in N.
- **Identificativo**: `mio-<partita>-<semimossa>`, con i caratteri diversi da lettere, cifre, `_` e `-` sostituiti da `_`; così lo stesso errore non viene aggiunto due volte e la riga CSV resta valida.
- **Spiegazione**: la frase del coach sull'errore originale (non salvata con il puzzle, vedi sotto).

`toCsv()` produce la riga `id,fen,mosse,punteggio,temi` con l'arrocco nella forma standard (`e1g1`), leggibile da `Puzzle.parseCsv`. 

### Salvataggio e ripasso

Nel riepilogo della revisione il pulsante **Salva gli errori come puzzle (N)** compare se c'è almeno un puzzle da salvare. Contro il computer contano solo gli errori di chi ha giocato, non quelli del motore; tra due persone contano entrambi i lati.

- `PuzzleTrainer.addPersonal` salva i puzzle in `PersonalPuzzles` (`lib/puzzles/personal_puzzles.dart`, chiave `puzzles.personal.v1`, al massimo 200: i più vecchi vengono scartati) e li aggiunge alla coda di ripasso come carte nuove. Salvare di nuovo la stessa partita non duplica nulla e lo dice ("Questi puzzle sono già salvati.").
- Si trovano in **Puzzle › Ripasso degli errori**, con gli intervalli del sistema di Leitner degli altri puzzle. Il punteggio dei puzzle non cambia: vale solo per quelli del database, quindi un puzzle personale (id `mio-…`) sbagliato o risolto agisce solo sul ripasso.
- Se il salvataggio fallisce compare "Salvataggio non riuscito. Riprova." e il pulsante resta disponibile.
- La spiegazione del coach non viene conservata: il puzzle è salvato come riga CSV del dataset dei puzzle. Mostrarla dopo la soluzione richiederebbe un campo dedicato.
- Se la scrittura su disco fallisce nulla viene aggiunto in memoria, così il salvataggio si può riprovare. Oltre 200 puzzle si scartano i più vecchi, anche dal ripasso.
- L'identificativo della partita nell'id (`mio-<partita>-<semimossa>`) è un FNV-1a della chiave della revisione, uguale su tutte le piattaforme.
