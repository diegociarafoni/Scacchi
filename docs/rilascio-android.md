# Rilascio Android (APK)

Il workflow `.github/workflows/apk-release.yml` compila un APK release per telefoni a 64 bit (arm64, cioè tutti i telefoni Android degli ultimi anni) e lo pubblica come allegato di una GitHub Release, scaricabile direttamente dal telefono. L'app installata si chiama **Rokko**; il file è `rokko.apk`. L'identificativo del pacchetto è `io.github.diegociarafoni.rokko` (prima era `io.github.diegociarafoni.scacchi`): essendo cambiato, il primo APK con il nome nuovo non si installa sopra quello vecchio e va installato come app nuova, portando i dati con un backup; da lì in poi gli aggiornamenti si installano uno sopra l'altro.

## Versioni pubblicate

L'elenco delle versioni con le note è nella pagina delle Release e in `CHANGELOG.md`; lo stato delle funzioni già in `main` è in [README.md](README.md#stato-del-progetto). Le versioni firmate con la chiave stabile del progetto si installano una sopra l'altra (vedi [Firma](#firma)). Dalla 0.12.0 l'identificativo dell'app è cambiato (`io.github.diegociarafoni.rokko`): la prima installazione non sostituisce le versioni precedenti, che restano come app separata e si disinstallano a mano; da lì in poi gli aggiornamenti si installano sopra.

## Quando parte

| Evento | Risultato |
|---|---|
| Push di un tag `vX.Y.Z` | Build e Release `vX.Y.Z` con `rokko.apk` e `rokko.apk.sha256` |
| Avvio manuale (Actions → Rilascio APK → Run workflow) con **version** = `X.Y.Z` | Crea il tag `vX.Y.Z` sul commit del branch scelto e pubblica la Release; se il tag esiste già su un altro commit si ferma |
| CI verde su `main` (evento `workflow_run`) | Pre-release `nightly` con `rokko.apk`, aggiornata a ogni merge su `main` |
| Avvio manuale con **version** vuoto | Solo build: l'APK resta per 7 giorni come artefatto dell'esecuzione |

La versione mostrata dall'app (`versionName`) è quella del tag senza la `v`; il `versionCode` è il numero di commit nella cronologia del tag, quindi cresce a ogni versione successiva su `main`. Se la CI non è già passata sul commit, il rilascio esegue prima `flutter analyze` e `flutter test`; un tag già esistente deve puntare al commit compilato. Prima della pubblicazione l'APK deve superare i controlli MASVS sul manifest (`tool/check_apk.dart`, vedi [sicurezza.md](sicurezza.md)) e il budget di dimensione (`tool/check_size.dart`, vedi [qualita.md](qualita.md)): un APK che non li supera non esce.

I tag con suffisso (`v1.2.0-beta.1`) diventano pre-release. Gli altri sono la "latest release", per cui questo link porta sempre all'ultima versione stabile:

```
https://github.com/diegociarafoni/rokko/releases/latest/download/rokko.apk
```

## Changelog e proposta di versione

Il workflow `.github/workflows/release-please.yml` (release-please) tiene aperta su `main` una PR **«chore(main): release X.Y.Z»**. Contiene l'aggiornamento di `CHANGELOG.md` con le modifiche dall'ultima versione, raggruppate in Novità (`feat`), Correzioni (`fix`), Prestazioni (`perf`) e Annullamenti (`revert`); gli altri tipi di commit non compaiono. La versione proposta segue i commit: prima della 1.0 una novità alza la seconda cifra, una correzione la terza.

**Unire la PR non pubblica nulla.** Release-please aggiorna `CHANGELOG.md` e `.release-please-manifest.json`, crea il tag `vX.Y.Z` e una release **in bozza** con le note del changelog. Il tag è creato con il token del workflow, che non avvia altri workflow, quindi `Rilascio APK` non parte. La versione dell'app resta quella del tag: `pubspec.yaml` non viene toccato.

**La versione esce solo su richiesta.** Quando si decide di pubblicare: Actions → Rilascio APK → Run workflow, scegliendo come ramo il **tag** `vX.Y.Z` (non `main`, che nel frattempo può essere andato avanti) e **version** = `X.Y.Z`. Il workflow costruisce l'APK, lo allega alla bozza e la pubblica, mantenendo le note del changelog. Senza bozza (versioni fatte a mano, come nella tabella sopra) la Release si crea come prima.

Con il solo token del workflow GitHub non avvia la CI sulla PR creata da un workflow, e i controlli obbligatori restano in attesa: si sbloccano da «Update branch», che fa partire i controlli a nome di chi lo preme. Non si usa un token personale per aggirarlo, perché con quello anche la creazione del tag avvierebbe la pubblicazione.

## Nightly a ogni merge

Ogni volta che la CI passa su `main`, il workflow compila l'APK firmato e ricrea la pre-release **nightly** (nome `Rokko nightly <commit>`). Il link non cambia mai e porta sempre all'ultimo `main` verificato:

```
https://github.com/diegociarafoni/rokko/releases/download/nightly/rokko.apk
```

- È firmata con la stessa chiave delle versioni numerate, quindi si installa sopra di esse e viceversa; il `versionCode` cresce con i commit di `main`, perciò Android accetta l'aggiornamento (le versioni numerate vanno pubblicate da `main`).
- Parte solo dopo una CI riuscita su un evento `push` di `main` e non rifà analisi e test.
- Con più merge ravvicinati la build in corso non si annulla (altrimenti non finirebbe mai): per il nightly resta in attesa solo l'ultima esecuzione, che parte al termine della precedente. Un nightly non torna mai indietro: non si pubblica un commit che sta indietro rispetto al nightly attuale o a una release numerata, così il `versionCode` cresce sempre e Android lo installa sopra la versione precedente.
- La release è sempre la stessa: a ogni merge cambiano file, commit e note, non l'indirizzo, e non partono notifiche.
- Non compare in `releases/latest`, che resta l'ultima versione numerata.
- Se la CI di `main` è rossa non esce nessun nightly: l'ultimo resta disponibile.

## Minuti di GitHub Actions

Il rilascio è pensato per consumare pochi minuti:

- la build è un solo job, perché ogni job viene conteggiato arrotondato al minuto; solo le versioni numerate aggiungono il breve job `attestazione` (vedi [sicurezza.md](sicurezza.md#scorecard-e-provenienza-dellapk));
- nessuna esecuzione sulle pull request: la loro build Android è già nella CI;
- `flutter analyze`, `flutter test` e i test di `tool/derive_keystore.py` girano solo se la CI non è già passata sullo stesso commit (il caso normale quando si rilascia da `main`);
- cache di Flutter e di Gradle (`ccache` è usato solo dalla build di debug della CI, non dal rilascio);
- build della sola architettura arm64, che dimezza circa il tempo di compilazione e riduce molto l'APK;
- `timeout-minutes: 30` contro le esecuzioni bloccate.

Per un telefono a 32 bit si può compilare a mano un APK universale togliendo dal workflow `--target-platform android-arm64` e la variabile `ROKKO_NATIVE_ABIS`, che limita ad arm64 le librerie native dei plugin (`android/build.gradle.kts`).

## Frequenza dei rilasci

Le versioni numerate escono a blocchi (il nightly copre l'uso quotidiano):

- **Regola predefinita**: una nuova versione solo quando `main` ha accumulato almeno circa 5 PR di funzionalità dall'ultima, oppure quando il responsabile del progetto la chiede.
- Le correzioni urgenti (un difetto che impedisce di usare l'app) possono uscire prima, come versione di correzione (`0.3.1`).
- Prima di pubblicare si aspetta la CI verde sul commit di `main`: così il rilascio salta analisi e test già passati.
- Le funzioni uscite tra due rilasci restano in `main`, installabili compilando o dal prossimo APK; `docs/README.md` indica lo stato di ciascuna.

## Pubblicare una versione

Dall'interfaccia di GitHub con l'avvio manuale descritto sopra (consigliato, anche per le versioni proposte da release-please), oppure creando il tag da riga di comando:

```bash
git checkout main && git pull
git tag vX.Y.Z   # per esempio v0.9.0
git push origin vX.Y.Z
```

## Installare sul telefono

1. Dal browser del telefono aprire la pagina della Release (o il link qui sopra) e toccare **rokko.apk**.
2. Aprire il file scaricato. Android chiede di consentire l'installazione di app da questa origine (il browser o il gestore file): consentirla e tornare indietro.
3. Toccare **Installa**. Google Play Protect può segnalare un'app di sviluppatore sconosciuto: scegliere **Installa comunque**.

Per verificare l'integrità del file: `sha256sum -c rokko.apk.sha256`.

## Firma

Android installa un aggiornamento solo se è firmato con la stessa chiave della versione presente.

La build sceglie la chiave in quest'ordine:

1. **Keystore** nei segreti `ANDROID_KEYSTORE_*` (vedi sotto). Se c'è anche la frase segreta la build lo segnala con un avviso: togliere poi il keystore cambierebbe la firma.
2. **Frase segreta** nel segreto `ANDROID_SIGNING_SEED`: è il metodo consigliato.
3. **Nessun segreto**: chiave di debug generata dal runner, diversa a ogni esecuzione; per passare a una nuova versione bisogna prima disinstallare l'app (e le partite salvate vanno perse).

### Metodo consigliato: frase segreta

`tool/derive_keystore.py` ricava dalla frase, in modo deterministico, una chiave RSA a 3072 bit e un certificato sempre identico (scrypt sulla frase, numeri primi da un flusso SHAKE-256, campi del certificato fissi e firma PKCS#1 v1.5). Stessa frase, stesso certificato: non c'è nessun file da conservare o caricare, e la copia di sicurezza è la frase stessa.

1. Generare una frase casuale lunga (almeno 32 caratteri, meglio 40 o più) con il generatore di un gestore di password e salvarla lì. Non usare una frase inventata o una citazione: il certificato pubblico di ogni APK permette di provare frasi a tentativi, e chi la indovina può firmare aggiornamenti dell'app. Spazi iniziali e finali sono ignorati.
2. Aprire https://github.com/diegociarafoni/rokko/settings/secrets/actions, toccare **New repository secret**, nome `ANDROID_SIGNING_SEED`, valore la frase, **Add secret**. Funziona anche dal browser del telefono.
3. Pubblicare una nuova versione. Chi aveva installato una versione firmata con la chiave di debug deve disinstallarla una volta; da lì in poi gli aggiornamenti si installano sopra.

L'impronta SHA-256 del certificato compare nel log del passo "Build APK release firmato", nella riga `Certificato SHA-256: …` stampata da `tool/derive_keystore.py`. Cambiare la frase, o il sale `SALT` nello script, cambia la chiave e richiede di nuovo una disinstallazione. Per una build locale firmata:

```bash
export ANDROID_SIGNING_SEED='...'
export ANDROID_KEYSTORE_PATH=/tmp/rokko.p12
export ANDROID_KEYSTORE_PASSWORD="$(python3 tool/derive_keystore.py "$ANDROID_KEYSTORE_PATH")"
export ANDROID_KEY_PASSWORD="$ANDROID_KEYSTORE_PASSWORD" ANDROID_KEY_ALIAS=scacchi
flutter build apk --release
```

Serve il pacchetto Python `cryptography`. Su Google Play questa chiave si usa come chiave di caricamento: la chiave di firma finale la gestisce Play App Signing.

### Alternativa: keystore tradizionale

1. Generare il keystore, una volta sola, e conservarlo con le password in un luogo sicuro (perderlo impedisce di aggiornare l'app):

   ```bash
   keytool -genkeypair -v -keystore rokko-release.jks -keyalg RSA -keysize 4096 \
     -validity 10000 -alias scacchi
   ```

2. In GitHub, **Settings → Secrets and variables → Actions → New repository secret**, creare:

   | Segreto | Valore |
   |---|---|
   | `ANDROID_KEYSTORE_BASE64` | output di `base64 -w0 rokko-release.jks` |
   | `ANDROID_KEYSTORE_PASSWORD` | password del keystore |
   | `ANDROID_KEY_ALIAS` | `scacchi` (l'alias scelto) |
   | `ANDROID_KEY_PASSWORD` | password della chiave |

3. Dalla build successiva l'APK è firmato con questa chiave. Chi aveva installato una versione firmata con la chiave di debug deve disinstallarla una volta.

Il keystore non va mai aggiunto al repository: `android/.gitignore` esclude `*.jks` e `*.keystore`.

### Build locale firmata con un keystore

`android/app/build.gradle.kts` legge la chiave dalle stesse variabili d'ambiente; senza `ANDROID_KEYSTORE_PATH` firma con la chiave di debug locale.

```bash
export ANDROID_KEYSTORE_PATH=$HOME/rokko-release.jks
export ANDROID_KEYSTORE_PASSWORD=... ANDROID_KEY_ALIAS=scacchi ANDROID_KEY_PASSWORD=...
flutter build apk --release
```
