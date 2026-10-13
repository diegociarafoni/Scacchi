# Localizzazione

Requisito RP-05: italiano come lingua predefinita, con la struttura pronta per altre lingue.

## Stato

- L'app usa `flutter_localizations` e il generatore `gen-l10n` di Flutter.
- La lingua è fissata all'italiano (`locale: Locale('it')` in `lib/main.dart`), quindi anche i testi di Material (pulsante Indietro, selettori, campi di testo) sono in italiano su qualunque dispositivo. `l10n.yaml` indica l'italiano come lingua preferita, così resterà la lingua di ripiego anche quando il `locale` fisso verrà tolto.
- Su iOS e macOS la regione di sviluppo è l'italiano; le finestre native del sistema (condivisione, permessi) seguono la lingua del dispositivo se è italiano o inglese, altrimenti usano l'italiano.
- Il nome sotto l'icona non viene da `appTitle`: è `android:label` in `android/app/src/main/AndroidManifest.xml` e `CFBundleDisplayName` in `ios/Runner/Info.plist`.
- Sono dichiarate italiano e inglese (`supportedLocales`, e `CFBundleLocalizations` su iOS). Sono tradotti il nome dell'app, i testi del profilo bambino (prefissi `kid`, `kidGame`, `kidBot`), quelli dello scambio QR (prefisso `qr`), quelli dei badge (prefissi `badge` e `badges`), quelli dell'esportazione come immagine (prefisso `shareImage`), quelli della scacchiera fisica (prefisso `physical`), il profilo con traguardi, sfide, serie e promemoria (prefisso `progress`), la revisione della partita e i commenti dell'allenatore (prefisso `review`), i suggerimenti (`coachHint`), l'analisi (`analysis`), l'archivio (`archive`), la scheda settimanale (`portrait`) e le schermate elencate in [Schermate migrate](#schermate-migrate); gli altri testi sono ancora scritti in italiano nel codice.

## Lingue di destinazione

L'italiano è la lingua base e il modello degli `.arb`. Inglese, spagnolo e francese vanno completati: ogni testo dell'app, compresi lezioni, commenti dei grandi maestri, frasi dei bot, spiegazioni dell'allenatore e nomi delle aperture, deve avere la sua traduzione. La documentazione in `docs/` resta in italiano. La notazione dei pezzi segue la lingua dell'app, con inglese e figurativa a scelta. Per un dispositivo in un'altra lingua l'app userà l'italiano (obiettivo: oggi la lingua è ancora fissata a italiano in `lib/main.dart`).

I termini scacchistici e le regole di stile di ogni lingua sono in [glossario-scacchistico.md](glossario-scacchistico.md). Chi traduce o rilegge parte da lì.

Stato attuale: sono dichiarati soltanto italiano e inglese (vedi sopra); spagnolo e francese si aggiungono per funzione. Durante la migrazione italiano e inglese restano obbligatori in ogni PR.

## File

| File | Contenuto |
|---|---|
| `l10n.yaml` | Configurazione del generatore |
| `lib/l10n/it/<funzione>.arb` | Testi italiani di una funzione, modello di riferimento con le descrizioni |
| `lib/l10n/en/<funzione>.arb` | Traduzione inglese, con gli stessi nomi di file e le stesse chiavi |
| `tool/l10n.dart` | Unisce i file per funzione e lancia `flutter gen-l10n` |
| `lib/l10n/app_<lingua>.arb`, `lib/l10n/app_localizations*.dart` | Prodotti da `tool/l10n.dart`, non sono nel repository (`.gitignore`) |

I testi sono in un file per funzione (`kids.arb`, `story.arb`, `stats.arb`, `exchange.arb`, `game.arb`, `puzzles.arb`, `openings.arb`, `coach.arb`…), con il nome della cartella di `lib/` a cui appartengono. Due PR che aggiungono testi a funzioni diverse toccano file diversi e non vanno in conflitto; per questo i file unici e il codice generato non sono versionati.

Dopo un clone, e dopo ogni modifica ai `.arb` o un cambio di ramo, eseguire `dart tool/l10n.dart`. Con una copia nuova `flutter pub get` fallisce finché i file unici non esistono: il comando va dato prima (in CI `dart tool/l10n.dart --solo-unione`, che non lancia `gen-l10n`). `tool/verifica.sh` e l'hook di pre-commit lo eseguono già.

## Testi fissi nel codice

`dart tool/stringhe_fisse.dart` cerca in `lib/` le frasi italiane scritte tra apici invece che nei `.arb` (almeno due parole, con parole italiane comuni o lettere accentate; commenti, `import` e identificativi sono ignorati). I conteggi per cartella stanno in `tool/stringhe_fisse_base.json` e **non possono salire**: la CI e `tool/verifica.sh` falliscono se una cartella ha più testi fissi della base, con l'indicazione di dove spostarli. Quando una cartella viene migrata la base si abbassa con `dart tool/stringhe_fisse.dart --aggiorna`. `--elenco` stampa ogni testo con file e riga. Un nome proprio o un dato dell'archivio che il controllo scambia per testo si esclude con il commento `// l10n-ok` sulla riga. Il controllo è euristico: trova i testi italiani, non quelli già in un'altra lingua.

## Aggiungere un testo

1. Aggiungere la chiave nel file della funzione in `lib/l10n/it/` (uno nuovo, con lo stesso nome in `lib/l10n/en/`, se la funzione è nuova), con una voce `@chiave` che ne descrive il contesto quando il testo da solo non basta e che dichiara i segnaposto. Le chiavi sono in camelCase con il prefisso della schermata (`backup…`, `minigames…`, `stats…`).
2. Aggiungere la stessa chiave nello stesso file di ogni altra lingua, con gli stessi segnaposto. Una chiave non può comparire in due file. Non si scrive `@@locale`: lo aggiunge `tool/l10n.dart`.
3. Per i conteggi usare i plurali ICU (`{count, plural, one{{count} partita} other{{count} partite}}`) invece di comporre la frase nel codice.
4. Eseguire `dart tool/l10n.dart`, che unisce i file, controlla che le lingue coincidano e rigenera il codice; i file prodotti non si committano.
5. Nel codice usare `AppLocalizations.of(context).chiave`.

`test/tool/l10n_merge_test.dart` verifica l'unione (nessuna chiave duplicata, stessi file e stesse chiavi per lingua). `test/l10n_test.dart` controlla che italiano e inglese abbiano le stesse chiavi e gli stessi segnaposto e che nessuna traduzione sia vuota, e monta alcune schermate migrate in inglese.

## Aggiungere una lingua

Creare `lib/l10n/<codice>/` con tutti i file e le chiavi delle altre lingue e rigenerare con `dart tool/l10n.dart`. Per renderla selezionabile va tolto il `locale` fisso in `lib/main.dart`, lasciando che Flutter scelga la lingua del dispositivo, solo dopo che tutti i testi dell'interfaccia sono stati spostati nei file `.arb`.

## Schermate migrate

