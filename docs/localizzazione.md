# Localizzazione

Requisito RP-05: italiano come lingua predefinita, con la struttura pronta per altre lingue.

## Stato

- L'app usa `flutter_localizations` e il generatore `gen-l10n` di Flutter.
- La lingua è fissata all'italiano (`locale: Locale('it')` in `lib/main.dart`), quindi anche i testi di Material (pulsante Indietro, selettori, campi di testo) sono in italiano su qualunque dispositivo. `l10n.yaml` indica l'italiano come lingua preferita, così resterà la lingua di ripiego anche quando il `locale` fisso verrà tolto.
- Su iOS e macOS la regione di sviluppo è l'italiano; le finestre native del sistema (condivisione, permessi) seguono la lingua del dispositivo se è italiano o inglese, altrimenti usano l'italiano.
- Il nome sotto l'icona non viene da `appTitle`: è `android:label` in `android/app/src/main/AndroidManifest.xml` e `CFBundleDisplayName` in `ios/Runner/Info.plist`.
- Sono dichiarate italiano e inglese (`supportedLocales`, e `CFBundleLocalizations` su iOS), ma per ora è tradotto solo il nome dell'app; gli altri testi sono ancora scritti in italiano nel codice.

## File

| File | Contenuto |
|---|---|
| `l10n.yaml` | Configurazione del generatore |
| `lib/l10n/app_it.arb` | Testi italiani, modello di riferimento con le descrizioni |
| `lib/l10n/app_en.arb` | Traduzione inglese |
| `lib/l10n/app_localizations*.dart` | Codice generato, da non modificare a mano |

## Aggiungere un testo

1. Aggiungere la chiave in `app_it.arb`, con una voce `@chiave` che ne descrive il contesto.
2. Aggiungere la stessa chiave in ogni altro file `.arb`.
3. Eseguire `flutter gen-l10n` (lo fa anche `flutter pub get`) e salvare i file generati; la CI fallisce se non corrispondono ai file `.arb`.
4. Nel codice usare `AppLocalizations.of(context).chiave`.

## Aggiungere una lingua

Creare `lib/l10n/app_<codice>.arb` con tutte le chiavi e rigenerare. Per renderla selezionabile va tolto il `locale` fisso in `lib/main.dart`, lasciando che Flutter scelga la lingua del dispositivo, solo dopo che tutti i testi dell'interfaccia sono stati spostati nei file `.arb`.

## Testi da spostare

Nei test e2e non si usa `tester.pageBack()`, che cerca il tooltip inglese "Back": si tocca il tooltip restituito da `MaterialLocalizations.of(context).backButtonTooltip`.

I test dei widget che montano una singola schermata devono usare `AppLocalizations.localizationsDelegates` e `locale: Locale('it')` nel `MaterialApp`, come l'app reale, prima che quella schermata passi ai file `.arb`.


La migrazione dei testi esistenti verso i file `.arb` si fa una schermata alla volta, per non entrare in conflitto con il lavoro in corso sulle singole funzioni. Restano esclusi i nomi delle aperture e i temi dei puzzle, che provengono dai dataset di Lichess.
