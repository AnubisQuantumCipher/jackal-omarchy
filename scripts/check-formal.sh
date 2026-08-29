#!/bin/bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)

if ! command -v gnatprove >/dev/null 2>&1 || ! command -v gprbuild >/dev/null 2>&1; then
  if [[ -f $HOME/opt/gnat/env.sh ]]; then
    # shellcheck disable=SC1091
    source "$HOME/opt/gnat/env.sh"
  fi
fi

if ! command -v gnatprove >/dev/null 2>&1 || ! command -v gprbuild >/dev/null 2>&1; then
  if [[ ${JACKAL_REQUIRE_FORMAL:-0} == 1 ]]; then
    echo "refused: the release gate requires gprbuild and gnatprove" >&2
    exit 1
  fi
  echo "SKIP SPARK proof: gprbuild or gnatprove is unavailable"
  exit 0
fi

"$ROOT/formal/prove.sh"
node "$ROOT/tests/formal_conformance.test.mjs"
python3 -B "$ROOT/tests/formal_operator_conformance.test.py"
