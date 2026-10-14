# Pubblicazione sugli store (Fastlane)

La configurazione di [Fastlane](https://fastlane.tools) è pronta ma **senza credenziali**: nel repository non c'è nessun segreto e, finché non vengono inseriti, nulla viene pubblicato. Serve solo quando si decide di entrare nei negozi; l'APK diretto da GitHub ([rilascio-android.md](rilascio-android.md)) non cambia.

## Che cosa c'è

| File | Contenuto |
|---|---|
| `Gemfile`, `Gemfile.lock` | Fastlane con versione fissata; il file di blocco ha gli hash delle dipendenze |
| `android/fastlane/Appfile` | Identificativo del pacchetto (`io.github.diegociarafoni.rokko`) |
| `android/fastlane/Fastfile` | Corsia `convalida` (controlla la chiave) e corsia `interna` (carica un bundle firmato sulla traccia interna di Google Play, come bozza) |
| `.github/workflows/store.yml` | Avvio manuale: esegue `convalida`; senza segreti fallisce con un messaggio |

## Segreti da inserire

In https://github.com/diegociarafoni/rokko/settings/secrets/actions (**New repository secret**):

| Nome del segreto | A che cosa serve | Quando |
|---|---|---|
| `PLAY_SERVICE_ACCOUNT_JSON` | Contenuto del file JSON dell'account di servizio di Google Cloud con accesso a Google Play Console (Impostazioni → Accesso API) | Per `convalida` e per `interna` |
| `ANDROID_SIGNING_SEED` oppure `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | Chiave di firma: sono gli stessi segreti già usati per l'APK | Per costruire il bundle da caricare |

Su Google Play serve inoltre un account sviluppatore e l'app creata in Play Console; la prima versione va caricata a mano. Se si attiva «Play App Signing», la chiave caricata resta quella del progetto e Google firma per la distribuzione.

L'App Store di iOS non è ancora configurato: quando servirà si aggiungeranno una cartella Fastlane per iOS e i segreti per certificati e chiave API di App Store Connect, che saranno elencati qui.

## Uso

Dopo aver inserito `PLAY_SERVICE_ACCOUNT_JSON`: Actions → Store → Run workflow. Se la chiave è valida il passo «Convalida» riesce. Il caricamento vero e proprio (`bundle exec fastlane android interna`, con `AAB_PATH` che punta al bundle firmato) non è collegato a nessun workflow: si aggiunge insieme alla build del bundle quando si decide di pubblicare.
