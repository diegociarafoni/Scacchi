#!/usr/bin/env bash
# Controlli veloci prima del push, gli stessi che la CI esegue su ogni PR:
# nome del ramo, messaggi dei commit, titolo della PR (facoltativo), nessun
# sottomodulo, documentazione, testi tradotti, formattazione e analisi. Con
# --test anche i test senza golden.
#
#   tool/verifica.sh [--titolo "feat(game): titolo della PR"] [--test]
set -euo pipefail
cd "$(dirname "$0")/.."

titolo=""
test_run=false
while [ $# -gt 0 ]; do
  case "$1" in
    --titolo) titolo="${2:?manca il titolo}"; shift 2 ;;
    --test) test_run=true; shift ;;
    *) echo "uso: tool/verifica.sh [--titolo \"...\"] [--test]" >&2; exit 2 ;;
  esac
done

git fetch -q origin main || echo "avviso: origin/main non aggiornato, si usa la copia locale" >&2

if ! git rev-parse --verify -q origin/main >/dev/null; then
  echo "✗ manca origin/main (clone senza il ramo principale o remoto non configurato)." >&2
  echo "  Aggiungere il remoto o scaricarlo con: git fetch origin main" >&2
  exit 1
fi

dart tool/check_branch_name.dart "$(git rev-parse --abbrev-ref HEAD)"
base="$(git merge-base origin/main HEAD)"
dart tool/check_commit_msg.dart --range "$base..HEAD"
if [ -n "$titolo" ]; then dart tool/check_commit_msg.dart --text "$titolo"; fi

# Una cartella con un repository dentro (per esempio .claude/worktrees/...)
# finisce nell'indice come sottomodulo e fa fallire il checkout in CI.
if git ls-files -s | grep -q '^160000'; then
  echo "✗ nell'indice c'è un sottomodulo, di solito una copia di lavoro aggiunta per errore:" >&2
  git ls-files -s | grep '^160000' >&2
  echo "  toglierlo con: git rm --cached <percorso>" >&2
  exit 1
fi

dart tool/check_docs.dart
dart tool/check_comments.dart
dart tool/l10n.dart
dart tool/stringhe_fisse.dart
dart tool/l10n_stato.dart
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter analyze --fatal-infos --fatal-warnings
if $test_run; then flutter test --exclude-tags golden; fi
echo "✓ controlli superati"
