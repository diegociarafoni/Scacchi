# Rilascio Android (APK)

Il workflow `.github/workflows/apk-release.yml` compila un APK release universale (tutte le architetture in un unico file) e lo pubblica come allegato di una GitHub Release, scaricabile direttamente dal telefono.

## Quando parte

| Evento | Risultato |
|---|---|
| Push di un tag `vX.Y.Z` | Build e Release `vX.Y.Z` con `scacchi.apk` e `scacchi.apk.sha256` |
| Avvio manuale (Actions → Rilascio APK → Run workflow) con **version** = `X.Y.Z` | Crea il tag `vX.Y.Z` sul commit del branch scelto e pubblica la Release; se il tag esiste già su un altro commit si ferma |
| Avvio manuale con **version** vuoto | Solo build: l'APK resta come artefatto dell'esecuzione |
| Pull request che tocca `android/` o il workflow | Solo build, per verificare la configurazione |

La versione mostrata dall'app (`versionName`) è quella del tag senza la `v`; il `versionCode` è il numero di commit nella cronologia del tag, quindi cresce a ogni versione successiva su `main`. Il rilascio parte solo se `flutter analyze` e `flutter test` passano, e un tag già esistente deve puntare al commit compilato.

I tag con suffisso (`v1.2.0-beta.1`) diventano pre-release. Gli altri sono la "latest release", per cui questo link porta sempre all'ultima versione stabile:

```
https://github.com/diegociarafoni/Scacchi/releases/latest/download/scacchi.apk
```

## Pubblicare una versione

```bash
git checkout main && git pull
git tag v0.2.0
git push origin v0.2.0
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

1. **Keystore** nei segreti `ANDROID_KEYSTORE_*` (vedi sotto).
2. **Frase segreta** nel segreto `ANDROID_SIGNING_SEED`: è il metodo consigliato.
3. **Nessun segreto**: chiave di debug generata dal runner, diversa a ogni esecuzione; per passare a una nuova versione bisogna prima disinstallare l'app (e le partite salvate vanno perse).

Sulle pull request la build firma con una frase pubblica fissa, così il percorso di firma è verificato senza esporre segreti al codice della PR.

### Metodo consigliato: frase segreta

`tool/derive_keystore.py` ricava dalla frase, in modo deterministico, una chiave RSA a 3072 bit e un certificato sempre identico (scrypt sulla frase, numeri primi da un flusso SHAKE-256, campi del certificato fissi e firma PKCS#1 v1.5). Stessa frase, stesso certificato: non c'è nessun file da conservare o caricare, e la copia di sicurezza è la frase stessa.

1. Generare una frase casuale lunga (almeno 20 caratteri, meglio 40 o più) con un gestore di password e salvarla lì. Chi la conosce può firmare aggiornamenti dell'app: non va condivisa.
2. Aprire https://github.com/diegociarafoni/Scacchi/settings/secrets/actions, toccare **New repository secret**, nome `ANDROID_SIGNING_SEED`, valore la frase, **Add secret**. Funziona anche dal browser del telefono.
3. Pubblicare una nuova versione. Chi aveva installato una versione firmata con la chiave di debug deve disinstallarla una volta; da lì in poi gli aggiornamenti si installano sopra.

L'impronta SHA-256 del certificato compare nel log del passo "Chiave di firma dalla frase segreta". Cambiare la frase, o il sale `SALT` nello script, cambia la chiave e richiede di nuovo una disinstallazione. Per una build locale firmata:

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

Il keystore non va mai aggiunto al repository: `android/.gitignore` esclude `*.jks` e `*.keystore`.

### Build locale firmata con un keystore

`android/app/build.gradle.kts` legge la chiave dalle stesse variabili d'ambiente; senza `ANDROID_KEYSTORE_PATH` firma con la chiave di debug locale.

```bash
export ANDROID_KEYSTORE_PATH=$HOME/scacchi-release.jks
export ANDROID_KEYSTORE_PASSWORD=... ANDROID_KEY_ALIAS=scacchi ANDROID_KEY_PASSWORD=...
flutter build apk --release
```
