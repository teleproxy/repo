#!/bin/sh
# Build the teleproxy RPM for both architectures.
#
# Inputs (env):
#   VERSION           - upstream tag without leading 'v' (e.g. 4.2.1)
#   SIGNING_KEY_FILE  - path to ASCII-armored private signing key
#
# Inputs (filesystem):
#   ./bin/teleproxy-amd64
#   ./bin/teleproxy-arm64
#
# Output:
#   ./out/teleproxy-${VERSION}-1.x86_64.rpm
#   ./out/teleproxy-${VERSION}-1.aarch64.rpm
set -eu

: "${VERSION:?VERSION must be set (e.g. 4.2.1)}"
: "${SIGNING_KEY_FILE:?SIGNING_KEY_FILE must be set}"

[ -f bin/teleproxy-amd64 ] || { echo "missing bin/teleproxy-amd64" >&2; exit 1; }
[ -f bin/teleproxy-arm64 ] || { echo "missing bin/teleproxy-arm64" >&2; exit 1; }

mkdir -p out

# nfpm only expands env vars in metadata fields (version, maintainer, etc.),
# not in contents.src/dst. Use envsubst to render a per-arch config.
for ARCH in amd64 arm64; do
    export ARCH VERSION SIGNING_KEY_FILE
    RENDERED=$(mktemp)
    envsubst '${ARCH} ${VERSION} ${SIGNING_KEY_FILE}' \
        < nfpm/teleproxy.yaml > "$RENDERED"
    nfpm package \
        --packager rpm \
        --config "$RENDERED" \
        --target out/
    rm -f "$RENDERED"
done

ls -la out/
