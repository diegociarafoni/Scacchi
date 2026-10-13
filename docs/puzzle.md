# Puzzle

Problemi tattici offline (requisiti RF-80 – RF-85).

## Dati

La raccolta è un sottoinsieme del [database dei puzzle di Lichess](https://database.lichess.org/#puzzles), rilasciato in pubblico dominio (CC0). Il file `assets/puzzles/puzzles.csv` è incluso nell'app e contiene 4.691 problemi (circa 650 KB, compressi ulteriormente nel pacchetto).

Formato, una riga per puzzle:

```
id,fen,moves,rating,themes
```

- `fen`: posizione **prima** della mossa dell'avversario.
- `moves`: mosse in notazione UCI; la prima la gioca l'avversario, poi si alternano giocatore e avversario.
- `rating`: difficoltà Glicko-2 calcolata da Lichess.
- `themes`: temi Lichess separati da spazi (`fork`, `mateIn2`, `endgame`...).

### Come viene generata

Lo script `tool/datasets/build_puzzles.py` sceglie i puzzle in modo deterministico (stesso input, stesso output):

1. scarta i puzzle con punteggio poco affidabile (deviazione oltre 85), poco apprezzati (popolarità sotto 85) o poco giocati (meno di 800 tentativi);
2. divide i restanti in fasce di 100 punti, da 400 a 3000;
3. in ogni fascia prende fino a 6 puzzle per ciascun tema offerto come filtro, poi completa fino a 200 puzzle;
4. integra i temi rari (arrocco, sottopromozione, en passant, interferenza) fino ad almeno 30 puzzle ciascuno, con un filtro più permissivo.

L'ordine all'interno di una fascia è dato dall'hash SHA-1 dell'id, quindi è casuale ma riproducibile.

Il workflow `.github/workflows/datasets.yml` scarica il database, esegue lo script, valida il risultato con `test/puzzles/puzzle_dataset_test.dart` (il commit del workflow non avvia la CI) e fa il commit del risultato sul branch della pull request quando gli script in `tool/datasets/` cambiano; si può avviare anche a mano. In locale:

```sh
curl -sS https://database.lichess.org/lichess_db_puzzle.csv.zst \
  | zstd -dc | python3 tool/datasets/build_puzzles.py > assets/puzzles/puzzles.csv
```

Il test `test/puzzles/puzzle_dataset_test.dart` verifica che ogni soluzione sia legale, che le fasce di difficoltà siano coperte e che ogni tema offerto abbia abbastanza puzzle.

## Componenti

| File | Ruolo |
|---|---|
| `lib/puzzles/puzzle.dart` | Modello e lettura del CSV |
| `lib/puzzles/puzzle_session.dart` | Avanzamento dentro un puzzle: verifica delle mosse, risposta dell'avversario, suggerimento, soluzione |
| `lib/puzzles/glicko2.dart` | Punteggio Glicko-2 |
| `lib/puzzles/puzzle_library.dart` | Raccolta ordinata per difficoltà, scelta del puzzle successivo, filtro per tema, puzzle del giorno |
| `lib/puzzles/puzzle_trainer.dart` | Punteggio del giocatore, puzzle già visti, salvataggio, evento di puzzle concluso |
| `lib/puzzles/puzzle_page.dart` | Schermata di risoluzione |
| `lib/puzzles/puzzle_hub_page.dart` | Punteggio e modalità |
| `lib/puzzles/puzzle_assets.dart` | Caricamento della raccolta inclusa nell'app (`assets/puzzles/puzzles.csv`) |
| `lib/puzzles/puzzle_feed.dart` | Sequenze di puzzle per le schermate di risoluzione |
| `lib/puzzles/puzzle_run.dart`, `lib/puzzles/puzzle_run_page.dart` | Modalità a serie: modello e schermata |
| `lib/puzzles/run_records.dart` | Record personali delle serie |
| `lib/puzzles/review_queue.dart` | Coda di ripasso a intervalli (Leitner) |
| `lib/puzzles/personal_puzzles.dart` | Puzzle ricavati dagli errori delle proprie partite |
| `lib/puzzles/puzzle_goal.dart` | Obiettivo del puzzle ricavato dai temi (`PuzzleGoal`) |
| `lib/puzzles/themes.dart` | Elenco dei temi offerti come filtro e loro nome nella lingua dell'app |
| `lib/puzzles/activity_recorder.dart` | Collegamento con i progressi (`PuzzleSolved`, `PuzzleRunFinished`) |
| `lib/puzzles/mode_guide.dart` | Obiettivo e regole di ogni modalità, nella lingua dell'app |
| `lib/puzzles/guide_view.dart` | Schermata e pannello con la spiegazione |
| `lib/training/training_board.dart` | Scacchiera per esercizi, riusabile da puzzle e aperture; segue le impostazioni della scacchiera tramite `SettingsScope` |

## Regole di risoluzione

- Il puzzle parte con la mossa dell'avversario già giocata; la scacchiera è orientata dal lato del giocatore.
- Una mossa diversa dalla soluzione viene annullata con il messaggio "Non è la mossa giusta. Premi «Riprova» per ricominciare." e il puzzle conta come fallito, ma si può continuare a cercare.
- La mossa sbagliata resta segnata sulla scacchiera con una freccia e un cerchio rossi (arancioni con i colori per daltonici, `AppSettings.wrongColor`) finché non si riprova, si fa un'altra mossa o si chiede la soluzione. Il rosso non è l'unico segnale: compare l'icona ✕ accanto al messaggio, il messaggio è una regione "live" che i lettori di schermo annunciano, e con la vibrazione attiva si sente un colpo deciso.
- All'ultima mossa è accettato anche un matto diverso da quello previsto.
- L'arrocco è riconosciuto sia come mossa del re di due case sia come re sulla torre.
- **Suggerimento**: cerchia il pezzo da muovere; non fa fallire il puzzle.
- **Soluzione**: gioca la mossa giusta al posto del giocatore e fa fallire il puzzle.
- **Riprova**: compare dopo un errore o una soluzione mostrata, resta visibile per non spostare la scacchiera, e riporta il puzzle alla posizione iniziale. Errori e soluzioni mostrate restano segnati: anche se il nuovo tentativo riesce, il puzzle conta come fallito per il punteggio e per il ripasso, e senza XP se la soluzione era stata mostrata. L'esito viene registrato quando il puzzle finisce o si passa oltre con «Prossimo»; uscendo dalla schermata a metà non si registra nulla.
- **Prossimo**: si attiva a fine puzzle e ogni volta che c'è «Riprova»; in quel caso il puzzle viene registrato come fallito, senza XP. Resta disattivato se la sequenza non ha altri puzzle, per esempio nel puzzle del giorno.

I quattro pulsanti stanno in una riga che va a capo su due righe sugli schermi stretti, senza spezzare le etichette.

## Punteggio (RF-81)

Il punteggio del giocatore è un Glicko-2 locale che parte da 1500 con deviazione 350. Ogni puzzle concluso è una partita contro un avversario con il punteggio del puzzle e deviazione fissa 75: vinta se risolto al primo tentativo senza vedere la soluzione, persa altrimenti. Il punteggio cambia solo alla prima volta che si incontra un puzzle: rigiocare il puzzle del giorno o un puzzle già visto non modifica punteggio, contatori e XP, così non si possono accumulare punti ripetendo lo stesso problema.

Il puzzle successivo è quello non ancora visto con difficoltà più vicina al punteggio attuale; finiti i puzzle di un tema si ripropone quello visto meno di recente, così si ripassano tutti a rotazione.

## Obiettivo del puzzle

In cima alla pagina c'è una sola scheda. All'inizio dice obiettivo e colore che muove («Matto in 2 · Muove il Bianco», «Ottieni il vantaggio · Muove il Nero»), così si capisce se la mossa giusta è un matto o un guadagno; dopo ogni mossa la stessa scheda mostra l'esito (giusta, sbagliata, risolto), così la scacchiera non si sposta. `PuzzleGoal.of` ricava l'obiettivo dai temi Lichess con questa precedenza: `mateIn1`–`mateIn4`, `mate`/`mateIn5` («dai matto»), `equality`, `crushing`, `advantage`; senza questi temi la scheda dice «Trova la mossa migliore». Il testo è localizzato (`puzzleGoal` e `puzzleGoalSide` in `lib/l10n`, italiano e inglese) e nel profilo bambino «matto in N» diventa «dai matto», perché lì non ci sono cifre.

Sotto la scacchiera non c'è altro finché il puzzle è aperto: il punteggio compare solo nell'esito a puzzle finito, e difficoltà e temi (che sarebbero un indizio) solo a puzzle risolto. «Suggerimento» e «Soluzione» sono visibili finché il puzzle è aperto; «Riprova» dopo un errore; «Prossimo» solo quando c'è qualcosa da passare, cioè a puzzle risolto, dopo un errore o dopo la soluzione mostrata, e solo se c'è un puzzle successivo. La scheda mostra l'obiettivo solo all'inizio e dopo «Riprova»: negli esiti lascia il posto al messaggio, per non spostare la scacchiera.

Il punteggio mostrato a fine puzzle (per esempio «Punteggio 1427 (-248)» dopo «Mosse trovate: 4 di 4») non è in contraddizione: «Mosse trovate» conta anche le mosse mostrate con «Soluzione», mentre il punteggio considera il puzzle fallito se è stata vista la soluzione o fatto un errore.

## Puzzle del giorno (RF-84)

Il puzzle del giorno non richiede un server: l'indice è `(giorni dal 1970 × 7919) mod numero di puzzle`, uguale per tutti i dispositivi con la stessa versione della raccolta.

## Obiettivo e regole di ogni modalità

Ogni modalità spiega cosa fare, come si vince o si perde, tempo o vite e come si calcola il punteggio (`PuzzleGuide`, `lib/puzzles/mode_guide.dart`).

- **Serie, Combo a tempo, Corsa e Sopravvivenza**: prima di partire compare una schermata con l'**Obiettivo** e **Come si gioca**; il tempo parte solo con **Inizia** (e "Gioca ancora" a fine serie riparte senza ripetere la spiegazione). Il testo dell'obiettivo resta in cima durante il gioco.
- **Allenamento, Per tema, Puzzle del giorno e Ripasso**: la spiegazione si apre da sola, in un pannello, la prima volta che si entra nella modalità (`puzzles.guides.v1` ricorda quelle già lette) e si riapre sempre dall'icona **Come funziona** nella barra del titolo. Nel profilo bambino non compare, perché è fatta di regole e numeri (le modalità a serie non sono disponibili in quel profilo).

Durante il gioco l'avanzamento è sempre visibile:

- nelle serie, i punti, il tempo rimasto (con una barra, che sale quando arrivano i secondi bonus della combo) e le vite come cuori con etichetta per i lettori di schermo ("Vite: 2 su 3"); l'icona **Come funziona** riapre le regole, ma il tempo continua a scorrere;
- a fine serie, la schermata dice perché è finita (tempo scaduto, vite finite, primo errore o puzzle esauriti);
- nei puzzle singoli con più di una mossa, la barra delle **mosse trovate** ("Mosse trovate: 1 di 3"); con una sola mossa non compare; nel profilo bambino resta solo la barra, senza cifre.

I numeri citati nei testi (10 secondi, 3/5/7/10 secondi di bonus, intervalli del ripasso) hanno un test che li confronta con le regole del codice.

## Modalità a serie (RF-82)

| Modalità | Tempo | Fine | Note |
|---|---|---|---|
| Combo a tempo | 3 minuti | Allo scadere del tempo | Combo: +3 s a 5, +5 s a 12, +7 s a 20, +10 s a 30 e poi ogni 10; un errore toglie 10 s e azzera la combo |
| Corsa 3 minuti | 3 minuti | Tempo o tre errori | |
| Corsa 5 minuti | 5 minuti | Tempo o tre errori | |
| Sopravvivenza | Nessuno | Tre errori | |
| Serie | Nessuno | Primo errore | Un solo salto consentito |

In tutte le modalità la difficoltà cresce: il puzzle numero *n* è scelto a caso tra quelli con punteggio in `[600 + 60·n, 600 + 60·n + 40)`, mai ripetuto nella stessa serie. Il passo (60) è più ampio della finestra (40), così ogni puzzle è più difficile del precedente; se la finestra è vuota si prende il primo puzzle più difficile e, in cima alla raccolta, il più difficile rimasto. La ricerca usa l'ordinamento per punteggio (ricerca binaria), senza scorrere tutta la raccolta a ogni mossa. Un errore fa passare subito al puzzle successivo. Le serie non modificano il punteggio puzzle.

Il miglior risultato di ogni modalità è salvato come record personale (RG-08, chiave `puzzles.records.v1`) e un nuovo record viene festeggiato nella schermata finale. Record e XP dei puzzle risolti valgono anche se si esce a metà serie. Il record mostrato nella scheda Puzzle resta disponibile anche con la gamification spenta; il Profilo riceve lo stesso punteggio tramite `PuzzleRunFinished` per i suoi record personali.

Il modello è `lib/puzzles/puzzle_run.dart`, la schermata `lib/puzzles/puzzle_run_page.dart`; il tempo arriva da una funzione iniettabile, così i test non aspettano minuti veri.

## Sfida a tempo tra amici (RF-95)

Due telefoni giocano la stessa prova a tempo e ne confrontano i punteggi, senza rete, account o server. Si usa il trasporto QR dello scambio di partite ([scambio-qr.md](scambio-qr.md)). Si apre da **Puzzle › Sfida un amico**; nel profilo bambino la voce non compare, come le altre modalità a tempo.

| Passo | Chi | Cosa succede |
|---|---|---|
| 1 | Chi lancia | Sceglie la prova (Combo a tempo, Corsa 3 o 5 minuti) e tocca **Prepara la sfida**: l'app estrae un seme casuale a 32 bit |
| 2 | Chi lancia | **Mostra il QR all'amico**: il QR porta prova, seme e impronta della raccolta di puzzle |
| 3 | L'amico | **Ricevi una sfida** e inquadra il QR: si apre la stessa prova, con la spiegazione e il pulsante Inizia |
| 4 | Entrambi | Giocano la prova (anche in momenti diversi): il seme guida la scelta dei puzzle, quindi la sequenza è identica sui due telefoni |
| 5 | Entrambi | A fine prova **Mostra il mio risultato** (QR col punteggio) e **Leggi il risultato dell'amico**; poi la schermata dice "Hai vinto: 9 a 7", "Ha vinto l'amico: 7 a 9" o "Pareggio: 8 a 8" |

Perché i puzzle sono gli stessi: `PuzzleRun` accetta un generatore casuale e la sfida usa `SeededRandom` (mulberry32, sequenza fissa per ogni seme: `Random(seed)` di Dart non garantisce la stessa sequenza tra versioni e piattaforme). Con esso la scelta di ogni puzzle dipende solo dal seme, dalla prova e dalla raccolta, non dalle risposte date (un errore e una risposta giusta fanno avanzare allo stesso modo). Per questo sono ammesse solo le prove a tempo, dove tutti hanno la stessa durata e un errore non cambia la sequenza; sopravvivenza e serie, che finiscono in momenti diversi, restano fuori.

Messaggi (`lib/puzzles/friend_challenge.dart`, Dart puro): JSON compatto in un solo fotogramma `SC1`, in due forme.

| Campo | Lancio | Risultato |
|---|---|---|
| `k` | `sfida` | `risultato` |
| `v` | 1 | 1 |
| `m` | nome della prova (`storm`, `rush3`, `rush5`) | idem |
| `s` | seme, intero da 0 a 4294967295 | idem |
| `l` | impronta della raccolta, CRC-32 in 8 cifre esadecimali | idem |
| `p` | | punteggio, da 0 a 9999 |

L'**impronta della raccolta** è il CRC-32 di versione dell'algoritmo, identificativi, punteggi e ordine dei puzzle: se i due telefoni hanno versioni diverse dei puzzle, il seme darebbe serie diverse, quindi la sfida non parte e l'app chiede di aggiornare Rokko su entrambi. Un risultato appartiene alla sfida solo se coincidono prova, seme e impronta; uno di un'altra sfida viene respinto con un avviso.

Sicurezza (MASVS-CODE-4): il testo letto dalla fotocamera è input non fidato. Dopo il ricompositore dei QR, `parseChallenge` rifiuta testi oltre 512 caratteri, JSON non valido o non oggetto, versione o tipo sconosciuti, prove non a tempo, semi o punteggi fuori intervallo e impronte malformate. Il QR del risultato **non è firmato**: è pensato per una sfida tra amici, non per una classifica, e chi vuole può barare mostrando un punteggio inventato. Non c'è nessun dato personale nei QR.

In una sfida si gioca una volta sola: **Gioca ancora** non compare, perché ripeterebbe gli stessi puzzle. Record personali, XP e traguardi valgono come in una serie normale. La schermata del confronto è una colonna scorrevole, con etichette e annunci per i lettori di schermo (l'esito è una regione viva) e i testi nei file `.arb` (`challenge*`) in italiano e inglese.

Il codice è in `lib/puzzles/friend_challenge.dart` (messaggi e confronto), `friend_challenge_page.dart` (lancio e ricezione) e `challenge_result_panel.dart` (confronto a fine prova); `PuzzleRunPage` riceve la sfida con il parametro `challenge`.

## Ripasso degli errori (RF-85)

Ogni puzzle sbagliato nell'allenamento, anche se già visto, entra in una coda di ripasso a intervalli crescenti (sistema di Leitner, `lib/puzzles/review_queue.dart`):

| Livello | Torna dopo |
|---|---|
| 0 (appena sbagliato) | 1 giorno |
| 1 | 3 giorni |
| 2 | 7 giorni |
| 3 | 14 giorni |
| 4 | 30 giorni |

Un ripasso riuscito fa salire di livello; superato l'ultimo, il puzzle è considerato imparato ed esce dalla coda. Un nuovo errore lo riporta al livello 0. Le scadenze sono calcolate a giorni di calendario (dalla mezzanotte), così un errore della sera torna disponibile dal mattino dopo. La voce "Ripasso degli errori" mostra quanti puzzle sono in scadenza oggi, dal più in ritardo, ignorando quelli non più presenti nella raccolta dopo un aggiornamento; vi entrano anche i puzzle personali ricavati dagli errori delle proprie partite (vedi [revisione-partita.md](revisione-partita.md)); il ripasso non modifica il punteggio e, finiti i puzzle in scadenza, lo segnala.

Le schermate di risoluzione ricevono i puzzle da un `PuzzleFeed` (`lib/puzzles/puzzle_feed.dart`): `RatedFeed` per l'allenamento e i temi, `SingleFeed` per il puzzle del giorno, `ReviewFeed` per il ripasso.

## Salvataggio

Punteggio, puzzle visti, contatori, spiegazioni delle modalità già lette (`puzzles.guides.v1`), coda di ripasso (`puzzles.review.v1`) e record delle serie (`puzzles.records.v1`) sono salvati nel file `training.json` della cartella dati dell'app (chiave `puzzles.trainer.v1` per il punteggio) tramite l'interfaccia `KeyValueStore` (`lib/storage/key_value_store.dart`). Il file passa da `JsonFile` (`lib/storage/json_file.dart`), lo stesso di progressi e archivio: scrittura atomica, salvataggi accodati, file non valido messo da parte come `training.json.bad-<ms>` invece di essere sovrascritto. Sarà importato nel database locale quando arriverà (RNF-08). Dati del punteggio illeggibili vengono ignorati e si riparte da 1500.

## Integrazione con la gamification

Ogni puzzle nuovo portato a termine dal giocatore, anche dopo un tentativo sbagliato, registra un `PuzzleSolved` con temi, punteggio aggiornato e durata nel `ProgressController` (XP, obiettivo giornaliero "5 puzzle", traguardi) e mostra la notifica `showProgressFeedback`. Un puzzle concluso con "Soluzione" non vale XP. Nelle modalità a serie i puzzle risolti e un `PuzzleRunFinished` (modalità e punteggio) vengono registrati a fine serie, con un'unica notifica riassuntiva; anche i puzzle del ripasso valgono XP, perché arrivano solo alla scadenza e non si possono ripetere a piacere. Gli XP premiano l'impegno, come le partite perse (RG-01): per questo un puzzle risolto dopo un errore vale XP anche se per il punteggio conta come fallito. Il collegamento passa da `HomeShell`, che apre i progressi alla prima attività, alle schermate tramite il parametro `onActivity` (`lib/puzzles/activity_recorder.dart`).

Nel profilo bambino (RP-06) l'hub e la pagina del puzzle non mostrano punteggio, difficoltà e contatori e le modalità a tempo sono nascoste: vedi [profilo-bambino.md](profilo-bambino.md#niente-numeri).

## Navigazione

L'app ha una barra di navigazione in basso (`lib/home/home_shell.dart`) con le schede **Gioca**, **Puzzle**, **Aperture** e **Tu**. I puzzle vengono caricati solo alla prima apertura della scheda, così l'avvio dell'app non rallenta.
