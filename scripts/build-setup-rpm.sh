#!/bin/sh
# Build the noarch teleproxy-release setup RPM.
#
# Inputs (env):
#   SIGNING_KEY_FILE  - path to ASCII-armored private signing key
#
# Output:
#   ./out/teleproxy-release-1-1.noarch.rpm
set -eu

: "${SIGNING_KEY_FILE:?SIGNING_KEY_FILE must be set}"

[ -f RPM-GPG-KEY-teleproxy ] || { echo "missing RPM-GPG-KEY-teleproxy" >&2; exit 1; }
[ -f files/teleproxy.repo ] || { echo "missing files/teleproxy.repo" >&2; exit 1; }

mkdir -p out

export SIGNING_KEY_FILE
nfpm package \
    --packager rpm \
    --config nfpm/teleproxy-release.yaml \
    --target out/

ls -la out/teleproxy-release-*.rpm
