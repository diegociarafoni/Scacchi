# Dichiarazioni sulla privacy per gli store

Rokko non ha account, pubblicità, analisi né tracciamento (requisiti RV-02 e RNF-10; i pacchetti vietati sono controllati da `tool/policy.json`). Questo documento raccoglie le risposte da dare nelle schede degli store, così che chi pubblica non debba ricostruirle. Le risposte sono **da riconfermare a ogni versione che aggiunge un permesso o un servizio** (`test/security/privacy_declarations_test.dart` controlla i file iOS e la presenza di questo documento; i permessi Android sono controllati da `test/security/masvs_test.dart`).

## Che cosa lascia il telefono

| Funzione | Che cosa esce | Verso chi | Quando |
|---|---|---|---|
| Giocare da soli, puzzle, lezioni, revisione | Niente | | Mai |
| Partita in rete locale o Bluetooth | Mosse cifrate | L'altro telefono | Solo se si sceglie quella partita |
| Partita a distanza | Eventi Nostr firmati e cifrati con le mosse | I relay indicati nell'app | Solo se si sceglie la partita a distanza |
| Condivisione di PGN, immagini e backup | Il file scelto | L'app scelta dal menu di condivisione del sistema | Solo su azione esplicita |
| Fotocamera | Niente: serve a leggere un QR sul telefono | | Solo su azione esplicita |

Le mosse della partita a distanza passano da server di terzi (i relay), ma sono cifrate da un capo all'altro, non contengono nome né account e partono solo se l'utente avvia quella partita: per questo le schede sotto le trattano come dati non raccolti dallo sviluppatore. È una lettura delle regole degli store, da riconfermare prima della prima pubblicazione.

## Apple App Store (Privacy Nutrition Label)

- Risposta nella scheda «App Privacy»: **Data Not Collected**.
- Nessun tracciamento: `NSPrivacyTracking` falso e nessun dominio in `NSPrivacyTrackingDomains`.
- `ios/Runner/PrivacyInfo.xcprivacy` dichiara `NSPrivacyCollectedDataTypes` vuoto e le due API a motivo obbligatorio usate dall'app: `UserDefaults` (`CA92.1`, impostazioni salvate con `shared_preferences`) e le date dei file (`C617.1`, file dell'app nella sua cartella dati, letti con `path_provider`). I pacchetti Flutter portano i loro manifesti, che Xcode unisce a quello dell'app.
- URL dell'informativa: la pagina di questo repository con il testo qui sotto (`https://github.com/diegociarafoni/rokko/blob/main/docs/privacy-store.md`).

### Crittografia per l'esportazione

`ITSAppUsesNonExemptEncryption` è **vero** in `ios/Runner/Info.plist`: il multigiocatore usa AES-GCM, Ed25519 e HKDF con il pacchetto `cryptography`, quindi con algoritmi standard ma fuori da quelli del sistema (vedi [multigiocatore.md](multigiocatore.md)). Con il valore vero App Store Connect chiede la documentazione di conformità all'esportazione una volta per app. È una dichiarazione legale del titolare dell'account: la scelta prudente è questa, e se il titolare stabilisce che l'app rientra in un'esenzione basta cambiare il valore in falso, senza altre modifiche al codice.

## Google Play (Data safety)

- «L'app raccoglie o condivide dati utente richiesti?»: **No**. Nessuna sezione di dati da compilare.
- «Tutti i dati sono cifrati in transito?»: non applicabile; la partita a distanza è comunque cifrata da un capo all'altro.
- «Gli utenti possono chiedere la cancellazione dei dati?»: non applicabile, i dati restano sul telefono e si cancellano disinstallando l'app o dal backup nelle Impostazioni.
- Permessi da dichiarare nel modulo dell'app: quelli di `privacy.androidPermissions` in `tool/policy.json` (avvio, fotocamera, internet, Bluetooth), tutti spiegati in [sicurezza.md](sicurezza.md).
- Pubblico: l'app ha un profilo bambino, ma funziona senza account e senza raccogliere nulla; la scheda «Famiglie» di Google Play si compila quando si decide di includerla.

## Informativa sulla privacy (testo da pubblicare)

**Italiano.** Rokko non raccoglie, non vende e non condivide dati personali. Non ci sono account, pubblicità, strumenti di analisi o tracciamento. Partite, progressi, impostazioni e foto del profilo restano sul tuo telefono; li cancelli disinstallando l'app. Le funzioni che usano la rete (partita in rete locale, Bluetooth, a distanza) partono solo quando le scegli e inviano soltanto le mosse, cifrate, all'altro giocatore; la partita a distanza passa da relay Nostr da te indicati, che non vedono il contenuto. Condividere un file (PGN, immagine, backup) lo invia solo all'app che scegli tu. La fotocamera serve soltanto a leggere un codice QR sul telefono. Il codice è pubblico e verificabile: `https://github.com/diegociarafoni/rokko`.

**English.** Rokko does not collect, sell or share personal data. There are no accounts, ads, analytics or tracking. Games, progress, settings and profile photo stay on your phone; uninstalling the app deletes them. Network features (local network, Bluetooth, remote play) only start when you choose them and send only the moves, encrypted, to the other player; remote play goes through Nostr relays you pick, which cannot read the content. Sharing a file (PGN, image, backup) sends it only to the app you choose. The camera is used only to read a QR code on the phone. The code is public: `https://github.com/diegociarafoni/rokko`.

## Che cosa resta a chi pubblica

Compilare le schede nelle console con queste risposte e inserire l'URL dell'informativa: richiede l'account di sviluppatore e non può farlo il repository. Elenco completo delle azioni dell'account in [store.md](store.md).
