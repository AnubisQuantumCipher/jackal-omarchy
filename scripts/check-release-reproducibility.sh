#!/bin/bash
set -euo pipefail

# JOP-REL-001: two independent clean checkouts must produce identical bytes.

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
cd "$ROOT"

[[ -z $(git status --porcelain) ]] || {
  echo "reproducibility refused: working tree is not clean" >&2
  exit 3
}

VERSION=$(tr -d '\n' < VERSION)
COMMIT=$(git rev-parse --verify 'HEAD^{commit}')
[[ $COMMIT =~ ^[0-9a-f]{40}$ ]] || {
  echo "reproducibility refused: HEAD is not a full lowercase commit identity" >&2
  exit 4
}
NAME="jackal-omarchy-v${VERSION}"
AUDIT_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/jackal-omarchy-repro.XXXXXX")

cleanup() {
  case ${AUDIT_ROOT:-} in
    "${TMPDIR:-/tmp}"/jackal-omarchy-repro.*)
      rm -rf -- "$AUDIT_ROOT"
      ;;
  esac
}
trap cleanup EXIT HUP INT TERM

for BUILD_NAME in first second; do
  CHECKOUT="$AUDIT_ROOT/$BUILD_NAME"
  OUTPUT="$AUDIT_ROOT/output-$BUILD_NAME"
  git init --quiet "$CHECKOUT"
  git -C "$CHECKOUT" remote add exact-source "$ROOT"
  git -C "$CHECKOUT" fetch --quiet --depth=1 exact-source "$COMMIT"
  git -C "$CHECKOUT" checkout --quiet --detach "$COMMIT"
  CHECKED_OUT_COMMIT=$(git -C "$CHECKOUT" rev-parse --verify 'HEAD^{commit}')
  [[ $CHECKED_OUT_COMMIT == "$COMMIT" ]] || {
    echo "reproducibility refused: detached checkout identity mismatch" >&2
    exit 5
  }
  JACKAL_RELEASE_DIST="$OUTPUT" "$CHECKOUT/scripts/package-release.sh"
done

FIRST="$AUDIT_ROOT/output-first/$NAME.tar.gz"
SECOND="$AUDIT_ROOT/output-second/$NAME.tar.gz"
FIRST_DIGEST="$FIRST.sha256"
SECOND_DIGEST="$SECOND.sha256"

cmp "$FIRST" "$SECOND"
cmp "$FIRST_DIGEST" "$SECOND_DIGEST"
(
  cd -- "$(dirname -- "$FIRST")"
  sha256sum -c "$(basename -- "$FIRST_DIGEST")"
)
(
  cd -- "$(dirname -- "$SECOND")"
  sha256sum -c "$(basename -- "$SECOND_DIGEST")"
)

echo "RELEASE_REPRODUCIBILITY_PASS"
