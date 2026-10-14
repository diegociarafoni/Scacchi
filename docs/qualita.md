# Qualità

Ogni controllo ha un limite misurabile e blocca la CI se non è rispettato. I limiti numerici sono in [`tool/policy.json`](../tool/policy.json), così da cambiarli in un solo punto e con una revisione visibile. Questa pagina descrive i controlli oggi attivi, compresa la prova su emulatore Android ([End-to-end su emulatore](#end-to-end-su-emulatore)); non ci sono prove automatiche su un telefono fisico.

| Controllo | Strumento | Limite | Dove gira |
|---|---|---|---|
| Formattazione | `dart format` | nessuna differenza | pre-commit, CI |
| Analisi statica | `flutter analyze --fatal-infos --fatal-warnings` con [`analysis_options.yaml`](../analysis_options.yaml) | nessun avviso, nemmeno informativo | pre-commit, CI |
| Testi tradotti | `tool/l10n.dart`, `tool/stringhe_fisse.dart`, `tool/l10n_stato.dart` | lingue con le stesse chiavi; i testi italiani scritti nel codice non aumentano (base in `tool/stringhe_fisse_base.json`); le lingue «pronte» di `tool/lingue.json` complete | pre-commit (solo `l10n.dart`), `tool/verifica.sh`, CI |
| Test unitari, widget, accessibilità | `flutter test` | tutti verdi | pre-push (solo i test dei file modificati), CI |
| Copertura della logica di gioco | `tool/check_coverage.dart` | almeno 80% | CI |
| Sicurezza OWASP MASVS (sorgenti) | `test/security/` | permessi, log e SDK secondo `tool/policy.json` | pre-push, CI |
| Manifest dell'APK (MASVS) | `tool/check_apk.dart` | permessi ed esportazioni secondo `tool/policy.json`, non debuggable in rilascio | CI (job android), rilascio |
| Dimensione dell'APK | `tool/check_size.dart` | al massimo `budget.apkMaxMegabytes` (60 MB) | rilascio e nightly, prima della pubblicazione |
| Fluidità e avvio | `integration_test/fluidita_perf.dart` e `tool/check_performance.dart` | tempi di costruzione dei fotogrammi entro `budget.frames` e avvio entro `budget.startupMaxMs` | main, tag e PR che toccano la misura (workflow `Prestazioni`) |
| Analisi statica dell'APK (MobSF) | `.github/workflows/mobsf.yml`, `tool/check_mobsf.dart` | nessun avviso grave oltre a `mobsf.acceptedHigh`, punteggio almeno `mobsf.minSecurityScore` | settimanale su main e a richiesta (vedi [sicurezza.md](sicurezza.md)) |
| End-to-end su emulatore Android | `.github/workflows/e2e-android.yml` | i test di `integration_test/` indicati nel workflow passano su Android x86_64 (KVM) | main, a richiesta e PR che toccano il workflow, `integration_test/`, `android/` o `pubspec.*` |
| Golden test | `flutter test` con tag `golden` (più i golden di `test/settings/` e `test/style/`) | nessuna differenza di pixel | CI (Linux) |
| Accessibilità | linee guida di `flutter_test` | vedi sotto | CI |

## Copertura della logica di gioco

La logica di gioco è definita in modo automatico: ogni file in `lib/` scritto a mano che non importa Flutter (`package:flutter/…` o `dart:ui`), esclusi i testi localizzati generati. Un file di logica mai caricato dai test conta come scoperto, quindi aggiungere codice senza test fa scendere la percentuale. La regola rafforza anche la separazione tra logica e interfaccia descritta in [architettura.md](architettura.md). Per i file mai caricati si contano le righe di codice non vuote e non di commento, un'approssimazione per eccesso rispetto alle righe eseguibili di lcov.

```sh
flutter test --coverage && dart run tool/check_coverage.dart
```

## Budget di dimensione e fluidità

I due controlli sono pesanti, quindi girano solo dove serve: la dimensione sull'APK di rilascio che il workflow `Rilascio APK` costruisce comunque (un APK oltre il limite non viene pubblicato), la fluidità nel workflow `Prestazioni`, su `main`, sui tag e sulle PR che modificano la misura stessa.

- **Dimensione.** L'APK arm64 firmato include Stockfish; il limite di 60 MB lascia margine per una nuova funzione ma segnala un asset aggiunto per errore. Misura del 13 ottobre 2026 sul nightly (65 MiB compressi): librerie arm64 31 MiB (libapp 12, libflutter 11, motore 6, lettore QR 2,5), asset 17 MiB di cui 12,6 di chessground, e circa 15 MiB di librerie native per armeabi-v7a e x86_64 che i plugin impacchettavano anche nell'APK arm64. Il rimedio è doppio: `ROKKO_NATIVE_ABIS=arm64-v8a` nel rilascio e la copia ridotta di chessground in `third_party/chessground` (solo i 12 set di pezzi offerti, nessuna immagine di scacchiera; vedi `third_party/chessground/MODIFICHE.md`). Il motore usa già la rete NNUE piccola incorporata (circa 1 MB): non c'è una rete più piccola da valutare. Per cambiare il limite si modifica `budget.apkMaxMegabytes` in `tool/policy.json`, con una revisione visibile.
- **Fluidità.** Il test sta in `integration_test/` perché solo lì `flutter test -d linux` avvia l'app; il suffisso `_perf` (non `_test`) lo esclude dal giro dei test end-to-end della CI. Gioca otto mosse sulla scacchiera, passa alla scheda Tu della Home e scorre la pagina su desktop Linux (Xvfb), registrando con `watchPerformance` i `FrameTiming` e scrivendo `build/performance.json`; `tool/check_performance.dart` confronta il 90° e il 99° percentile del tempo di costruzione con `budget.frames`. Prima della partita il test cronometra l'avvio, dal lancio alla Home con la barra di navigazione (campo `startup_ms` del rapporto), e `tool/check_performance.dart` lo confronta con `budget.startupMaxMs` (2000 ms, l'obiettivo di RM-07: su un runner desktop in modalità debug è un limite largo, che intercetta un'inizializzazione lenta aggiunta all'avvio, non certifica un telefono di fascia media). Si misura solo la costruzione: sul runner senza GPU la rasterizzazione non è significativa. Il test gira in modalità debug, quindi i limiti sono larghi: servono a intercettare una regressione grossolana, non a certificare i 60 fotogrammi al secondo su un telefono. Il rapporto è allegato al workflow (artefatto `prestazioni`).

```sh
dart run tool/check_size.dart build/app/outputs/flutter-apk/app-release.apk
xvfb-run -a flutter test integration_test/fluidita_perf.dart -d linux && dart run tool/check_performance.dart
```

## End-to-end su emulatore

Il workflow `E2E Android` compila l'app di debug per x86_64 e la prova su un emulatore (API 34, accelerato con KVM, senza finestra) con `flutter test integration_test/<file>.dart -d emulator-5554`, un file alla volta come su desktop. Sono inclusi solo i test che non dipendono dal desktop (non quelli che avviano il Stockfish di sistema né quelli con la fotocamera); la suite lunga `app_test.dart` resta su desktop, perché su emulatore con rendering software supera i dieci minuti; l'elenco è nel passo «Test end-to-end». Per aggiungerne uno basta il nome del file nel ciclo (oggi `portrait_test` e `weekly_summary_test`). Serve a trovare problemi che il desktop non mostra: libreria nativa, permessi, dimensioni dello schermo e ciclo di vita Android.

## Golden test

`test/golden/` confronta schermate di Rokko con immagini di riferimento in `test/golden/goldens/`: la partita (anche a fine partita, in tema scuro), la Home (anche su tablet in orizzontale), la galleria dei bot, i badge, l'esploratore delle aperture, i puzzle, il Percorso (chiaro, scuro, testo al 130% e profilo bambino), la Storia, la scheda Tu, il multigiocatore, l'istruttore e i fumetti dei personaggi. Le schermate usano gli schermi definiti in `test/support/devices.dart`:

| Nome | Dimensione logica | Esempio |
|---|---|---|
| telefono-piccolo | 360 × 640 | Android compatto |
| telefono-medio | 393 × 852 | iPhone 15 |
| telefono-grande | 430 × 932 | iPhone 15 Pro Max |
| telefono-orizzontale | 852 × 393 | telefono ruotato |
| tablet | 820 × 1180 | iPad Air |

Altri golden stanno in `test/settings/goldens/` (menu delle Impostazioni e pagina Scacchiera) e in `test/style/goldens/` (schermata Stile).

Le immagini usano Roboto e le icone Material dell'SDK, quindi i testi sono leggibili. Il rendering dei caratteri cambia tra sistemi operativi: i riferimenti si generano e si confrontano solo su Linux, e i test di `test/golden/` e `test/style/` si saltano da soli fuori da Linux; il tag `golden` li esclude anche dall'hook locale.

Per aggiornare i riferimenti dopo un cambio grafico voluto:

```sh
flutter test --tags golden test/golden test/style --update-goldens   # su Linux, oppure in un container Linux
flutter test test/settings --update-goldens
```

## Test deterministici

Un test non deve dipendere dal tempo, dal carico del runner o dagli strumenti installati. Regole:

- Niente attese fisse per disco, relay o Bluetooth: si aspetta la condizione con `until`, `untilSaved`, `untilMoves` o, nei widget test, `pumpUntil` (`test/support/wait.dart`). Scadono con un messaggio che dice cosa mancava.
- Per i canali in memoria (`LoopbackTransport`) basta `settleLoopback()`, che conta i giri del ciclo di eventi invece dei millisecondi.
- Un'attesa a tempo fisso resta solo per provare che qualcosa *non* succede.
- I golden non dipendono dall'ambiente: `test/golden/flutter_test_config.dart` fissa il motore come disponibile (`StockfishTransport.debugSupported`), altrimenti la schermata cambia secondo che Stockfish sia installato.
- Per cercare gli instabili si esegue la suite con la CPU satura (per esempio un ciclo vuoto per ogni core, più `--concurrency` pari ai core) e si ripete: un test corretto passa ogni volta.

## Accessibilità

`test/accessibility/accessibility_test.dart` verifica, in tema chiaro e scuro, sulla Home:

- ogni elemento toccabile ha un'etichetta per TalkBack e VoiceOver;
- dimensioni tattili minime di Android (48 × 48) e iOS (44 × 44);
- contrasto del testo almeno 4,5:1 (WCAG AA);

e inoltre che i comandi della barra della partita siano annunciati come pulsanti, con il loro stato attivo o disattivo, che con il testo di sistema al 200% non ci siano sovrapposizioni su nessun telefono e che i pezzi catturati si vedano sullo sfondo scuro.

`touch_targets_130_test.dart`: con il testo al 130%, su telefono piccolo e medio, schede della barra, impostazioni (menu e ogni sezione), Storia, partita e menu ⋮ non hanno overflow, hanno bersagli di tocco da 48 dp e comandi con etichetta.

Altre prove per il requisito RNF-07: mossa da tastiera (`test/move_input_test.dart`), annuncio delle mosse (`test/move_speech_test.dart`), colori per daltonici (`test/settings/color_blind_test.dart`). Le animazioni ridotte dal sistema sono in `test/settings/reduce_motion_test.dart` (pezzi e pagine), `test/theme/motion_test.dart` (dialoghi e fogli) e `test/review/eval_bar_motion_test.dart` (barra di valutazione). Resta da coprire l'annuncio delle case sulla scacchiera.
