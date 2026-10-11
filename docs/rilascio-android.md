# Rilascio Android (APK)

Il workflow `.github/workflows/apk-release.yml` compila un APK release per telefoni a 64 bit (arm64, cioè tutti i telefoni Android degli ultimi anni) e lo pubblica come allegato di una GitHub Release, scaricabile direttamente dal telefono. L'app installata si chiama **Rokko**; il file e l'identificativo del pacchetto (`io.github.diegociarafoni.scacchi`) restano `scacchi`, perché cambiarli impedirebbe l'aggiornamento sopra le versioni già installate.

## Versioni pubblicate

| Versione | Novità principali |
|---|---|
| v0.2.0 | Prima versione con firma stabile: gli aggiornamenti si installano sopra |
| v0.3.0 | Backup e ripristino, scacchiera fisica, La tua settimana |
| v0.4.0 | Profilo bambino, tornei dalla scheda Tu, guardiano nel percorso, XP e archivio a fine partita, puzzle dagli errori, anteprima della scacchiera |

L'elenco completo con le note è nella pagina delle Release; le funzioni già in `main` ma non ancora in un APK sono indicate nel paragrafo sulla frequenza dei rilasci.

## Quando parte

| Evento | Risultato |
|---|---|
| Push di un tag `vX.Y.Z` | Build e Release `vX.Y.Z` con `scacchi.apk` e `scacchi.apk.sha256` |
| Avvio manuale (Actions → Rilascio APK → Run workflow) con **version** = `X.Y.Z` | Crea il tag `vX.Y.Z` sul commit del branch scelto e pubblica la Release; se il tag esiste già su un altro commit si ferma |
| Avvio manuale con **version** vuoto | Solo build: l'APK resta per 7 giorni come artefatto dell'esecuzione |

La versione mostrata dall'app (`versionName`) è quella del tag senza la `v`; il `versionCode` è il numero di commit nella cronologia del tag, quindi cresce a ogni versione successiva su `main`. Il rilascio parte solo se `flutter analyze` e `flutter test` passano, e un tag già esistente deve puntare al commit compilato.

I tag con suffisso (`v1.2.0-beta.1`) diventano pre-release. Gli altri sono la "latest release", per cui questo link porta sempre all'ultima versione stabile:

```
https://github.com/diegociarafoni/Scacchi/releases/latest/download/scacchi.apk
```

## Minuti di GitHub Actions

Il rilascio è pensato per consumare pochi minuti:

- un solo job, perché ogni job viene conteggiato arrotondato al minuto;
- nessuna esecuzione sulle pull request: la loro build Android è già nella CI;
- `flutter analyze`, `flutter test` e i test di `tool/derive_keystore.py` girano solo se la CI non è già passata sullo stesso commit (il caso normale quando si rilascia da `main`);
- cache di Flutter e di Gradle (la build Android di debug della CI usa in più `ccache` per non ricompilare il motore C++ invariato);
- build della sola architettura arm64, che dimezza circa il tempo di compilazione e riduce molto l'APK;
- `timeout-minutes: 30` contro le esecuzioni bloccate.

Per un telefono a 32 bit si può compilare a mano un APK universale togliendo `--target-platform android-arm64` dal workflow.

## Frequenza dei rilasci

Per risparmiare minuti di Actions si pubblica a blocchi, non a ogni funzione:

