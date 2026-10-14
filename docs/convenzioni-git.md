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

Tipi ammessi: quelli dei commit (`feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `revert`) più `hotfix` e `chore`, che valgono solo per i rami: i commit di un ramo `chore/…` usano un tipo Angular, per esempio `build:`. Solo minuscole, cifre, `.`, `_`, `-` e `/` tra le parti.

Sono accettati anche i rami creati dagli strumenti automatici: `dependabot/…` e `release-please--…`. Le sessioni di Claude Code seguono le stesse regole delle persone: niente `claude/…`, anche quando l'ambiente propone quel nome.

Dopo il merge il ramo si elimina, su GitHub (vedi **Automatically delete head branches** più sotto) e in locale.

## Messaggi di commit (Angular)

```
tipo(ambito): descrizione al presente, minuscola, senza punto finale

Corpo facoltativo, separato da una riga vuota: il perché della modifica.

BREAKING CHANGE: cosa cambia per chi usa l'app o il codice.
```

| Tipo | Uso | Nel changelog (`release-please-config.json`) |
|---|---|---|
| `feat` | nuova funzione | Novità |
| `fix` | correzione di un difetto | Correzioni |
| `perf` | miglioramento delle prestazioni | Prestazioni |
| `revert` | annullamento di un commit precedente | Annullamenti |
| `docs` | solo documentazione | no |
| `refactor` | riorganizzazione senza cambi di comportamento | no |
| `test` | test aggiunti o corretti | no |
| `build` | build, dipendenze, strumenti | no |
| `ci` | integrazione continua | no |
| `style` | formattazione, senza cambi di codice | no |

La descrizione inizia con la minuscola, tranne quando comincia con una sigla (`feat(game): XP e salvataggio`, `fix: PGN con commenti`). L'intestazione è lunga al massimo 100 caratteri. L'ambito è facoltativo, in minuscolo (`board`, `game`, `l10n`, `deps`). Un `!` dopo tipo o ambito (`feat!:`) segnala una modifica incompatibile e fa salire la versione principale.

L'unico `chore` ammesso nei commit è quello generato da release-please (`chore(main): release x.y.z`).

Nei commit del ramo sono ammessi anche i messaggi generati da git (`Merge branch …`, `Revert "…"`) e i `fixup!`/`squash!`/`amend!` di un messaggio valido, che spariscono con lo squash merge. Il titolo della PR, che diventa il commit su `main`, deve invece seguire sempre la convenzione.

Il controllo è in `tool/check_commit_msg.dart` e gira in locale (hook `commit-msg`) e in CI su ogni commit della PR e sul suo titolo.

## Hook locali (lefthook)

[lefthook](https://lefthook.dev) esegue i controlli veloci prima del commit e i test prima del push; tutto il resto è in CI.

| Hook | Controlli |
|---|---|
| `pre-commit` | formattazione dei file Dart in commit, `dart tool/l10n.dart` e `flutter analyze --fatal-infos --fatal-warnings`, Gitleaks sui file in commit |
| `commit-msg` | messaggio secondo la convenzione Angular |
| `pre-push` | nome dei rami di destinazione, che blocca anche `git push origin main` da qualsiasi ramo; messaggi di tutti i commit del ramo (gli stessi della CI); documentazione (`tool/check_docs.dart`); commenti (`tool/check_comments.dart`); nessun sottomodulo nell'indice; test senza golden (i golden dipendono dal sistema operativo e girano in CI su Linux) |

Installazione, una volta per clone:

```sh
brew install lefthook gitleaks        # macOS
# oppure: npm install -g lefthook, go install github.com/evilmartians/lefthook/v2@latest
# Gitleaks su Linux e Windows: https://github.com/gitleaks/gitleaks/releases
lefthook install
```

### Sessioni di Claude Code nel cloud

Gli hook git non vengono installati da soli in un container nuovo. L'hook di avvio `.claude/hooks/session-start.sh`, registrato in `.claude/settings.json`, installa Flutter alla versione della CI, lefthook e Gitleaks, prepara le dipendenze ed esegue `lefthook install`, così `pre-commit`, `commit-msg` e `pre-push` sono attivi fin dal primo commit. Gira solo nelle sessioni cloud (`CLAUDE_CODE_REMOTE=true`) ed è idempotente.

### Senza hook: `tool/verifica.sh`

Dove gli hook non sono installati si lancia a mano, prima del push, lo script con gli stessi controlli veloci della CI:

```sh
tool/verifica.sh --titolo "feat(game): titolo della PR" --test
```

Controlla nome del ramo, messaggi dei commit dal punto in cui il ramo si stacca da `main`, titolo della PR (facoltativo), documentazione (`tool/check_docs.dart`: link, percorsi citati, indice e [mappa del codice](mappa-del-codice.md)), commenti (`tool/check_comments.dart`), testi tradotti (`tool/l10n.dart`, `tool/stringhe_fisse.dart`, `tool/l10n_stato.dart`), formattazione e analisi; con `--test` anche i test senza golden, cioè senza l'etichetta `golden` dichiarata in `dart_test.yaml`. Segnala inoltre un sottomodulo nell'indice, di solito una copia di lavoro di Claude Code (`.claude/worktrees/…`) aggiunta per errore, che in CI fa fallire il checkout con «No url found for submodule path»: la cartella è in `.gitignore`, e un errore già commesso si toglie con `git rm --cached <percorso>`.

Per un'emergenza `git commit --no-verify` salta gli hook, ma la CI esegue comunque gli stessi controlli.

## Commenti nel codice

I commenti sono solo funzionali, brevi e sul perché: niente cronaca, riferimenti a PR o thread, descrizioni di ciò che il codice dice già. `tool/check_comments.dart` blocca in automatico i commenti che nominano app concorrenti, rimandano a una PR o a un'issue (`PR #12`, `(#240)`) o contengono `TODO`, `FIXME`, `XXX`, `HACK` senza la forma `TODO: motivo` di almeno una frase; un commento con un indirizzo web è una fonte e non si controlla. Il resto lo giudica la revisione.

## Processo di merge

1. Aprire la PR dal proprio ramo verso `main`, con titolo secondo la convenzione Angular (diventerà il commit su `main`). Il modello della PR contiene la lista di verifica.
2. Attendere che tutti i controlli della PR siano verdi.
3. Eseguire la skill `/code-review` di Claude Code sulla PR e risolvere i risultati.
4. Unire con **Squash and merge**. Con la coda di merge attiva il pulsante diventa **Merge when ready**: la PR entra in coda e GitHub la aggiorna con `main`, rilancia la CI sul risultato e la unisce in squash, una alla volta, senza bisogno di riallineare il ramo a mano.

### Coda di merge

Con più PR aperte in parallelo ogni merge su `main` rende obsolete le altre. La coda (merge queue) le aggiorna e rifà la CI da sola. Perché funzioni:

- i workflow dei controlli obbligatori hanno il trigger `merge_group`: `ci.yml` gira sul gruppo (e2e e build Android solo se il gruppo tocca i file che li riguardano, con la stessa regola delle PR), `conventions.yml` si salta perché titolo e commit sono già stati controllati sulla PR;
- i testi tradotti sono in un file per funzione (vedi [localizzazione.md](localizzazione.md)), così le PR che aggiungono testi non vanno in conflitto tra loro;
- ogni giro in coda esegue tutta la CI sul risultato dell'unione: un test instabile fa perdere il giro, quindi i test instabili si correggono, non si rilanciano.

## Protezione di `main` (impostazione su GitHub)

Da fare una volta, in **Settings** del repository:

1. **General → Pull Requests**: lasciare attivo solo **Allow squash merging**, con messaggio predefinito **Pull request title**; disattivare **Allow merge commits** e **Allow rebase merging**; attivare **Automatically delete head branches**.
2. **Rules → Rulesets → New branch ruleset**: nome `main`, destinazione **Default branch**, stato **Active**, con queste regole:
   - **Restrict deletions** e **Block force pushes**;
   - **Require a pull request before merging**, metodo di merge consentito **Squash**, con **Require conversation resolution before merging**;
   - **Require merge queue**, metodo di merge **Squash**, dimensione del gruppo 1 (una PR alla volta, il titolo della PR resta il commit su `main`) e tempo massimo di attesa dei controlli di 45 minuti;
   - **Require status checks to pass**, con i controlli `test`, `e2e`, `android` e `Ramo, titolo della PR e commit` (con la coda non serve Require branches to be up to date; aggiungere i controlli nuovi quando entrano in CI; vedi anche la nota sulle PR di sola documentazione in [sviluppo.md](sviluppo.md#consumo-di-minuti)).

Su un account GitHub Free le regole dei rami sono applicate solo ai repository pubblici, come questo; se il repository tornasse privato servirebbe GitHub Pro, e fino ad allora l'hook `pre-push` e la CI resterebbero l'unica protezione.

Con un solo sviluppatore non conviene richiedere approvazioni obbligatorie: GitHub non permette di approvare le proprie PR. La revisione è coperta da `/code-review`.
