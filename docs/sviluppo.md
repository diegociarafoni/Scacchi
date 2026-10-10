# Sviluppo

## Requisiti

- [Flutter](https://docs.flutter.dev/get-started/install), canale stable, versione 3.47 o successiva (la CI usa 3.47.7).
- Per Android: Android Studio o Android SDK, Java 17.
- Per iOS e macOS: un Mac con Xcode, oppure un servizio di build in cloud.
- Per Linux desktop: le librerie di sviluppo GTK 3 (`libgtk-3-dev`).

## Comandi

```sh
flutter pub get                       # dipendenze
flutter run                           # avvio sul dispositivo o emulatore collegato
flutter test                          # test
flutter analyze                       # analisi statica
dart format lib test                  # formattazione
flutter build apk                     # APK Android
flutter build ios                     # app iOS (su Mac)
```

## Test

- `test/chess_game_test.dart`: notazione SAN, rifiuto delle mosse illegali, scacco matto, stallo, triplice ripetizione, regola delle 50 mosse, annullamento e abbandono.
- `test/widget_test.dart`: avvio dell'app e stato iniziale.

Ogni nuova regola o condizione di fine partita va accompagnata da un test in `chess_game_test.dart`.

## Integrazione continua

Il workflow `.github/workflows/ci.yml` gira su ogni pull request e su ogni push su `main`:

1. **test**: verifica della formattazione, `flutter analyze`, `flutter test`.
2. **android**: se i test passano, compila un APK di debug e lo pubblica come artefatto `scacchi-debug-apk`, scaricabile dalla pagina dell'esecuzione.

## Convenzioni

- Nel codice solo commenti funzionali e brevi: cosa fa un elemento, non la sua storia o le motivazioni di progetto.
- La documentazione completa sta in `docs/`, da aggiornare insieme al codice che descrive.
- Testi dell'interfaccia in italiano.
- Logica di gioco separata dall'interfaccia (`ChessGame` non importa Flutter), così da poterla testare in isolamento.
