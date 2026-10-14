#!/usr/bin/env bash
# Prepara le sessioni cloud: Flutter alla versione della CI, lefthook e
# Gitleaks, poi attiva gli hook git versionati in lefthook.yml.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}"

flutter_version="$(sed -n 's/^ *flutter-version: *//p' .github/workflows/ci.yml | head -1)"
flutter_dir="$HOME/flutter"
go_bin="$(go env GOPATH 2>/dev/null || echo "$HOME/go")/bin"

if [ ! -x "$flutter_dir/bin/flutter" ]; then
  git clone -q --depth 1 -b "$flutter_version" https://github.com/flutter/flutter.git "$flutter_dir"
fi
export PATH="$flutter_dir/bin:$go_bin:$PATH"

command -v lefthook >/dev/null || npm install -g lefthook
command -v gitleaks >/dev/null || go install github.com/zricethezav/gitleaks/v8@latest

# In una copia nuova i .arb vanno uniti prima del pub get.
# Link nel PATH di sistema: gli hook git non leggono CLAUDE_ENV_FILE.
ln -sf "$go_bin/gitleaks" /usr/local/bin/gitleaks
ln -sf "$flutter_dir/bin/flutter" /usr/local/bin/flutter
ln -sf "$flutter_dir/bin/dart" /usr/local/bin/dart

flutter --suppress-analytics --version >/dev/null
dart tool/l10n.dart --solo-unione
flutter --suppress-analytics pub get
dart tool/l10n.dart

lefthook install

# Le sessioni successive trovano gli strumenti nel PATH.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$flutter_dir/bin:$go_bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi
