#!/usr/bin/env bash
# Prepara le sessioni cloud: Flutter alla versione della CI, lefthook e
# Gitleaks, poi attiva gli hook git versionati in lefthook.yml.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}"

flutter_version="$(sed -n 's/^ *flutter-version: *\([0-9.]*\).*/\1/p' .github/workflows/ci.yml | head -1)"
gitleaks_version="v8.30.1" # la stessa di .github/workflows/conventions.yml
flutter_dir="$HOME/flutter"
go_bin="$(go env GOPATH 2>/dev/null || echo "$HOME/go")/bin"

if [ -z "$flutter_version" ]; then
  echo "versione di Flutter non trovata in .github/workflows/ci.yml" >&2
  exit 1
fi

# Il percorso viene scritto subito: anche se un passo fallisce, le sessioni
# successive trovano gli strumenti già installati.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$flutter_dir/bin:$go_bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

# Clone in una cartella temporanea: un'interruzione non lascia una copia a metà.
if [ ! -x "$flutter_dir/bin/flutter" ]; then
  rm -rf "$flutter_dir.tmp"
  git clone -q --depth 1 -b "$flutter_version" https://github.com/flutter/flutter.git "$flutter_dir.tmp"
  rm -rf "$flutter_dir"
  mv "$flutter_dir.tmp" "$flutter_dir"
fi
export PATH="$flutter_dir/bin:$go_bin:$PATH"

command -v lefthook >/dev/null || npm install -g lefthook
command -v gitleaks >/dev/null || go install "github.com/zricethezav/gitleaks/v8@$gitleaks_version"

# Gli hook git non leggono CLAUDE_ENV_FILE: gli strumenti vanno nel PATH di sistema.
if [ -w /usr/local/bin ]; then
  for t in "$go_bin/gitleaks" "$flutter_dir/bin/flutter" "$flutter_dir/bin/dart"; do
    [ -e "/usr/local/bin/$(basename "$t")" ] || ln -s "$t" /usr/local/bin/
  done
fi

# In una copia nuova i .arb vanno uniti prima del pub get.
flutter --suppress-analytics --version >/dev/null
dart tool/l10n.dart --solo-unione
flutter --suppress-analytics pub get
dart tool/l10n.dart

lefthook install
