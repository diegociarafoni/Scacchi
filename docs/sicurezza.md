# Sicurezza

## Scanner

Il workflow `Sicurezza` (`.github/workflows/security.yml`) gira su ogni push su `main` che non tocca solo la documentazione, ogni lunedì (per scoprire vulnerabilità nuove anche senza modifiche al codice), su avvio manuale e sulle PR che cambiano dipendenze (`pubspec.*` e i `Gemfile*` di Fastlane), `.github/`, configurazione Android, `tool/policy.json` o `.gitleaks.toml`: le altre PR non possono introdurre vulnerabilità nelle dipendenze, e così risparmiano minuti di Actions. Gitleaks gira comunque su ogni PR, sui soli commit della PR, nel workflow `Convenzioni`.

Trivy, Gitleaks e OSV-Scanner si scaricano dai rilasci ufficiali con checksum SHA-256 fissato in `.github/actions/install-scanners/action.yml`, invece di usare azioni di terze parti: una sola fonte da verificare per ogni aggiornamento. Tutte le azioni GitHub sono fissate per SHA del commit e aggiornate da Dependabot.

| Scanner | Cosa cerca | Blocca la CI su |
|---|---|---|
| Trivy | vulnerabilità nelle dipendenze, segreti, configurazioni errate | gravità alta o critica |
| OSV-Scanner | vulnerabilità nel database OSV, più completo di Trivy per i pacchetti pub | qualsiasi vulnerabilità nota |
| Gitleaks | chiavi e password nei file e in tutta la cronologia; anche prima di ogni commit (vedi [convenzioni-git.md](convenzioni-git.md)) | qualsiasi segreto |
| zizmor | iniezioni, permessi eccessivi, credenziali persistenti nei workflow | non blocca: con `--format sarif` esce sempre con 0 e i problemi di gravità media o superiore restano nel report |

CodeQL non supporta Dart, quindi non è usato.

Le eccezioni di Gitleaks stanno in `.gitleaks.toml`, ognuna con il motivo. Oggi c'è solo `assets/puzzles/puzzles.csv`: alcuni identificativi dei puzzle (per esempio `MKEY8`) somigliano a chiavi API. Ogni nuova eccezione va verificata a mano e limitata al file che la richiede.

I report SARIF di ogni scanner sono nell'artefatto `security-reports` del workflow e vengono caricati nella scheda **Security → Code scanning** di GitHub. Il repository è pubblico, quindi il code scanning è disponibile senza costi. Il caricamento resta con `continue-on-error`: se fallisce (per esempio su un fork senza il permesso `security-events`) non blocca il workflow e i report restano consultabili negli artefatti.

## Scorecard e provenienza dell'APK

**OpenSSF Scorecard.** Il workflow `Scorecard` (`.github/workflows/scorecard.yml`, solo dal ramo `main`) valuta ogni lunedì, e a ogni modifica delle regole di protezione di `main`, le pratiche del repository: azioni fissate per SHA, permessi minimi dei workflow, protezione dei rami, dipendenze aggiornate, analisi statica, politica di sicurezza. Il punteggio è pubblico su https://scorecard.dev/viewer/?uri=github.com/diegociarafoni/rokko, il report SARIF è nella scheda **Security → Code scanning** e nell'artefatto `scorecard`. Non blocca nessuna PR: serve a vedere dove manca qualcosa. Non duplica `Sicurezza`, che cerca vulnerabilità e segreti, mentre Scorecard giudica il processo.

**Provenienza.** Ogni APK delle versioni numerate pubblicate da `Rilascio APK` ha un'attestazione di provenienza (SLSA) firmata dal workflow, senza chiavi da custodire. L'attestazione è in un job a parte, l'unico con i permessi per firmarla, così nessun passo della build può usarli. Il nightly e gli APK delle esecuzioni manuali senza versione non sono attestati: il primo è sostituito a ogni merge, i secondi non sono pubblicati. Chi scarica una versione numerata può verificare che sia stata costruita da questo repository e da questo workflow:

```
gh attestation verify rokko.apk --repo diegociarafoni/rokko
```

L'attestazione si aggiunge al file `rokko.apk.sha256` già presente nella Release, che controlla solo l'integrità del download.

## OWASP MASVS

