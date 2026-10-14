# Modifiche rispetto a chessground 10.3.0

Questa è una copia di [chessground](https://github.com/lichess-org/flutter-chessground) 10.3.0 (GPL-3.0, vedi `LICENSE`), usata al posto del pacchetto di pub.dev tramite il percorso in `pubspec.yaml` di Rokko. Il codice in `lib/` è identico all'originale. Cambiano solo gli asset dichiarati:

- restano i soli 12 set di pezzi che Rokko offre (`cburnett`, `celtic`, `chessnut`, `fantasy`, `firi`, `kiwen-suwi`, `merida`, `mpchess`, `rhosgfx`, `shapes`, `spatial`, `totoy`);
- sono tolti gli altri 28 set e tutte le immagini di scacchiera (`assets/boards/`), che non si usano e pesavano circa 12 MB compressi nell'APK, e il cui elenco di licenze include set non compatibili con la GPL.

Scegliere nell'app un set tolto non è possibile; il test `test/third_party/chessground_ridotto_test.dart` fallisce se il codice usa un set non presente.

## Aggiornare chessground

1. Scaricare la nuova versione (`flutter pub cache add chessground --version X.Y.Z`).
2. `dart tool/vendor_chessground.dart <cartella nella cache di pub>`.
3. Aggiornare il numero di versione qui e in `CREDITS.md`, lanciare `flutter pub get` e i test.
