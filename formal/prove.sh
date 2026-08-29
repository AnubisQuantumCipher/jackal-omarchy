#!/bin/sh
set -eu

# Proof obligations: JOP-DOCTOR-001, JOP-STATE-001, JOP-STATE-002,
# JOP-ASSURANCE-001, JOP-CAP-001. JOP-BRIDGE-001 is checked separately.

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
PROJECT="$SCRIPT_DIR/jackal_assurance.gpr"

if ! command -v gnatprove >/dev/null 2>&1 || ! command -v gprbuild >/dev/null 2>&1; then
  if [ -f "$HOME/opt/gnat/env.sh" ]; then
    # shellcheck disable=SC1091
    . "$HOME/opt/gnat/env.sh"
  fi
fi

command -v gprbuild >/dev/null 2>&1 || {
  echo "refused: gprbuild is unavailable" >&2
  exit 1
}
command -v gnatprove >/dev/null 2>&1 || {
  echo "refused: gnatprove is unavailable" >&2
  exit 1
}

gprbuild -p -q -P "$PROJECT"
gnatprove -P "$PROJECT" -U --level=3 --report=all --warnings=error \
  --proof-warnings=on --assumptions -j0

PROOF_REPORT="$SCRIPT_DIR/obj/gnatprove/gnatprove.out"
[ -f "$PROOF_REPORT" ] || {
  echo "refused: GNATprove summary is missing" >&2
  exit 1
}

NORMALIZED_TOTAL=$(grep '^Total' "$PROOF_REPORT" | sed 's/([0-9]*%)//g' | tr -s ' ')
set -- $NORMALIZED_TOTAL
[ "$#" -eq 6 ] || {
  echo "refused: GNATprove total row is unparsable" >&2
  exit 1
}
JUSTIFIED=$5
UNPROVED=$6
[ "$JUSTIFIED" = "." ] && [ "$UNPROVED" = "." ] || {
  echo "refused: GNATprove reports justified or unproved checks" >&2
  exit 1
}

grep -q 'unit jackal_assurance_policy' "$PROOF_REPORT" || {
  echo "refused: the assurance policy unit was not analyzed" >&2
  exit 1
}

if rg -n --glob '*.ad?' 'pragma[[:space:]]+(Assume|Annotate)' \
  "$SCRIPT_DIR/src" "$SCRIPT_DIR/tests"; then
  echo "refused: proof assumptions or justifications are forbidden" >&2
  exit 1
fi

echo "SPARK_PLATINUM_COMPONENT_PROOF_PASS"
