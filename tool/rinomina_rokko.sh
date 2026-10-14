#!/usr/bin/env bash
# Rinomina l'identificativo tecnico «scacchi» in «rokko» (pacchetto Dart,
# applicationId e bundle id, binari desktop, variabili di CI). Ripetibile:
# su un albero già rinominato non cambia nulla. Non tocca la parola comune
# «scacchi», né l'alias, il sale e il nome del certificato del keystore, né le
# stringhe dei protocolli multigiocatore (schema scacchi://, contesti HKDF,
# firme e UUID BLE): cambiarli romperebbe la compatibilità.
set -euo pipefail
cd "$(dirname "$0")/.."

vecchio_id="io.github.diegociarafoni.scacchi"
nuovo_id="io.github.diegociarafoni.rokko"

files=$(git ls-files | grep -vE '\.(png|webp|jpg|jpeg|ico|icns|ttf|otf|woff2?|mp3|ogg|wav|zip|gz|db|bin)$' \
  | grep -v '^tool/rinomina_rokko.sh$')

# Ogni regola è una sostituzione esatta e delimitata: niente «scacchiera».
echo "$files" | xargs perl -pi -e '
  s/\Q'"$vecchio_id"'\E/'"$nuovo_id"'/g;
  s/package:scacchi\//package:rokko\//g;
  s/ScacchiApp/RokkoApp/g;
  s/SCACCHI_NATIVE_ABIS/ROKKO_NATIVE_ABIS/g;
  s/\bscacchi\.app\b/rokko.app/g;
  s/\bscacchi-debug-apk\b/rokko-debug-apk/g;
  s/^name: scacchi$/name: rokko/;
  s/^description: "Scacchi offline/description: "Rokko offline/;
  s/BINARY_NAME "scacchi"/BINARY_NAME "rokko"/;
  s/^project\(scacchi /project(rokko /;
  s/^PRODUCT_NAME = scacchi$/PRODUCT_NAME = rokko/;
  s/\/scacchi"; *$/\/rokko";/;
  s/"InternalName", "scacchi"/"InternalName", "rokko"/;
  s/"OriginalFilename", "scacchi\.exe"/"OriginalFilename", "rokko.exe"/;
'

vecchia=android/app/src/main/kotlin/io/github/diegociarafoni/scacchi
if [ -d "$vecchia" ]; then
  git mv "$vecchia" android/app/src/main/kotlin/io/github/diegociarafoni/rokko
fi

# Il backup scrive «rokko» e legge anche «scacchi» dei file già esistenti.
perl -0pi -e "s/  static const _app = 'scacchi';/  static const _app = 'rokko';\n  static const _appVecchio = 'scacchi';/;
  s/json\['app'\] != _app\b(?! \&\&)/json['app'] != _app \&\& json['app'] != _appVecchio/" lib/backup/backup.dart
