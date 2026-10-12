# Sicurezza

## Scanner

Il workflow `Sicurezza` (`.github/workflows/security.yml`) gira su ogni push su `main` che non tocca solo la documentazione, ogni lunedì (per scoprire vulnerabilità nuove anche senza modifiche al codice), su avvio manuale e sulle PR che cambiano dipendenze (`pubspec.*`, e `Gemfile*` quando ci sarà Fastlane), `.github/`, configurazione Android, `tool/policy.json` o `.gitleaks.toml`: le altre PR non possono introdurre vulnerabilità nelle dipendenze, e così risparmiano minuti di Actions. Gitleaks gira comunque su ogni PR, sui soli commit della PR, nel workflow `Convenzioni`.

Trivy, Gitleaks e OSV-Scanner si scaricano dai rilasci ufficiali con checksum SHA-256 fissato in `.github/actions/install-scanners/action.yml`, invece di usare azioni di terze parti: una sola fonte da verificare per ogni aggiornamento. Tutte le azioni GitHub sono fissate per SHA del commit e aggiornate da Dependabot.

| Scanner | Cosa cerca | Blocca la CI su |
|---|---|---|
| Trivy | vulnerabilità nelle dipendenze, segreti, configurazioni errate | gravità alta o critica |
| OSV-Scanner | vulnerabilità nel database OSV, più completo di Trivy per i pacchetti pub | qualsiasi vulnerabilità nota |
| Gitleaks | chiavi e password nei file e in tutta la cronologia; anche prima di ogni commit (vedi [convenzioni-git.md](convenzioni-git.md)) | qualsiasi segreto |
| zizmor | iniezioni, permessi eccessivi, credenziali persistenti nei workflow | non blocca: con `--format sarif` esce sempre con 0 e i problemi di gravità media o superiore restano nel report |

CodeQL non supporta Dart, quindi non è usato.

Le eccezioni di Gitleaks stanno in `.gitleaks.toml`, ognuna con il motivo. Oggi c'è solo `assets/puzzles/puzzles.csv`: alcuni identificativi dei puzzle Lichess (per esempio `MKEY8`) somigliano a chiavi API. Ogni nuova eccezione va verificata a mano e limitata al file che la richiede.

I report SARIF di ogni scanner sono nell'artefatto `security-reports` del workflow e vengono caricati nella scheda **Security → Code scanning** di GitHub. Il repository è pubblico, quindi il code scanning è disponibile senza costi. Il caricamento resta con `continue-on-error`: se fallisce (per esempio su un fork senza il permesso `security-events`) non blocca il workflow e i report restano consultabili negli artefatti.

## Catena di fornitura

- **SBOM**: ogni esecuzione del workflow `Sicurezza` produce un SBOM CycloneDX (`sbom.cdx.json`) nell'artefatto `security-reports`.
- **Azioni fissate**: ogni azione è fissata allo SHA del commit e i checkout non lasciano credenziali nella configurazione di git.
- **Dipendenze**: aggiornamenti e licenze in [dipendenze-e-licenze.md](dipendenze-e-licenze.md).

## Segnalare una vulnerabilità

Aprire una [segnalazione privata](https://docs.github.com/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability) dalla scheda Security del repository, non una issue pubblica.
