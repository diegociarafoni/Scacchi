# Identità visiva

L'app si chiama **Rokko**, da *arrocco* e da *rook* (la torre in inglese): breve, uguale in italiano e in inglese, facile da dire anche per i bambini. Il repository, il pacchetto Dart (`scacchi`) e l'identificativo dell'app (`io.github.diegociarafoni.scacchi`) restano invariati, così gli aggiornamenti si installano sopra le versioni già presenti.

![Icona di Rokko](../assets/icon/icon.svg)

## Dove compare il nome

| Punto | File |
|---|---|
| Nome sotto l'icona su Android | `android/app/src/main/AndroidManifest.xml`, `android:label` |
| Nome sotto l'icona su iOS | `ios/Runner/Info.plist`, `CFBundleDisplayName` |
| Titolo dell'app e testi che la nominano | `lib/l10n/app_it.arb`, `lib/l10n/app_en.arb` (`appTitle`, `qrCameraError`) |
| Finestra su Linux e Windows | `linux/runner/my_application.cc`, `windows/runner/main.cpp`, `windows/runner/Runner.rc` |
| Promemoria, backup (`rokko-backup-….json`) e scheda della settimana (`rokko-settimana-….png`) | `lib/reminders/reminder.dart`, `lib/backup/`, `lib/stats/portrait_page.dart` |

`test/branding_test.dart` controlla che i nomi nativi siano Rokko e che l'identificativo non cambi.

Su macOS il pacchetto si chiama ancora `scacchi.app`: rinominarlo tocca il progetto Xcode in più punti e va verificato su un Mac. Il tag `Event` delle partite in PGN resta «Scacchi», che descrive il gioco e non l'app.

## Icona

Una torre sorridente su sfondo arancione, disegnata sulla griglia adattiva Android da 108 dp con il soggetto dentro la zona sicura da 66 dp: regge le maschere rotonde, a goccia e a squircle, e si legge anche a 29 px.

| Colore | Valore | Uso |
|---|---|---|
| Arancione | `#F2994A` | Sfondo dell'icona e della schermata di avvio chiara; torre nelle versioni scure |
| Crema | `#FFF6E9` | Torre nella versione chiara |
| Marrone | `#8A3B12` | Occhi e sorriso nella versione chiara |
| Notte | `#1C1714` | Sfondo della schermata di avvio scura |

Varianti generate:

- **Android**: icona adattiva con primo piano e sfondo separati, versione monocromatica per le icone a tema di Android 13 e successivi, icona classica per le versioni precedenti.
- **iOS**: icona chiara, scura (sfondo trasparente, lo aggiunge il sistema) e colorata dal sistema, come previsto da iOS 18.

## Schermata di avvio

Torre al centro su sfondo arancione col tema chiaro, torre arancione su sfondo scuro col tema scuro. Su Android 12 e successivi usa la schermata di sistema con la stessa immagine, senza cerchio di sfondo. La schermata segue il tema del telefono, perché compare prima che l'app legga le impostazioni: chi sceglie nell'app un tema diverso da quello del telefono vede per un istante l'altra versione.

## Rigenerare le immagini

Le forme sono definite solo in `tool/generate_icons.py`; i PNG in `assets/icon/` e i file nativi sono derivati.

```sh
python3 -m pip install cairosvg pillow
python3 tool/generate_icons.py            # assets/icon/*.png e icon.svg
dart run flutter_launcher_icons           # icone Android e iOS (flutter_launcher_icons.yaml)
dart run flutter_native_splash:create     # schermata di avvio (flutter_native_splash.yaml)
```

I due generatori sono dipendenze di sviluppo e non finiscono nell'app. `flutter_launcher_icons` 0.14 cambia per errore `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` in `ios/Runner.xcodeproj/project.pbxproj`: quella modifica va annullata con `git checkout ios/Runner.xcodeproj/project.pbxproj` prima del commit; `test/branding_test.dart` fallisce se la modifica resta.
