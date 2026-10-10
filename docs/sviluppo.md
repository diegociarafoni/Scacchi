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
flutter test                          # test unitari e di widget
flutter test integration_test -d linux  # test e2e (su Linux senza schermo: xvfb-run -a ...)
flutter analyze                       # analisi statica
dart format lib test                  # formattazione
flutter build apk                     # APK Android
flutter build ios                     # app iOS (su Mac)
```

## Test

### Metodo: prima i test

Ogni funzione nasce dai requisiti del progetto, nel documento dei requisiti, con questo ordine:

1. Si scrivono i test che descrivono il comportamento richiesto, citando nel nome l'identificativo del requisito (per esempio `RF-32 patta concordata`).
2. Si eseguono e si verifica che falliscano per la ragione attesa.
3. Si implementa il minimo necessario per farli passare.
4. Si aggiorna la documentazione in `docs/`.

### Livelli

| Livello | Cartella | Cosa verifica | Comando |
|---|---|---|---|
| Unitari | `test/chess_game_test.dart`, `test/material_test.dart`, `test/settings_test.dart` | Regole e fine partita su `ChessGame`; pezzi catturati e vantaggio su `MaterialBalance`; impostazioni e salvataggio; senza interfaccia | `flutter test` |
| Widget | `test/widget_test.dart` | Avvio dell'app e stato iniziale | `flutter test` |
| Gamification | `test/progress/` | Regole di XP, serie e traguardi; salvataggio; schermata Profilo | `flutter test test/progress` |
| Archivio | `test/archive/` | PGN, salvataggio su file, schermata Partite | `flutter test test/archive` |
| End-to-end | `integration_test/app_test.dart` | L'app reale avviata su un dispositivo o desktop, con tocchi e trascinamenti sulla scacchiera | `flutter test integration_test -d <dispositivo>` |

I test e2e simulano uno schermo da telefono in verticale (1170×2532 pixel fisici, rapporto 3) e muovono i pezzi calcolando la posizione delle case sulla scacchiera.

### Copertura attuale dei requisiti

| Requisito | Unitari | E2E |
|---|---|---|
| RF-01 mossa con due tocchi e trascinamento, mosse illegali ignorate | ✓ | ✓ |
| RF-04 promozione | ✓ | |
| RF-06 capovolgimento della scacchiera | | ✓ |
| RF-10 lista delle mosse in SAN | ✓ | ✓ |
| RF-11 pezzi catturati e vantaggio di materiale | ✓ | ✓ |
| RF-02, RF-04, RF-07, RF-12, RP-01, RP-04 impostazioni salvate | ✓ | ✓ |
| RF-25 matto, stallo, materiale insufficiente, ripetizione, 50 mosse, abbandono | ✓ | matto, abbandono |
| RF-31 rotazione automatica a ogni turno | | ✓ |
| RF-32 patta concordata e annullamento | ✓ | ✓ |
| RF-100 salvataggio e partita da riprendere | ✓ | |
| RF-101 storico con ricerca | ✓ | |
| RF-102 import ed export PGN, condivisione, copia | ✓ | |
| Annullamento di abbandono e patta senza perdita di mosse | ✓ | |
| RF-04 chiusura del selettore di promozione con Annulla | | ✓ |
| RG-01 XP e livelli | ✓ | |
| RG-02 obiettivo giornaliero, serie, riposo, protezioni | ✓ | |
| RG-05 33 traguardi e notifica in-app | ✓ | |
| RG-07 sfide giornaliere e settimanali | ✓ | |
| RG-08 record personali | ✓ | |
| RG-12 gamification disattivabile | ✓ | |

## Integrazione continua

Il workflow `.github/workflows/ci.yml` gira su ogni pull request e su ogni push su `main`:

1. **test**: verifica della formattazione, `flutter analyze`, `flutter test`.
2. **e2e**: se i test passano, esegue i test end-to-end sull'app Linux desktop con uno schermo virtuale (`xvfb`).
3. **android**: se i test passano, compila un APK di debug e lo pubblica come artefatto `scacchi-debug-apk`, scaricabile dalla pagina dell'esecuzione.

## Convenzioni

- Nel codice solo commenti funzionali e brevi: cosa fa un elemento, non la sua storia o le motivazioni di progetto.
- La documentazione completa sta in `docs/`, da aggiornare insieme al codice che descrive.
- Testi dell'interfaccia in italiano.
- Logica di gioco separata dall'interfaccia (`ChessGame` non importa Flutter), così da poterla testare in isolamento.
