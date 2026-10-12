# Qualità

Ogni controllo ha un limite misurabile e blocca la CI se non è rispettato. I limiti numerici sono in [`tool/policy.json`](../tool/policy.json), così da cambiarli in un solo punto e con una revisione visibile. Questa pagina descrive i controlli oggi attivi; le prove sul telefono arriveranno in PR successive.

| Controllo | Strumento | Limite | Dove gira |
|---|---|---|---|
| Formattazione | `dart format` | nessuna differenza | pre-commit, CI |
| Analisi statica | `flutter analyze --fatal-infos` con [`analysis_options.yaml`](../analysis_options.yaml) | nessun avviso, nemmeno informativo | pre-commit, CI |
| Test unitari, widget, accessibilità | `flutter test` | tutti verdi | pre-push (senza golden), CI |
| Copertura della logica di gioco | `tool/check_coverage.dart` | almeno 80% | CI |
| Sicurezza OWASP MASVS (sorgenti) | `test/security/` | permessi, log e SDK secondo `tool/policy.json` | pre-push, CI |
| Manifest dell'APK (MASVS) | `tool/check_apk.dart` | permessi ed esportazioni secondo `tool/policy.json`, non debuggable in rilascio | CI (job android), rilascio |
| Dimensione dell'APK | `tool/check_size.dart` | al massimo `budget.apkMaxMegabytes` (80 MB) | rilascio e nightly, prima della pubblicazione |
| Fluidità | `integration_test/fluidita_perf.dart` e `tool/check_performance.dart` | tempi di costruzione dei fotogrammi entro `budget.frames` | main, tag e PR che toccano la misura (workflow `Prestazioni`) |
| Analisi statica dell'APK (MobSF) | `.github/workflows/mobsf.yml`, `tool/check_mobsf.dart` | nessun avviso grave oltre a `mobsf.acceptedHigh`, punteggio almeno `mobsf.minSecurityScore` | settimanale su main e a richiesta (vedi [sicurezza.md](sicurezza.md)) |
| Golden test | `flutter test` con tag `golden` | nessuna differenza di pixel | CI (Linux) |
| Accessibilità | linee guida di `flutter_test` | vedi sotto | pre-push, CI |

## Copertura della logica di gioco

La logica di gioco è definita in modo automatico: ogni file in `lib/` scritto a mano che non importa Flutter (`package:flutter/…` o `dart:ui`), esclusi i testi localizzati generati. Un file di logica mai caricato dai test conta come scoperto, quindi aggiungere codice senza test fa scendere la percentuale. La regola rafforza anche la separazione tra logica e interfaccia descritta in [architettura.md](architettura.md). Per i file mai caricati si contano le righe di codice non vuote e non di commento, un'approssimazione per eccesso rispetto alle righe eseguibili di lcov. Misura attuale: 95,5%.

```sh
flutter test --coverage && dart run tool/check_coverage.dart
```

## Budget di dimensione e fluidità

I due controlli sono pesanti, quindi girano solo dove serve: la dimensione sull'APK di rilascio che il workflow `Rilascio APK` costruisce comunque (un APK oltre il limite non viene pubblicato), la fluidità nel workflow `Prestazioni`, su `main`, sui tag e sulle PR che modificano la misura stessa.

- **Dimensione.** L'APK arm64 firmato pesa oggi circa 63 MiB (Stockfish compreso); il limite di 80 MB lascia margine per una nuova funzione ma segnala un asset aggiunto per errore. Per cambiare il limite si modifica `budget.apkMaxMegabytes` in `tool/policy.json`, con una revisione visibile.
- **Fluidità.** Il test sta in `integration_test/` perché solo lì `flutter test -d linux` avvia l'app; il suffisso `_perf` (non `_test`) lo esclude dal giro dei test end-to-end della CI. Gioca otto mosse sulla scacchiera e scorre la pagina del profilo su desktop Linux (Xvfb), registrando con `watchPerformance` i `FrameTiming` e scrivendo `build/performance.json`; `tool/check_performance.dart` confronta il 90° e il 99° percentile del tempo di costruzione con `budget.frames`. Si misura solo la costruzione: sul runner senza GPU la rasterizzazione non è significativa. Il test gira in modalità debug, quindi i limiti sono larghi: servono a intercettare una regressione grossolana, non a certificare i 60 fotogrammi al secondo su un telefono. Il rapporto è allegato al workflow (artefatto `prestazioni`).

```sh
dart run tool/check_size.dart build/app/outputs/flutter-apk/app-release.apk
xvfb-run -a flutter test integration_test/fluidita_perf.dart -d linux && dart run tool/check_performance.dart
```

## Golden test

`test/golden/` confronta la schermata di gioco con immagini di riferimento in `test/golden/goldens/` su cinque schermi definiti in `test/support/devices.dart`, più una partita finita in scacco matto in tema scuro:

| Nome | Dimensione logica | Esempio |
|---|---|---|
| telefono-piccolo | 360 × 640 | Android compatto |
| telefono-medio | 393 × 852 | iPhone 15 |
| telefono-grande | 430 × 932 | iPhone 15 Pro Max |
| telefono-orizzontale | 852 × 393 | telefono ruotato |
| tablet | 820 × 1180 | iPad Air |

Le immagini usano Roboto e le icone Material dell'SDK, quindi i testi sono leggibili. Il rendering dei caratteri cambia tra sistemi operativi: i riferimenti si generano e si confrontano solo su Linux, e i test si saltano da soli fuori da Linux; il tag `golden` li esclude anche dall'hook locale.

Per aggiornare i riferimenti dopo un cambio grafico voluto:

```sh
flutter test --tags golden test/golden --update-goldens   # su Linux, oppure in un container Linux
```

## Accessibilità

`test/accessibility/` verifica, in tema chiaro e scuro, sulla schermata principale:

- ogni elemento toccabile ha un'etichetta per TalkBack e VoiceOver;
- dimensioni tattili minime di Android (48 × 48) e iOS (44 × 44);
- contrasto del testo almeno 4,5:1 (WCAG AA);
- i comandi della barra in basso sono annunciati come pulsanti, con il loro stato attivo o disattivo (questo test ha trovato che `_ActionButton` non lo era, ora corretto);
- con il testo di sistema al 200% non ci sono sovrapposizioni su nessun telefono.

Restano da coprire, con il requisito RNF-07: annuncio delle case e delle mosse sulla scacchiera, inserimento testuale della mossa, opzione per ridurre le animazioni.
