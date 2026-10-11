# Convenzioni Git e flusso di lavoro

## Regole

1. **Mai direttamente su `main`**: ogni modifica passa da un ramo e da una pull request.
2. **Un ramo per ogni funzione o correzione**, con nome `tipo/descrizione-in-minuscolo`.
3. **Commit secondo la convenzione Angular**.
4. **Squash merge**: la PR diventa un solo commit su `main`, con il titolo della PR come messaggio.
5. **Revisione `/code-review` prima del merge**, oltre alla CI verde.

## Nomi dei rami

```
feat/orologio
fix/arrocco-lungo
docs/guida-sviluppo
```

Tipi ammessi: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `revert`, gli stessi dei commit. Solo minuscole, cifre, `.`, `_`, `-` e `/` tra le parti.

Sono accettati anche i rami creati dagli strumenti automatici: `dependabot/…`, `release-please--…` e `claude/…` (sessioni di Claude Code).

## Messaggi di commit (Angular)

```
tipo(ambito): descrizione al presente, minuscola, senza punto finale

Corpo facoltativo, separato da una riga vuota: il perché della modifica.

BREAKING CHANGE: cosa cambia per chi usa l'app o il codice.
```

| Tipo | Uso | Nel changelog |
|---|---|---|
| `feat` | nuova funzione | Novità |
| `fix` | correzione di un difetto | Correzioni |
| `perf` | miglioramento delle prestazioni | Prestazioni |
| `revert` | annullamento di un commit precedente | Modifiche annullate |
| `docs` | solo documentazione | Documentazione |
| `refactor` | riorganizzazione senza cambi di comportamento | no |
| `test` | test aggiunti o corretti | no |
| `build` | build, dipendenze, strumenti | no |
| `ci` | integrazione continua | no |
| `style` | formattazione, senza cambi di codice | no |

L'ambito è facoltativo, in minuscolo (`board`, `game`, `l10n`, `deps`). Un `!` dopo tipo o ambito (`feat!:`) segnala una modifica incompatibile e fa salire la versione principale.

L'unico `chore` ammesso nei commit è quello generato da release-please (`chore(main): release x.y.z`).

Nei commit del ramo sono ammessi anche i messaggi generati da git (`Merge branch …`, `Revert "…"`) e i `fixup!`/`squash!` di un messaggio valido, che spariscono con lo squash merge. Il titolo della PR, che diventa il commit su `main`, deve invece seguire sempre la convenzione.

Il controllo è in `tool/check_commit_msg.dart` e gira in locale (hook `commit-msg`) e in CI su ogni commit della PR e sul suo titolo.

## Hook locali (lefthook)

[lefthook](https://lefthook.dev) esegue i controlli veloci prima del commit e i test prima del push; tutto il resto è in CI.

| Hook | Controlli |
|---|---|
| `pre-commit` | formattazione dei file in commit, `flutter analyze`, Gitleaks sui file in commit |
| `commit-msg` | messaggio secondo la convenzione Angular |
| `pre-push` | nome dei rami di destinazione, che blocca anche `git push origin main` da qualsiasi ramo; test senza golden (i golden dipendono dal sistema operativo e girano in CI su Linux) |

Installazione, una volta per clone:

```sh
brew install lefthook gitleaks        # macOS
# oppure: npm install -g lefthook, go install github.com/evilmartians/lefthook/v2@latest
# Gitleaks su Linux e Windows: https://github.com/gitleaks/gitleaks/releases
lefthook install
```

Per un'emergenza `git commit --no-verify` salta gli hook, ma la CI esegue comunque gli stessi controlli.

## Processo di merge

1. Aprire la PR dal proprio ramo verso `main`, con titolo secondo la convenzione Angular (diventerà il commit su `main`). Il modello della PR contiene la lista di verifica.
2. Attendere che tutti i controlli della PR siano verdi.
3. Eseguire la skill `/code-review` di Claude Code sulla PR e risolvere i risultati.
4. Unire con **Squash and merge**.

## Protezione di `main` (impostazione su GitHub)

Da fare una volta, in **Settings** del repository:

1. **General → Pull Requests**: lasciare attivo solo **Allow squash merging**, con messaggio predefinito **Pull request title**; disattivare **Allow merge commits** e **Allow rebase merging**; attivare **Automatically delete head branches**.
2. **Rules → Rulesets → New branch ruleset**: nome `main`, destinazione **Default branch**, stato **Active**, con queste regole:
   - **Restrict deletions** e **Block force pushes**;
   - **Require a pull request before merging**, metodo di merge consentito **Squash**, con **Require conversation resolution before merging**;
   - **Require status checks to pass**, con **Require branches to be up to date** e i controlli `test`, `e2e`, `android` e `Ramo, titolo della PR e commit` (aggiungere quelli nuovi quando entrano in CI).

Su un account GitHub Free le regole dei rami sono applicate solo ai repository pubblici: per un repository privato serve GitHub Pro. Fino ad allora l'hook `pre-push` e la CI restano l'unica protezione.

Con un solo sviluppatore non conviene richiedere approvazioni obbligatorie: GitHub non permette di approvare le proprie PR. La revisione è coperta da `/code-review`.
