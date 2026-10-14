# Identità visiva

L'app si chiama **Rokko**, da *arrocco* e da *rook* (la torre in inglese): breve, uguale in italiano e in inglese, facile da dire anche per i bambini. Il nome è lo stesso ovunque: repository, pacchetto Dart (`rokko`), identificativo dell'app (`io.github.diegociarafoni.rokko`), bundle id e binari desktop. L'identificativo è cambiato prima della pubblicazione sugli store (PR di rinomina, dopo la 0.11.0): il primo APK successivo non si installa sopra quello con l'identificativo vecchio e va installato come app nuova, con un backup per portare i dati. Restano con il nome storico `scacchi`, perché non li vede nessuno e cambiarli romperebbe la compatibilità, l'alias e il sale del keystore di firma, i contesti crittografici del multigiocatore e il campo `app` dei backup già creati, che si leggono ancora. `tool/rinomina_rokko.sh` ripete la rinomina.

![Icona di Rokko](../assets/icon/icon.svg)

## Dove compare il nome

| Punto | File |
|---|---|
| Nome sotto l'icona su Android | `android/app/src/main/AndroidManifest.xml`, `android:label` |
| Nome sotto l'icona su iOS | `ios/Runner/Info.plist`, `CFBundleDisplayName` |
| Titolo dell'app e testi che la nominano | `lib/l10n/it/app.arb`, `lib/l10n/en/app.arb` (`appTitle`); `qrCameraError` è in `exchange.arb` |
| Finestra su Linux e Windows | `linux/runner/my_application.cc`, `windows/runner/main.cpp`, `windows/runner/Runner.rc` |
| Promemoria, backup (`rokko-backup-….json`) e scheda della settimana (`rokko-settimana-….png`) | `lib/reminders/reminder.dart`, `lib/backup/`, `lib/stats/portrait_page.dart` |

`test/branding_test.dart` controlla che i nomi nativi siano Rokko e che l'identificativo non cambi.

Su macOS il pacchetto si chiama ancora `rokko.app`: rinominarlo tocca il progetto Xcode in più punti e va verificato su un Mac. Il tag `Event` delle partite in PGN è «Rokko».

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

## Torre-mascotte

`RokkoMascot` (`lib/theme/rokko_mascot.dart`) ridisegna la torre dell'icona con un `CustomPainter`, sulle stesse coordinate di `tool/generate_icons.py`: arancione con occhi e sorriso marroni, uguale nei temi chiaro e scuro. È solo decorativa e non ha testo per i lettori di schermo. `EmptyState` la mette sopra una frase breve negli stati vuoti: oggi nell'archivio senza partite e nell'albero delle aperture personali senza partite. A fine partita la torre compare a sinistra dell'esito sotto la scacchiera, tranne quando perdi contro il computer e in modalità zen (che toglie ogni decorazione).

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