Il riferimento è [OWASP MASVS v2](https://mas.owasp.org/MASVS/), con i casi di test della [MASTG](https://mas.owasp.org/MASTG/). L'app funziona offline, non ha account e non raccoglie dati: la superficie di attacco è piccola e i controlli servono soprattutto a mantenerla tale mentre l'app cresce. `test/security/masvs_test.dart` verifica i sorgenti a ogni `flutter test`; i controlli sull'APK compilato sono in `tool/check_apk.dart`.

| Area | Cosa si controlla | Strumento | Stato |
|---|---|---|---|
| MASVS-STORAGE | Nessun nuovo `print`, `debugPrint` o `dart:developer` fuori da `if (kDebugMode)`: in rilascio finirebbero nel logcat. I 25 esistenti riportano solo errori di lettura e scrittura e sono una base in `tool/policy.json` (`logging.unguardedBaseline`) che può solo scendere | test sorgenti | Attivo |
| MASVS-NETWORK | Nessun traffico in chiaro su Android, App Transport Security non disattivata su iOS | test sorgenti | Attivo |
| MASVS-PLATFORM | Solo `MainActivity` esportata, nessun deep link né schema URL, nessuna WebView tra le dipendenze vietate | test sorgenti | Attivo |
| MASVS-CODE | Il manifest non forza `debuggable`; il rilascio usa la chiave dello store quando `ANDROID_KEYSTORE_PATH` c'è | test sorgenti | Attivo |
| MASVS-CODE | Dipendenze senza vulnerabilità note | Trivy, OSV-Scanner | Attivo |
| MASVS-PRIVACY | Nessun SDK di analisi, pubblicità o tracciamento (`privacy.forbiddenPackages`); un pacchetto vietato è ammesso solo come dipendenza indiretta, con il motivo in `privacy.transitiveAllowed` | test sorgenti | Attivo |
| MASVS-PRIVACY | Solo i permessi Android elencati in `privacy.androidPermissions` con il motivo (oggi `RECEIVE_BOOT_COMPLETED`, `CAMERA`, `INTERNET` per la partita con un amico in rete locale e a distanza tramite relay Nostr, e i permessi Bluetooth per quella vicini senza Wi-Fi, chiesti solo scegliendo il Bluetooth); iOS chiede solo Bluetooth, fotocamera, libreria e rete locale, con la spiegazione, e annuncia solo il servizio mDNS della partita a due | test sorgenti | Attivo |
| MASVS-AUTH | Non applicabile: niente account né login | | N/A |
| MASVS-RESILIENCE | Anti-manomissione e rilevamento di root non previsti: l'app è open source e senza dati da proteggere | | Escluso per scelta |
| MASVS-CRYPTO | La crittografia del multigiocatore ([multigiocatore.md](multigiocatore.md)) è in uso sui canali Wi-Fi, Bluetooth e relay; la dichiarazione `ITSAppUsesNonExemptEncryption` per l'App Store non è ancora in `ios/Runner/Info.plist` e va decisa prima della prima pubblicazione su iOS | | Da fare |

`tool/check_apk.dart` legge con `aapt2` il manifest **finale** dell'APK, dopo l'unione con quelli delle librerie, dove compaiono permessi che nei sorgenti non ci sono. Verifica che l'APK non sia debuggable, che i permessi siano solo quelli di `privacy.androidPermissions` e `privacy.mergedPermissions` (aggiunti dalle librerie, ognuno con il motivo) e che l'unico componente esportato senza permesso sia `MainActivity`. Gira sull'APK di debug nel job `android` della CI (con `--debug`, che ammette INTERNET e salta il controllo sul debug) e sull'APK di rilascio nel workflow `Rilascio APK`, prima della pubblicazione: un APK non conforme non esce.

### MobSF sull'APK di rilascio

Il workflow `MobSF` (`.github/workflows/mobsf.yml`) esegue l'analisi statica di [MobSF](https://github.com/MobSF/Mobile-Security-Framework-MobSF) (OWASP MASVS) sull'APK del nightly, quindi sull'APK firmato che gli utenti installano. Parte ogni mercoledì su `main`, a richiesta (Actions → MobSF → Run workflow, con il tag di una release numerata oppure vuoto per il nightly) e sulle PR che toccano la scansione; non gira sulle altre PR perché è pesante. Analizza un APK già pubblicato: non ne costruisce uno. MobSF è un container fissato per digest (v4.5.3), avviato sul runner con una chiave API casuale: nessun APK né dato lascia il runner. `tool/check_mobsf.dart` applica al rapporto JSON la sezione `mobsf` di `tool/policy.json`:

- `minSecurityScore`: punteggio di sicurezza minimo (0-100);
- `acceptedHigh`: gli avvisi gravi (`appsec.high`) ammessi, inizio del titolo → motivo. Ogni altro avviso grave fa fallire il workflow. Un avviso accettato che il rapporto non contiene più viene segnalato come da togliere.

Il rapporto completo è allegato al workflow (artefatto `mobsf-report`, 30 giorni).

Aggiungere un permesso Android non elencato fa fallire il test finché il permesso non compare in `tool/policy.json` con il motivo: la scelta resta visibile in revisione.

## Catena di fornitura

- **SBOM**: ogni esecuzione del workflow `Sicurezza` produce un SBOM CycloneDX (`sbom.cdx.json`) nell'artefatto `security-reports`.
- **Azioni fissate**: ogni azione è fissata allo SHA del commit e i checkout non lasciano credenziali nella configurazione di git.
- **Dipendenze**: aggiornamenti e licenze in [dipendenze-e-licenze.md](dipendenze-e-licenze.md).

## Segnalare una vulnerabilità

Aprire una [segnalazione privata](https://docs.github.com/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability) dalla scheda Security del repository, non una issue pubblica.
