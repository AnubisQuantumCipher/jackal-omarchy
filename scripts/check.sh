#!/bin/bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"

export PYTHONDONTWRITEBYTECODE=1

python3 -B scripts/check-traceability.py
python3 -B tests/repository.test.py
python3 -B tests/operator_cli.test.py
python3 -B tests/presentation.test.py
python3 -B tests/ledger.test.py --fast
node tests/model.test.mjs
./scripts/check-formal.sh
python3 -B tests/router.test.py

bash -n scripts/check.sh
bash -n scripts/check-formal.sh
bash -n scripts/package-release.sh
bash -n scripts/check-release-reproducibility.sh
bash -n scripts/release-gate.sh

if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin validate "$ROOT"
else
  echo "SKIP omarchy plugin validate: omarchy is not installed"
fi

QMLLINT_BIN=""
if [[ -x /usr/lib/qt6/bin/qmllint ]]; then
  QMLLINT_BIN=/usr/lib/qt6/bin/qmllint
elif command -v qmllint6 >/dev/null 2>&1; then
  QMLLINT_BIN=$(command -v qmllint6)
elif command -v qmllint >/dev/null 2>&1 && qmllint --version 2>&1 | grep -q 'Qt 6'; then
  QMLLINT_BIN=$(command -v qmllint)
fi

if [[ -n $QMLLINT_BIN && -n ${OMARCHY_PATH:-} && -d ${OMARCHY_PATH}/shell ]]; then
  # Omarchy's `qs.*` imports are resolved by Quickshell from the shell source
  # root.  qmllint expects the URI-shaped `qs/` directory, so build that view
  # in an isolated temporary directory.  Lint the panel under a different
  # filename so its imported `qs.Ui.Panel` base type is not mistaken for a
  # self-reference solely because the entry point is also named Panel.qml.
  QMLLINT_TMP=$(mktemp -d "${TMPDIR:-/tmp}/jackal-omarchy-qmllint.XXXXXX")
  QMLLINT_LOG="$ROOT/build/qmllint.log"
  cleanup_qmllint() {
    case "$QMLLINT_TMP" in
      "${TMPDIR:-/tmp}"/jackal-omarchy-qmllint.*)
        unlink "$QMLLINT_TMP/imports/qs" 2>/dev/null || true
        rm -- "$QMLLINT_TMP/JackalPanel.qml" \
          "$QMLLINT_TMP/Service.qml" "$QMLLINT_TMP/Model.js" 2>/dev/null || true
        rmdir "$QMLLINT_TMP/imports" "$QMLLINT_TMP" 2>/dev/null || true
        ;;
    esac
  }
  trap cleanup_qmllint EXIT
  mkdir -p "$QMLLINT_TMP/imports" "$ROOT/build"
  ln -s "$OMARCHY_PATH/shell" "$QMLLINT_TMP/imports/qs"
  cp Panel.qml "$QMLLINT_TMP/JackalPanel.qml"
  cp Service.qml Model.js "$QMLLINT_TMP/"

  if "$QMLLINT_BIN" -I "$QMLLINT_TMP/imports" \
      "$QMLLINT_TMP/JackalPanel.qml" "$QMLLINT_TMP/Service.qml" \
      >"$QMLLINT_LOG" 2>&1; then
    echo "QMLLINT_PASS diagnostics=$QMLLINT_LOG"
  else
    cat "$QMLLINT_LOG"
    echo "FAIL: Qt 6 qmllint rejected JACKAL QML" >&2
    exit 1
  fi
else
  echo "SKIP qmllint: Qt 6 qmllint or the Omarchy QML import tree is unavailable"
fi

echo "JACKAL_OMARCHY_CHECK_PASS"
