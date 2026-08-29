#!/bin/bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
cd "$ROOT"

export JACKAL_REQUIRE_FORMAL=1

./scripts/check.sh
python3 -B tests/ledger.test.py
./scripts/check-release-reproducibility.sh

echo "JACKAL_OMARCHY_RELEASE_GATE_PASS"
