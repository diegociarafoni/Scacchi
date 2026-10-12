# Backup e ripristino

Offline non esiste una copia online dei dati: il backup (RF-103) li raccoglie in un solo file JSON che l'utente conserva dove preferisce.

## Cosa contiene

- Partite dell'archivio, progressi, percorso, storia, tornei e allenamento (`games.json`, `progress.json`, `path.json`, `story.json`, `tornei.json`, `training.json`).
- Impostazioni e preferenze (`SharedPreferences`): bool, numeri, testo ed elenchi di testo.

## Uso

**Impostazioni → Backup e ripristino**

- **Condividi il backup** crea `rokko-backup-AAAA-MM-GG.json` e apre il menu di condivisione del sistema.
- **Ripristina da testo** chiede di incollare il contenuto del file e rifiuta i backup non validi. Il backup valido resta in attesa (`ripristino-in-attesa.json`) e viene applicato al prossimo avvio, prima che qualunque archivio sia caricato, così nessun dato in memoria lo sovrascrive. Chiudi e riapri l'app.

All'avvio i file locali sostituiti, o assenti dal backup, restano accanto con suffisso `.prima-del-ripristino-<ora>`; le preferenze vengono sostituite per intero.

## Regole di sicurezza

`Backup.decode` rifiuta: testo non JSON, altra app, versione dello schema più recente, nomi di file fuori dall'elenco (nessuna scrittura fuori dalla cartella dati), file che non sono JSON con una versione dello schema e preferenze di tipo non semplice. All'avvio i file si scrivono in modo atomico (file temporaneo e rinomina).

## Codice

`lib/backup/backup.dart` (formato e ripristino, senza interfaccia) e `lib/backup/backup_page.dart` (pagina). Test in `test/backup/`.
