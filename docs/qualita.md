# Qualità

Ogni controllo ha un limite misurabile e blocca la CI se non è rispettato. I limiti numerici sono in [`tool/policy.json`](../tool/policy.json), così da cambiarli in un solo punto e con una revisione visibile. Questa pagina descrive i controlli oggi attivi; dimensioni, fluidità e prove sul telefono arriveranno in PR successive.

| Controllo | Strumento | Limite | Dove gira |
|---|---|---|---|
| Formattazione | `dart format` | nessuna differenza | pre-commit, CI |
| Analisi statica | `flutter analyze --fatal-infos` con [`analysis_options.yaml`](../analysis_options.yaml) | nessun avviso, nemmeno informativo | pre-commit, CI |
| Test unitari, widget, accessibilità | `flutter test` | tutti verdi | pre-push (senza golden), CI |
| Copertura della logica di gioco | `tool/check_coverage.dart` | almeno 80% | CI |
| Sicurezza OWASP MASVS (sorgenti) | `test/security/` | permessi, log e SDK secondo `tool/policy.json` | pre-push, CI |
| Golden test | `flutter test` con tag `golden` | nessuna differenza di pixel | CI (Linux) |
| Accessibilità | linee guida di `flutter_test` | vedi sotto | pre-push, CI |

## Copertura della logica di gioco

La logica di gioco è definita in modo automatico: ogni file in `lib/` scritto a mano che non importa Flutter (`package:flutter/…` o `dart:ui`), esclusi i testi localizzati generati. Un file di logica mai caricato dai test conta come scoperto, quindi aggiungere codice senza test fa scendere la percentuale. La regola rafforza anche la separazione tra logica e interfaccia descritta in [architettura.md](architettura.md). Per i file mai caricati si contano le righe di codice non vuote e non di commento, un'approssimazione per eccesso rispetto alle righe eseguibili di lcov. Misura attuale: 95,5%.

```sh
flutter test --coverage && dart run tool/check_coverage.dart
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