- **Regola predefinita**: una nuova versione solo quando `main` ha accumulato almeno circa 5 PR di funzionalità dall'ultima, oppure quando il responsabile del progetto la chiede.
- Le correzioni urgenti (un difetto che impedisce di usare l'app) possono uscire prima, come versione di correzione (`0.3.1`).
- Prima di pubblicare si aspetta la CI verde sul commit di `main`: così il rilascio salta analisi e test già passati e costa circa 11 minuti invece di 16.
- Le funzioni uscite tra due rilasci restano in `main`, installabili compilando o dal prossimo APK; `docs/README.md` indica lo stato di ciascuna.

## Pubblicare una versione

```bash
git checkout main && git pull
git tag v0.5.0
git push origin v0.5.0
```

In alternativa, dall'interfaccia di GitHub con l'avvio manuale descritto sopra.

## Installare sul telefono

1. Dal browser del telefono aprire la pagina della Release (o il link qui sopra) e toccare **scacchi.apk**. Se il repository è privato serve essere collegati a GitHub nel browser.
2. Aprire il file scaricato. Android chiede di consentire l'installazione di app da questa origine (il browser o il gestore file): consentirla e tornare indietro.
3. Toccare **Installa**. Google Play Protect può segnalare un'app di sviluppatore sconosciuto: scegliere **Installa comunque**.

Per verificare l'integrità del file: `sha256sum -c scacchi.apk.sha256`.

## Firma

Android installa un aggiornamento solo se è firmato con la stessa chiave della versione presente.

La build sceglie la chiave in quest'ordine:

1. **Keystore** nei segreti `ANDROID_KEYSTORE_*` (vedi sotto). Se c'è anche la frase segreta la build lo segnala con un avviso: togliere poi il keystore cambierebbe la firma.
2. **Frase segreta** nel segreto `ANDROID_SIGNING_SEED`: è il metodo consigliato.
3. **Nessun segreto**: chiave di debug generata dal runner, diversa a ogni esecuzione; per passare a una nuova versione bisogna prima disinstallare l'app (e le partite salvate vanno perse).


### Metodo consigliato: frase segreta

`tool/derive_keystore.py` ricava dalla frase, in modo deterministico, una chiave RSA a 3072 bit e un certificato sempre identico (scrypt sulla frase, numeri primi da un flusso SHAKE-256, campi del certificato fissi e firma PKCS#1 v1.5). Stessa frase, stesso certificato: non c'è nessun file da conservare o caricare, e la copia di sicurezza è la frase stessa.

1. Generare una frase casuale lunga (almeno 32 caratteri, meglio 40 o più) con il generatore di un gestore di password e salvarla lì. Non usare una frase inventata o una citazione: il certificato pubblico di ogni APK permette di provare frasi a tentativi, e chi la indovina può firmare aggiornamenti dell'app. Spazi iniziali e finali sono ignorati.
2. Aprire https://github.com/diegociarafoni/Scacchi/settings/secrets/actions, toccare **New repository secret**, nome `ANDROID_SIGNING_SEED`, valore la frase, **Add secret**. Funziona anche dal browser del telefono.
3. Pubblicare una nuova versione. Chi aveva installato una versione firmata con la chiave di debug deve disinstallarla una volta; da lì in poi gli aggiornamenti si installano sopra.

L'impronta SHA-256 del certificato compare nel log del passo "Build APK release firmato", nella riga `Certificato SHA-256: …` stampata da `tool/derive_keystore.py`. Cambiare la frase, o il sale `SALT` nello script, cambia la chiave e richiede di nuovo una disinstallazione. Per una build locale firmata:

```bash
export ANDROID_SIGNING_SEED='...'
export ANDROID_KEYSTORE_PATH=/tmp/scacchi.p12
export ANDROID_KEYSTORE_PASSWORD="$(python3 tool/derive_keystore.py "$ANDROID_KEYSTORE_PATH")"
export ANDROID_KEY_PASSWORD="$ANDROID_KEYSTORE_PASSWORD" ANDROID_KEY_ALIAS=scacchi
flutter build apk --release
```

Serve il pacchetto Python `cryptography`. Su Google Play questa chiave si usa come chiave di caricamento: la chiave di firma finale la gestisce Play App Signing.

### Alternativa: keystore tradizionale

1. Generare il keystore, una volta sola, e conservarlo con le password in un luogo sicuro (perderlo impedisce di aggiornare l'app):

   ```bash
   keytool -genkeypair -v -keystore scacchi-release.jks -keyalg RSA -keysize 4096 \
     -validity 10000 -alias scacchi
   ```

2. In GitHub, **Settings → Secrets and variables → Actions → New repository secret**, creare:

   | Segreto | Valore |
   |---|---|
   | `ANDROID_KEYSTORE_BASE64` | output di `base64 -w0 scacchi-release.jks` |
   | `ANDROID_KEYSTORE_PASSWORD` | password del keystore |
   | `ANDROID_KEY_ALIAS` | `scacchi` (l'alias scelto) |
   | `ANDROID_KEY_PASSWORD` | password della chiave |

3. Dalla build successiva l'APK è firmato con questa chiave. Chi aveva installato una versione firmata con la chiave di debug deve disinstallarla una volta.

Il keystore non va mai aggiunto al repository: `android/.gitignore` esclude `*.jks` e `*.keystore`.

### Build locale firmata con un keystore

`android/app/build.gradle.kts` legge la chiave dalle stesse variabili d'ambiente; senza `ANDROID_KEYSTORE_PATH` firma con la chiave di debug locale.

```bash
export ANDROID_KEYSTORE_PATH=$HOME/scacchi-release.jks
export ANDROID_KEYSTORE_PASSWORD=... ANDROID_KEY_ALIAS=scacchi ANDROID_KEY_PASSWORD=...
flutter build apk --release
```
