# Puzzle

Problemi tattici offline, sul modello dei puzzle di chess.com e Lichess (requisiti RF-80 – RF-85).

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
| `lib/training/training_board.dart` | Scacchiera per esercizi, riusabile da puzzle e aperture; segue le impostazioni della scacchiera tramite `SettingsScope` |

## Regole di risoluzione

- Il puzzle parte con la mossa dell'avversario già giocata; la scacchiera è orientata dal lato del giocatore.
- Una mossa diversa dalla soluzione viene annullata con il messaggio "Non è la mossa giusta. Riprova." e il puzzle conta come fallito, ma si può continuare a cercare.
- All'ultima mossa è accettato anche un matto diverso da quello previsto, come su Lichess.
- L'arrocco è riconosciuto sia come mossa del re di due case sia come re sulla torre.
- **Suggerimento**: cerchia il pezzo da muovere; non fa fallire il puzzle.
- **Soluzione**: gioca la mossa giusta al posto del giocatore e fa fallire il puzzle.

## Punteggio (RF-81)

Il punteggio del giocatore è un Glicko-2 locale che parte da 1500 con deviazione 350. Ogni puzzle concluso è una partita contro un avversario con il punteggio del puzzle e deviazione fissa 75: vinta se risolto al primo tentativo senza vedere la soluzione, persa altrimenti. Il punteggio cambia solo alla prima volta che si incontra un puzzle: rigiocare il puzzle del giorno o un puzzle già visto non modifica punteggio, contatori e XP, così non si possono accumulare punti ripetendo lo stesso problema.

Il puzzle successivo è quello non ancora visto con difficoltà più vicina al punteggio attuale; finiti i puzzle di un tema si ripropone quello visto meno di recente, così si ripassano tutti a rotazione.

## Puzzle del giorno (RF-84)

Sostituisce il puzzle del giorno di chess.com senza server: l'indice è `(giorni dal 1970 × 7919) mod numero di puzzle`, uguale per tutti i dispositivi con la stessa versione della raccolta.

## Modalità a serie (RF-82)

| Modalità | Tempo | Fine | Note |
|---|---|---|---|
| Puzzle Storm | 3 minuti | Allo scadere del tempo | Combo: +3 s a 5, +5 s a 12, +7 s a 20, +10 s a 30 e poi ogni 10; un errore toglie 10 s e azzera la combo |
| Rush 3 minuti | 3 minuti | Tempo o tre errori | |
| Rush 5 minuti | 5 minuti | Tempo o tre errori | |
| Sopravvivenza | Nessuno | Tre errori | |
| Serie (Streak) | Nessuno | Primo errore | Un solo salto consentito |

In tutte le modalità la difficoltà cresce: il puzzle numero *n* è scelto a caso tra quelli con punteggio in `[600 + 60·n, 600 + 60·n + 40)`, mai ripetuto nella stessa serie. Il passo (60) è più ampio della finestra (40), così ogni puzzle è più difficile del precedente; se la finestra è vuota si prende il primo puzzle più difficile e, in cima alla raccolta, il più difficile rimasto. La ricerca usa l'ordinamento per punteggio (ricerca binaria), senza scorrere tutta la raccolta a ogni mossa. Un errore fa passare subito al puzzle successivo. Le serie non modificano il punteggio puzzle.

Il miglior risultato di ogni modalità è salvato come record personale (RG-08, chiave `puzzles.records.v1`) e un nuovo record viene festeggiato nella schermata finale. Record e XP dei puzzle risolti valgono anche se si esce a metà serie. Il record mostrato nella scheda Puzzle resta disponibile anche con la gamification spenta; il Profilo riceve lo stesso punteggio tramite `PuzzleRunFinished` per i suoi record personali.

Il modello è `lib/puzzles/puzzle_run.dart`, la schermata `lib/puzzles/puzzle_run_page.dart`; il tempo arriva da una funzione iniettabile, così i test non aspettano minuti veri.

## Ripasso degli errori (RF-85)

Ogni puzzle sbagliato nell'allenamento, anche se già visto, entra in una coda di ripasso a intervalli crescenti, sul modello di Chess Tempo (sistema di Leitner, `lib/puzzles/review_queue.dart`):

| Livello | Torna dopo |
|---|---|
| 0 (appena sbagliato) | 1 giorno |
| 1 | 3 giorni |
| 2 | 7 giorni |
| 3 | 14 giorni |
| 4 | 30 giorni |

Un ripasso riuscito fa salire di livello; superato l'ultimo, il puzzle è considerato imparato ed esce dalla coda. Un nuovo errore lo riporta al livello 0. Le scadenze sono calcolate a giorni di calendario (dalla mezzanotte), così un errore della sera torna disponibile dal mattino dopo. La voce "Ripasso degli errori" mostra quanti puzzle sono in scadenza oggi, dal più in ritardo, ignorando quelli non più presenti nella raccolta dopo un aggiornamento; il ripasso non modifica il punteggio e, finiti i puzzle in scadenza, lo segnala.

Le schermate di risoluzione ricevono i puzzle da un `PuzzleFeed` (`lib/puzzles/puzzle_feed.dart`): `RatedFeed` per l'allenamento e i temi, `SingleFeed` per il puzzle del giorno, `ReviewFeed` per il ripasso.

## Salvataggio

Punteggio, puzzle visti, contatori, coda di ripasso (`puzzles.review.v1`) e record delle serie (`puzzles.records.v1`) sono salvati nel file `training.json` della cartella dati dell'app (chiave `puzzles.trainer.v1` per il punteggio) tramite l'interfaccia `KeyValueStore` (`lib/storage/key_value_store.dart`). Il file passa da `JsonFile` (`lib/storage/json_file.dart`), lo stesso di progressi e archivio: scrittura atomica, salvataggi accodati, file non valido messo da parte come `training.json.bad-<ms>` invece di essere sovrascritto. Sarà importato nel database locale quando arriverà (RNF-08). Dati del punteggio illeggibili vengono ignorati e si riparte da 1500.

## Integrazione con la gamification

Ogni puzzle nuovo portato a termine dal giocatore, anche dopo un tentativo sbagliato, registra un `PuzzleSolved` con temi, punteggio aggiornato e durata nel `ProgressController` (XP, obiettivo giornaliero "5 puzzle", traguardi) e mostra la notifica `showProgressFeedback`. Un puzzle concluso con "Soluzione" non vale XP. Nelle modalità a serie i puzzle risolti e un `PuzzleRunFinished` (modalità e punteggio) vengono registrati a fine serie, con un'unica notifica riassuntiva; anche i puzzle del ripasso valgono XP, perché arrivano solo alla scadenza e non si possono ripetere a piacere. Gli XP premiano l'impegno, come le partite perse (RG-01): per questo un puzzle risolto dopo un errore vale XP anche se per il punteggio conta come fallito. Il collegamento passa da `HomeShell`, che apre i progressi alla prima attività, alle schermate tramite il parametro `onActivity` (`lib/puzzles/activity_recorder.dart`).

## Navigazione

L'app ha una barra di navigazione in basso (`lib/home/home_shell.dart`) con le schede **Gioca**, **Puzzle** e **Aperture**. I puzzle vengono caricati solo alla prima apertura della scheda, così l'avvio dell'app non rallenta.
