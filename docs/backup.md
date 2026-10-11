# Backup e ripristino

Offline non esiste una copia online dei dati: il backup (RF-103) li raccoglie in un solo file JSON che l'utente conserva dove preferisce.

## Cosa contiene

- Partite dell'archivio, progressi, percorso, tornei e allenamento (`games.json`, `progress.json`, `path.json`, `tornei.json`, `training.json`).
- Impostazioni e preferenze (`SharedPreferences`): bool, numeri, testo ed elenchi di testo.

## Uso

**Impostazioni → Backup e ripristino**

- **Condividi il backup** crea `scacchi-backup-AAAA-MM-GG.json` e apre il menu di condivisione del sistema.
- **Ripristina da testo** chiede di incollare il contenuto del file, rifiuta i backup non validi e, se è valido, sostituisce i dati. Quelli precedenti restano accanto, con suffisso `.prima-del-ripristino`. Dopo il ripristino occorre riavviare l'app.

## Regole di sicurezza

`Backup.decode` rifiuta: testo non JSON, altra app, versione dello schema più recente, nomi di file fuori dall'elenco (nessuna scrittura fuori dalla cartella dati), contenuti dei file che non sono JSON e preferenze di tipo non semplice. I file si scrivono in modo atomico (file temporaneo e rinomina).

## Codice

`lib/backup/backup.dart` (formato e ripristino, senza interfaccia) e `lib/backup/backup_page.dart` (pagina). Test in `test/backup/`.
