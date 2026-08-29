#!/bin/bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"

VERSION=$(tr -d '\n' < VERSION)
[[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "release refused: VERSION is not a stable semantic version" >&2
  exit 2
}

MANIFEST_VERSION=$(python3 -B -c 'import json; print(json.load(open("manifest.json"))["version"])')
[[ $MANIFEST_VERSION == "$VERSION" ]] || {
  echo "release refused: VERSION and manifest.json disagree" >&2
  exit 2
}

[[ -z $(git status --porcelain) ]] || {
  echo "release refused: working tree is not clean" >&2
  exit 3
}

./scripts/check.sh

NAME="jackal-omarchy-v${VERSION}"
DIST="$ROOT/dist"
ARCHIVE="$DIST/$NAME.tar.gz"
DIGEST="$ARCHIVE.sha256"

[[ ! -e $ARCHIVE && ! -L $ARCHIVE && ! -e $DIGEST && ! -L $DIGEST ]] || {
  echo "release refused: output already exists" >&2
  exit 4
}

STAGE=$(mktemp -d)
cleanup() {
  [[ -n ${STAGE:-} && -d $STAGE ]] && rm -rf -- "$STAGE"
}
trap cleanup EXIT HUP INT TERM

mkdir -p "$STAGE/$NAME" "$DIST"
git archive --format=tar HEAD | tar -xf - -C "$STAGE/$NAME"

(
  cd "$STAGE/$NAME"
  find . -type f ! -name MANIFEST.sha256 -print0 \
    | LC_ALL=C sort -z \
    | xargs -0 sha256sum > MANIFEST.sha256
)

SOURCE_DATE_EPOCH=$(git log -1 --format=%ct HEAD)
tar \
  --sort=name \
  --mtime="@$SOURCE_DATE_EPOCH" \
  --owner=0 --group=0 --numeric-owner \
  --format=posix \
  -C "$STAGE" -cf - "$NAME" \
  | gzip -n > "$ARCHIVE"

(
  cd "$DIST"
  sha256sum "$(basename "$ARCHIVE")" > "$(basename "$DIGEST")"
)

echo "release_archive=$ARCHIVE"
echo "release_digest=$DIGEST"
