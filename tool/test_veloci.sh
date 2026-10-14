#!/usr/bin/env bash
# Test dei soli file toccati dal ramo: i test modificati e quelli che
# corrispondono ai sorgenti modificati (lib/x/y.dart -> test/x/y_test.dart),
# più sempre test/security. La suite completa, golden compresi, gira in CI.
set -euo pipefail
cd "$(dirname "$0")/.."

git fetch -q origin main || true
base="$(git merge-base origin/main HEAD 2>/dev/null || echo HEAD)"

lista="$(mktemp)"
trap 'rm -f "$lista"' EXIT
echo test/security >> "$lista"
git diff --name-only "$base"..HEAD | while IFS= read -r f; do
  case "$f" in
    test/golden/* | test/style/*) ;;
    test/*_test.dart) [ -f "$f" ] && echo "$f" ;;
    lib/*.dart)
      t="test/${f#lib/}"
      t="${t%.dart}_test.dart"
      [ -f "$t" ] && echo "$t" ;;
  esac
done >> "$lista" || true

# Senza mapfile e senza array vuoti, per la bash 3.2 di macOS.
flutter test --exclude-tags golden $(sort -u "$lista" | tr '\n' ' ')