| Schermata | File | Testi rimasti nel codice |
|---|---|---|
| Impostazioni | `lib/settings/settings_page.dart`, `lib/settings/section_pages.dart`, `lib/settings/settings_widgets.dart`, `lib/settings/settings_labels.dart`, `lib/settings/board_preview.dart` (`settings.arb`) | Nessuno; i nomi dei set di pezzi sono nomi propri, e «Livello N» / «Traguardo …» dei requisiti di sblocco arrivano da `Requirement.label` (`lib/progress/rewards.dart`) |
| Backup e ripristino | `lib/backup/backup_page.dart`, `lib/backup/backup.dart` | Nessuno; gli errori di `Backup.decode` sono codici (`BackupProblem`) tradotti dalla pagina |
| Elenco dei minigiochi | `lib/minigames/minigames_page.dart` | Nessuno; titoli e descrizioni dei minigiochi sono nei file `.arb` |
| Coordinate a tempo, Cattura tutto, Alla cieca, Conta del materiale | `lib/minigames/*_page.dart` | Domande e risposte dei quiz (`quiz.dart`, `blind.dart`, `material_quiz.dart`) e istruzioni delle scacchiere di Cattura tutto (`capture_all.dart`) |
| Editor di posizione (solo titolo e aiuto sul FEN, `editorFen…`) | `lib/editor/position_editor_page.dart` | Pulsanti, avvisi e dialoghi dell'editor |
| Le tue aperture | `lib/openings/personal_explorer_page.dart`, voce nella scheda Aperture (`personal…`) | Nessuno; i nomi delle aperture arrivano dal libro e sono tradotti nel codice |
| Scacchiera fisica (partita, foto e allineamento, voce in «Tu», prefisso `physical`) | `lib/physical/physical_game_page.dart`, `lib/physical/board_align_page.dart` | Nessuno; il nome del file PGN e l'intestazione `Site` restano in italiano |
| Scheda Tu (intestazione del gruppo, voci, «Continua da dove eri», prefisso `you`) | `lib/home/you_page.dart` | Nessuno; titoli e sottotitoli di Storia, Multigiocatore e Scacchiera fisica restano nei loro file `.arb` |
| Profilo, traguardi, sfide, serie, record, promemoria | `lib/progress/profile_page.dart`, `lib/progress/achievements_l10n.dart`, `lib/progress/streak_info.dart`, `lib/reminders/reminder.dart` (`progress.arb`) | Nessuno; `Avatar.label` e `AvatarFrame.label` (nomi dei personaggi e delle cornici) e `Minigame.title` restano nei loro enum |
| Revisione della partita, barra di valutazione, commenti dell'allenatore | `lib/review/review_page.dart`, `lib/review/review_l10n.dart`, `lib/review/coach.dart`, `lib/review/eval_bar.dart`, `lib/review/score_format.dart` (`review.arb`) | Nessuno; `CoachComment.text(l)` compone la frase quando serve, `MoveClass` e `GamePhase` non hanno più etichette |
| Suggerimenti dell'allenatore | `lib/coach/hint_text.dart` (`coach.arb`, prefisso `coachHint`) | Nessuno |
| Analisi | `lib/analysis/analysis_page.dart` (`analysis.arb`) | Nessuno |
| Archivio delle partite | `lib/archive/archive_page.dart` (`archive.arb`) | Nessuno; il tipo di partita (`SavedGame.mode`) resta un identificativo, mostrato tradotto |
| Scheda «La tua settimana» | `lib/stats/portrait_page.dart` (`stats.arb`, prefisso `portrait`) | Nessuno; il nome del file immagine resta in italiano |
| Statistiche | `lib/stats/stats_page.dart` | Bilancio sintetico `+V =P -S` (`Score.toString` in `stats.dart`), nomi delle cadenze e delle aperture che arrivano dall'archivio |

## Testi da spostare

Tutte le altre schermate. In particolare `Minigame.title` in `lib/minigames/minigame.dart` resta in italiano perché è usato anche dal profilo (`lib/progress/profile_page.dart`): la pagina dei minigiochi usa le proprie chiavi.

Nei test e2e non si usa `tester.pageBack()`, che cerca il tooltip inglese "Back": si tocca il tooltip restituito da `MaterialLocalizations.of(context).backButtonTooltip`.

I test dei widget che montano una singola schermata devono usare `localizedApp` di `test/localized_app.dart` (cioè `AppLocalizations.localizationsDelegates` e `locale: Locale('it')`), come l'app reale, prima che quella schermata passi ai file `.arb`.

La migrazione dei testi esistenti verso i file `.arb` si fa una schermata alla volta, per non entrare in conflitto con il lavoro in corso sulle singole funzioni. Restano esclusi i nomi delle aperture e i temi dei puzzle: arrivano in inglese dai dataset di Lichess e sono tradotti in italiano nel codice (`lib/openings/opening_names_it.dart`, `lib/puzzles/themes.dart`).
