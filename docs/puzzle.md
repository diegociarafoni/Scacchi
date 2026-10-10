# Puzzle

Problemi tattici offline, sul modello dei puzzle di chess.com e Lichess (requisiti RF-80 – RF-85).

## Dati

La raccolta è un sottoinsieme del [database dei puzzle di Lichess](https://database.lichess.org/#puzzles), rilasciato in pubblico dominio (CC0). Il file `assets/puzzles/puzzles.csv` è incluso nell'app e contiene circa 4.600 problemi (circa 650 KB, compressi ulteriormente nel pacchetto).

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

Il workflow `.github/workflows/datasets.yml` scarica il database, esegue lo script e fa il commit del risultato sul branch della pull request quando gli script in `tool/datasets/` cambiano; si può avviare anche a mano. In locale:

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
| `lib/training/training_board.dart` | Scacchiera per esercizi, riusabile da puzzle e aperture |

## Regole di risoluzione

- Il puzzle parte con la mossa dell'avversario già giocata; la scacchiera è orientata dal lato del giocatore.
- Una mossa diversa dalla soluzione viene annullata con il messaggio "Non è la mossa giusta. Riprova." e il puzzle conta come fallito, ma si può continuare a cercare.
- All'ultima mossa è accettato anche un matto diverso da quello previsto, come su Lichess.
- L'arrocco è riconosciuto sia come mossa del re di due case sia come re sulla torre.
- **Suggerimento**: cerchia il pezzo da muovere; non fa fallire il puzzle.
- **Soluzione**: gioca la mossa giusta al posto del giocatore e fa fallire il puzzle.

## Punteggio (RF-81)

Il punteggio del giocatore è un Glicko-2 locale che parte da 1500 con deviazione 350. Ogni puzzle concluso è una partita contro un avversario con il punteggio del puzzle e deviazione fissa 75: vinta se risolto al primo tentativo senza vedere la soluzione, persa altrimenti. Il punteggio viene aggiornato una sola volta per puzzle.

Il puzzle successivo è quello non ancora visto con difficoltà più vicina al punteggio attuale; finiti i puzzle di un tema si ricomincia dai già visti.

## Puzzle del giorno (RF-84)

Sostituisce il puzzle del giorno di chess.com senza server: l'indice è `(giorni dal 1970 × 7919) mod numero di puzzle`, uguale per tutti i dispositivi con la stessa versione della raccolta.

## Salvataggio

Punteggio, puzzle visti e contatori sono salvati nel file `training.json` della cartella dati dell'app (chiave `puzzles.trainer.v1`) tramite l'interfaccia `KeyValueStore` (`lib/storage/key_value_store.dart`). Il file è scritto in modo atomico (file temporaneo rinominato), come `progress.json` della gamification, e sarà importato nel database locale quando arriverà (RNF-08). Dati illeggibili vengono ignorati e si riparte da 1500.

## Integrazione con la gamification

`PuzzleTrainer.onCompleted` riceve un `PuzzleCompleted` (puzzle, esito, variazione di punteggio) per ogni puzzle concluso: è il punto in cui assegnare XP, aggiornare l'obiettivo giornaliero e le medaglie.

## Navigazione

L'app ha una barra di navigazione in basso (`lib/home/home_shell.dart`) con le schede **Gioca** e **Puzzle**. I puzzle vengono caricati solo alla prima apertura della scheda, così l'avvio dell'app non rallenta.
