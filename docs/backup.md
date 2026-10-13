# Backup e ripristino

Offline non esiste una copia online dei dati: il backup (RF-103) li raccoglie in un solo file JSON che l'utente conserva dove preferisce.

## Cosa contiene

- Partite dell'archivio, progressi, percorso, storia, tornei e allenamento (`games.json`, `progress.json`, `path.json`, `story.json`, `tornei.json`, `training.json`).
- Diario della settimana (`week.json`, [riepilogo-settimanale.md](riepilogo-settimanale.md)), progressi dei grandi maestri (`masters.json`) e dell'allenatore dei finali (`endgames.json`).
- Partita a due telefoni in corso (`multiplayer.json`, vedi [multigiocatore.md](multigiocatore.md)). Contiene la chiave privata della partita: chi riceve il backup potrebbe giocarla al posto tuo, quindi conserva il file solo dove ti fidi.
- Foto del profilo (`avatar_photo.jpg`), nel campo `binaries` in base64. Resta solo sul telefono e non va online: entra soltanto nel file di backup che crei tu.
- Impostazioni e preferenze (`SharedPreferences`): bool, numeri, testo ed elenchi di testo.

## Compatibilità

Il formato è alla versione 2 (la 1 non aveva settimana, maestri, finali, partita a due telefoni e foto). Un backup di versione 1 si ripristina ancora: i dati che non conteneva restano come sono sul telefono. Con un backup di versione 2 i dati assenti (per esempio nessuna foto) vengono invece tolti, con copia di sicurezza. Un backup più recente della 2 è rifiutato.

## Uso

**Impostazioni → Profilo → Backup e ripristino**

- **Condividi il backup** crea `rokko-backup-AAAA-MM-GG.json` e apre il menu di condivisione del sistema.
- **Ripristina da testo** chiede di incollare il contenuto del file e rifiuta i backup non validi. Il backup valido resta in attesa (`ripristino-in-attesa.json`) e viene applicato al prossimo avvio, prima che qualunque archivio sia caricato, così nessun dato in memoria lo sovrascrive. Chiudi e riapri l'app.

All'avvio i file locali sostituiti, o assenti dal backup, restano accanto con suffisso `.prima-del-ripristino-<ora>`; le preferenze vengono sostituite per intero.

## Regole di sicurezza

`Backup.decode` rifiuta: testo non JSON, altra app, versione dello schema più recente, nomi di file fuori dall'elenco (nessuna scrittura fuori dalla cartella dati), file che non sono JSON con una versione dello schema, binari fuori elenco o non base64 e preferenze di tipo non semplice. All'avvio i file si scrivono in modo atomico (file temporaneo e rinomina).

## Codice

`lib/backup/backup.dart` (formato e ripristino, senza interfaccia) e `lib/backup/backup_page.dart` (pagina). Test in `test/backup/`.
