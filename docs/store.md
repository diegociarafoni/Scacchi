# Pubblicazione sugli store (Fastlane)

La configurazione di [Fastlane](https://fastlane.tools) è pronta ma **senza credenziali**: nel repository non c'è nessun segreto e, finché non vengono inseriti, nulla viene pubblicato. Serve solo quando si decide di entrare nei negozi; l'APK diretto da GitHub ([rilascio-android.md](rilascio-android.md)) non cambia.

## Che cosa c'è

| File | Contenuto |
|---|---|
| `Gemfile`, `Gemfile.lock` | Fastlane con versione fissata; il file di blocco ha gli hash delle dipendenze |
| `android/fastlane/Appfile` | Identificativo del pacchetto (`io.github.diegociarafoni.scacchi`) |
| `android/fastlane/Fastfile` | Corsia `convalida` (controlla la chiave) e corsia `interna` (carica un bundle firmato sulla traccia interna di Google Play, come bozza) |
| `.github/workflows/store.yml` | Avvio manuale: esegue `convalida`; senza segreti fallisce con un messaggio |
| `android/fastlane/metadata/android/<lingua>/` | Scheda per Google Play e F-Droid in italiano (`it-IT`) e inglese (`en-US`): titolo, descrizione breve (80 caratteri) e completa, icona 512 px. `test/store/store_metadata_test.dart` controlla i limiti |
| `ios/fastlane/Appfile`, `ios/fastlane/Fastfile` | Corsie `convalida` (la chiave di App Store Connect è valida) e `beta` (firma, archivio e caricamento su TestFlight) |
| `.github/workflows/store-ios.yml` | Avvio manuale delle due corsie iOS su un runner macOS; senza segreti fallisce con un messaggio |
| `.github/workflows/ios.yml` | Compila l'app per iOS senza firma (PR che toccano `ios/` o le dipendenze, `main`, a richiesta): se la build iOS si rompe lo si vede subito |
| `fdroid/io.github.diegociarafoni.scacchi.yml` | Ricetta di F-Droid, pronta da copiare in fdroiddata |

## Segreti da inserire

In https://github.com/diegociarafoni/rokko/settings/secrets/actions (**New repository secret**):

| Nome del segreto | A che cosa serve | Quando |
|---|---|---|
| `PLAY_SERVICE_ACCOUNT_JSON` | Contenuto del file JSON dell'account di servizio di Google Cloud con accesso a Google Play Console (Impostazioni → Accesso API) | Per `convalida` e per `interna` |
| `ANDROID_SIGNING_SEED` oppure `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | Chiave di firma: sono gli stessi segreti già usati per l'APK | Per costruire il bundle da caricare |

Su Google Play serve inoltre un account sviluppatore e l'app creata in Play Console; la prima versione va caricata a mano. Se si attiva «Play App Signing», la chiave caricata resta quella del progetto e Google firma per la distribuzione.

### iOS e TestFlight

Servono l'iscrizione all'Apple Developer Program, l'app creata in App Store Connect con l'identificativo `io.github.diegociarafoni.scacchi`, e questi segreti dello stesso elenco:

| Nome del segreto | Che cosa contiene |
|---|---|
| `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY_P8` | Chiave API di App Store Connect (Utenti e accessi → Integrazioni → Chiavi): identificativo, emittente e contenuto del file `.p8` |
| `IOS_DISTRIBUTION_CERT_BASE64`, `IOS_CERT_PASSWORD` | Certificato «Apple Distribution» esportato come `.p12` (in base64) e la sua password |
| `IOS_PROVISIONING_PROFILE_BASE64` | Profilo di provisioning «App Store» per l'app (in base64) |
| `APPLE_TEAM_ID` | Identificativo del team (10 caratteri) |

Con i primi tre si lancia Actions → Store iOS → Run workflow con corsia `convalida`. Con tutti si lancia `beta`: il workflow esegue `flutter build ios --config-only` con un numero di build crescente, firma, archivia e carica la build su TestFlight. La corsia `beta` non è stata provata, perché le credenziali non sono nel repository: la prima esecuzione reale potrebbe richiedere piccoli aggiustamenti. La dichiarazione di crittografia da confermare in App Store Connect e le risposte per la scheda privacy sono in [privacy-store.md](privacy-store.md); la verifica scritta della licenza è in [licenza.md](licenza.md).

### F-Droid

F-Droid costruisce l'app dai sorgenti e la firma con la propria chiave, quindi non servono segreti: il repository è già pubblico, con licenza libera e senza dipendenze proprietarie (nessun servizio Google, pubblicità o analisi: `tool/policy.json`). Per entrare nel catalogo si apre una richiesta di unione su [fdroiddata](https://gitlab.com/fdroid/fdroiddata) con `fdroid/io.github.diegociarafoni.scacchi.yml`, dopo aver attivato il blocco `Builds` con la versione numerata e il suo `versionCode` (il numero di commit del tag). Serve un account GitLab. La scheda (titolo, descrizioni, icona) viene dalle stesse cartelle di Google Play; mancano le schermate, che vanno catturate da un telefono vero in `images/phoneScreenshots/` di ogni lingua. La ricetta non è stata provata con `fdroid build`.

## Uso

Dopo aver inserito `PLAY_SERVICE_ACCOUNT_JSON`: Actions → Store → Run workflow. Se la chiave è valida il passo «Convalida» riesce. Il caricamento vero e proprio (`bundle exec fastlane android interna`, con `AAB_PATH` che punta al bundle firmato) non è collegato a nessun workflow: si aggiunge insieme alla build del bundle quando si decide di pubblicare.
