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

- **Senza segreti configurati** la build usa la chiave di debug che Gradle genera sul runner. Ogni esecuzione ne genera una diversa, quindi per passare a una nuova versione bisogna prima disinstallare l'app (le partite salvate vanno perse). Va bene per provare l'app, non per gli utenti.
- **Con una chiave di rilascio** gli aggiornamenti si installano sopra la versione precedente. È la stessa chiave da usare poi come chiave di caricamento su Google Play.

### Configurare una chiave di rilascio

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

### Build locale firmata

`android/app/build.gradle.kts` legge la chiave dalle stesse variabili d'ambiente; senza `ANDROID_KEYSTORE_PATH` firma con la chiave di debug locale.

```bash
export ANDROID_KEYSTORE_PATH=$HOME/scacchi-release.jks
export ANDROID_KEYSTORE_PASSWORD=... ANDROID_KEY_ALIAS=scacchi ANDROID_KEY_PASSWORD=...
flutter build apk --release
```
