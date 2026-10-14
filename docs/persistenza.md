# Persistenza

Requisito RNF-08. Il codice è in `lib/storage/`.

## Decisione

Rokko **resta sui file JSON versionati** (`JsonFile`) e aggiunge la catena di migrazioni. Non passa a un database locale (SQLite, per esempio con `drift`). Motivi:

- I dati sono pochi e piccoli: partite, progressi, stelle del percorso, coda di ripasso. Si leggono interi all'avvio di una schermata e non servono interrogazioni.
- Un file per area si può esportare, copiare e ripristinare così com'è: la copia di sicurezza e il passaggio ad altro telefono ([backup.md](backup.md)) lavorano già su quei file.
- Un database aggiunge un pacchetto nativo per ogni piattaforma, un costo in dimensioni e un secondo formato da mantenere, senza un beneficio che oggi si veda.
- La scelta si può rivedere: se l'archivio delle partite crescesse fino a rendere lenta la lettura intera (si misura con `integration_test/fluidita_perf.dart`), si sposterebbe solo quel file su un database e il resto resterebbe com'è. L'archivio è già dietro `GameArchive`, quindi il cambio resterebbe nascosto.

## Come funziona

`JsonFile(file, version: n, migrations: {...})` scrive `{"version": n, ...}` con rinomina atomica e salvataggi accodati. In lettura:

1. Un file mancante dà `null`.
2. Una versione assente, minore di 1 o **maggiore** di quella dell'app (file scritto da un'app più nuova) mette il file da parte come `.bad-<ms>` e dà `null`: non si sovrascrive mai ciò che non si capisce.
3. Un file **più vecchio** passa dalle migrazioni: `migrations[n]` porta il contenuto dalla versione `n` alla `n + 1`, in ordine, fino alla versione corrente. Prima si tiene una copia dell'originale in `<file>.v<n>.bak`, una sola per versione, così un passo sbagliato non perde i dati.
4. Se manca un passo o una migrazione lancia un errore, il file si mette da parte come per un file illeggibile e la copia `.v<n>.bak` resta.

La lettura non riscrive il file: lo aggiorna il primo salvataggio, che scrive la versione nuova.

## Come aggiungere una versione dello schema

1. Alza `version` dove si crea il `JsonFile` (per i progressi, `ProgressStore.schemaVersion`).
2. Aggiungi `migrations: {n: _daNaN1}` con una funzione pura da `Map<String, Object?>` a `Map<String, Object?>`; non serve scrivere `version`.
3. Scrivi un test come quelli di `test/storage/json_file_test.dart`: un file della versione `n` con dati veri, letto dal controller dell'area.
4. Aggiorna la riga dell'area in questa pagina o nel suo documento.

Oggi tutti i file sono alla versione 1 e quindi senza migrazioni. Il file `training.json` (`JsonFileStore`) tiene le sue chiavi e le versiona nel nome (`puzzles.guides.v1`).
