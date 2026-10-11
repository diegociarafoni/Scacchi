# Localizzazione

Requisito RP-05: italiano come lingua predefinita, con la struttura pronta per altre lingue.

## Stato

- L'app usa `flutter_localizations` e il generatore `gen-l10n` di Flutter.
- La lingua è fissata all'italiano (`locale: Locale('it')` in `lib/main.dart`), quindi anche i testi di Material (pulsante Indietro, selettori, campi di testo) sono in italiano su qualunque dispositivo. `l10n.yaml` indica l'italiano come lingua preferita, così resterà la lingua di ripiego anche quando il `locale` fisso verrà tolto.
- Su iOS e macOS la regione di sviluppo è l'italiano; le finestre native del sistema (condivisione, permessi) seguono la lingua del dispositivo se è italiano o inglese, altrimenti usano l'italiano.
- Il nome sotto l'icona non viene da `appTitle`: è `android:label` in `android/app/src/main/AndroidManifest.xml` e `CFBundleDisplayName` in `ios/Runner/Info.plist`.
- Sono dichiarate italiano e inglese (`supportedLocales`, e `CFBundleLocalizations` su iOS). Sono tradotti il nome dell'app, i testi del profilo bambino (prefissi `kid`, `kidGame`, `kidBot`), quelli dello scambio QR (prefisso `qr`) e le schermate elencate in [Schermate migrate](#schermate-migrate); gli altri testi sono ancora scritti in italiano nel codice.

## File

| File | Contenuto |
|---|---|
| `l10n.yaml` | Configurazione del generatore |
| `lib/l10n/app_it.arb` | Testi italiani, modello di riferimento con le descrizioni |
| `lib/l10n/app_en.arb` | Traduzione inglese |
| `lib/l10n/app_localizations*.dart` | Codice generato, da non modificare a mano |

## Aggiungere un testo

1. Aggiungere la chiave in `app_it.arb`, con una voce `@chiave` che ne descrive il contesto quando il testo da solo non basta e che dichiara i segnaposto. Le chiavi sono in camelCase con il prefisso della schermata (`backup…`, `minigames…`, `stats…`).
2. Aggiungere la stessa chiave in ogni altro file `.arb`, con gli stessi segnaposto.
3. Per i conteggi usare i plurali ICU (`{count, plural, one{{count} partita} other{{count} partite}}`) invece di comporre la frase nel codice.
4. Eseguire `flutter gen-l10n` (lo fa anche `flutter pub get`) e salvare i file generati; la CI fallisce se non corrispondono ai file `.arb`.
5. Nel codice usare `AppLocalizations.of(context).chiave`.

`test/l10n_test.dart` controlla che italiano e inglese abbiano le stesse chiavi e gli stessi segnaposto e che nessuna traduzione sia vuota, e monta alcune schermate migrate in inglese.

## Aggiungere una lingua

Creare `lib/l10n/app_<codice>.arb` con tutte le chiavi e rigenerare. Per renderla selezionabile va tolto il `locale` fisso in `lib/main.dart`, lasciando che Flutter scelga la lingua del dispositivo, solo dopo che tutti i testi dell'interfaccia sono stati spostati nei file `.arb`.

## Schermate migrate

| Schermata | File | Testi rimasti nel codice |
|---|---|---|
| Backup e ripristino | `lib/backup/backup_page.dart`, `lib/backup/backup.dart` | Nessuno; gli errori di `Backup.decode` sono codici (`BackupProblem`) tradotti dalla pagina |
| Elenco dei minigiochi | `lib/minigames/minigames_page.dart` | Nessuno; titoli e descrizioni dei minigiochi sono nei file `.arb` |
| Coordinate a tempo, Cattura tutto, Alla cieca, Conta del materiale | `lib/minigames/*_page.dart` | Domande e risposte dei quiz (`quiz.dart`, `blind.dart`, `material_quiz.dart`) e istruzioni delle scacchiere di Cattura tutto (`capture_all.dart`) |
| Editor di posizione (solo titolo e aiuto sul FEN, `editorFen…`) | `lib/editor/position_editor_page.dart` | Pulsanti, avvisi e dialoghi dell'editor |
| Statistiche | `lib/stats/stats_page.dart` | Bilancio sintetico `+V =P -S` (`Score.toString` in `stats.dart`), nomi delle cadenze e delle aperture che arrivano dall'archivio |

## Testi da spostare

Tutte le altre schermate. In particolare `Minigame.title` in `lib/minigames/minigame.dart` resta in italiano perché è usato anche dal profilo (`lib/progress/profile_page.dart`): la pagina dei minigiochi usa le proprie chiavi.

Nei test e2e non si usa `tester.pageBack()`, che cerca il tooltip inglese "Back": si tocca il tooltip restituito da `MaterialLocalizations.of(context).backButtonTooltip`.

I test dei widget che montano una singola schermata devono usare `localizedApp` di `test/localized_app.dart` (cioè `AppLocalizations.localizationsDelegates` e `locale: Locale('it')`), come l'app reale, prima che quella schermata passi ai file `.arb`.

La migrazione dei testi esistenti verso i file `.arb` si fa una schermata alla volta, per non entrare in conflitto con il lavoro in corso sulle singole funzioni. Restano esclusi i nomi delle aperture e i temi dei puzzle: arrivano in inglese dai dataset di Lichess e sono tradotti in italiano nel codice (`lib/openings/opening_names_it.dart`, `lib/puzzles/themes.dart`).
