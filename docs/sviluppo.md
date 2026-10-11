# Sviluppo

## Requisiti

- [Flutter](https://docs.flutter.dev/get-started/install), canale stable, versione 3.47 o successiva (la CI usa 3.47.7).
- Per Android: Android Studio o Android SDK, Java 17.
- Per iOS e macOS: un Mac con Xcode, oppure un servizio di build in cloud.
- Per Linux desktop: le librerie di sviluppo GTK 3 e GStreamer (`libgtk-3-dev`, `libgstreamer1.0-dev`, `libgstreamer-plugins-base1.0-dev`) e, per riprodurre i suoni, i plugin `gstreamer1.0-plugins-base` e `gstreamer1.0-plugins-good`: senza questi ultimi l'app si chiude al primo suono.

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

## Suoni

I file in `assets/sounds/` si rigenerano con `python3 tool/generate_sounds.py`.

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
| Unitari | `test/chess_game_test.dart`, `test/material_test.dart`, `test/settings_test.dart`, `test/clock_test.dart`, `test/sound_test.dart`, `test/move_label_test.dart`, `test/move_input_test.dart`, `test/move_speech_test.dart` | Regole e fine partita su `ChessGame`; pezzi catturati e vantaggio su `MaterialBalance`; impostazioni e salvataggio; orologio; scelta dei suoni; numerazione, lettura e annuncio delle mosse; senza interfaccia | `flutter test` |
| Widget | `test/widget_test.dart`, `test/l10n_test.dart` | Avvio dell'app e stato iniziale; lingua italiana predefinita | `flutter test` |
| Gamification | `test/progress/` | Regole di XP, serie e traguardi; salvataggio; schermata Profilo | `flutter test test/progress` |
| Percorso | `test/path/` | Esercizi, contenuti, sblocco, mappa e tappe sulla scacchiera | `flutter test test/path` |
| Statistiche | `test/stats/` | Bilancio, rating locale, schermata | `flutter test test/stats` |
| Minigiochi | `test/minigames/` | Generazione risolvibile, risposte, schermate, registrazione dei punteggi | `flutter test test/minigames` |
| Tornei | `test/tournament/` | Abbinamenti, simulazione, spareggi, salvataggio, schermata | `flutter test test/tournament` |
| Scacchiera per esercizi | `test/training/` | Tema, pezzi e coordinate presi dalle impostazioni, senza capovolgere i pezzi | `flutter test test/training` |
| Archivio | `test/archive/` | PGN, salvataggio su file, schermata Partite | `flutter test test/archive` |
| End-to-end | `integration_test/*_test.dart` | L'app reale avviata su un dispositivo o desktop, con tocchi e trascinamenti sulla scacchiera | `flutter test integration_test -d <dispositivo>` |

I test e2e simulano uno schermo da telefono in verticale (1170×2532 pixel fisici, rapporto 3) e muovono i pezzi calcolando la posizione delle case sulla scacchiera.

### Copertura attuale dei requisiti

| Requisito | Unitari | E2E |
|---|---|---|
| RF-01 mossa con due tocchi e trascinamento, mosse illegali ignorate | ✓ | ✓ |
| RF-04 promozione | ✓ | |
| RF-06 capovolgimento della scacchiera | | ✓ |
| RF-10 lista delle mosse in SAN, navigazione tra le posizioni | ✓ | ✓ |
| RF-11 pezzi catturati e vantaggio di materiale | ✓ | ✓ |
| RF-02, RF-04, RF-07, RF-12, RP-01, RP-04 impostazioni salvate | ✓ | ✓ |
| RP-05 italiano predefinito, struttura per altre lingue | ✓ | ✓ |
| RF-40, RF-41 cadenze, incremento, avvisi, tempo scaduto | ✓ | ✓ |
| RP-03 suoni e vibrazione, RF-31 modalità tavolo | ✓ | ✓ |
| RNF-07 mossa da tastiera, annuncio delle mosse | ✓ | ✓ |
| RF-30 nomi dei giocatori | ✓ | ✓ |
| RF-09 conferma della mossa | ✓ | ✓ |
| RF-25 matto, stallo, materiale insufficiente, ripetizione, 50 mosse, abbandono | ✓ | matto, abbandono |
| RF-31 rotazione automatica a ogni turno | | ✓ |
| RF-32 patta concordata e annullamento | ✓ | ✓ |
| RF-100 salvataggio e partita da riprendere | ✓ | |
| RF-101 storico con ricerca | ✓ | |
| RF-102 import ed export PGN, condivisione, copia | ✓ | |
| Annullamento di abbandono e patta senza perdita di mosse | ✓ | |
| RF-04 chiusura del selettore di promozione con Annulla | | ✓ |
| RF-110 rating locale contro il computer | ✓ | |
| RF-111 statistiche per colore, cadenza, aperture, precisione | ✓ | |
| RG-01 XP e livelli | ✓ | |
| RG-02 obiettivo giornaliero, serie, riposo, protezioni | ✓ | |
| RG-03 percorso a tappe, stelle, sblocco, contenuti verificati | ✓ | |
| RG-05 37 traguardi e notifica in-app | ✓ | |
| RG-07 sfide giornaliere e settimanali | ✓ | |
| RG-08 record personali | ✓ | |
| RG-10 minigiochi | ✓ | |
| RG-09 tornei offline contro bot | ✓ | |
| RG-12 gamification disattivabile | ✓ | |
| RF-80 raccolta di puzzle inclusa e valida | ✓ | ✓ |
| RF-81 risoluzione e punteggio Glicko-2 | ✓ | ✓ |
| RF-83 suggerimento, soluzione, filtro per tema | ✓ | ✓ |
| RF-84 puzzle del giorno | ✓ | ✓ |
| RG-01 XP per i puzzle risolti | ✓ | |
| RF-82 Storm, Rush, sopravvivenza, Serie | ✓ | ✓ |
| RF-85 ripasso dei puzzle sbagliati | ✓ | |
| RG-08 record personali delle serie | ✓ | ✓ |
| RF-90 nome dell'apertura in partita | ✓ | ✓ |
| RF-91 mosse di libro | ✓ | |
| RF-92 explorer ridotto | ✓ | ✓ |

## Integrazione continua

Il workflow `.github/workflows/ci.yml` gira su ogni pull request e su ogni push su `main`:

1. **test**: verifica della formattazione, `flutter analyze`, `flutter test`.
2. **e2e**: se i test passano, esegue i test end-to-end sull'app Linux desktop con uno schermo virtuale (`xvfb`), un file alla volta perché avvii ravvicinati dell'app Linux nello stesso comando falliscono.
3. **android**: se i test passano, compila un APK di debug e lo pubblica come artefatto `scacchi-debug-apk`, scaricabile dalla pagina dell'esecuzione.

Il workflow `.github/workflows/apk-release.yml` produce l'APK release installabile sul telefono e lo pubblica come GitHub Release: vedi [rilascio-android.md](rilascio-android.md).

## Convenzioni

- Nel codice solo commenti funzionali e brevi: cosa fa un elemento, non la sua storia o le motivazioni di progetto.
- La documentazione completa sta in `docs/`, da aggiornare insieme al codice che descrive.
- Testi dell'interfaccia in italiano.
- Logica di gioco separata dall'interfaccia (`ChessGame` non importa Flutter), così da poterla testare in isolamento.
