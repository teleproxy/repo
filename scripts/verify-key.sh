#!/bin/sh
# Hard gate: fail the build if the signing key contains any SHA-1 digests.
# RHEL 9+ rpm-sequoia rejects keys with SHA-1 self-signatures or subkey
# binding signatures, even if the actual RPM signature uses SHA-256.
#
# Usage: verify-key.sh <keyid-or-uid>
set -e

KEY="${1:-Teleproxy}"

if [ -z "${GNUPGHOME:-}" ]; then
    echo "verify-key.sh: GNUPGHOME must be set" >&2
    exit 2
fi

# Every "digest algo N" line must report 8 (SHA256), 9 (SHA384) or
# 10 (SHA512). Anything else (especially 2 = SHA1) is a hard fail.
# The line looks like: "\tdigest algo 10, begin of digest 00 4d"
# Strip everything but the number after "digest algo".
ALGOS=$(gpg --export "$KEY" | gpg --list-packets 2>/dev/null \
    | sed -n 's/.*digest algo \([0-9][0-9]*\).*/\1/p' \
    | sort -u)

if [ -z "$ALGOS" ]; then
    echo "verify-key.sh: no signature digests found for $KEY" >&2
    exit 2
fi

BAD=""
for algo in $ALGOS; do
    case "$algo" in
        8|9|10) ;;
        *) BAD="$BAD $algo" ;;
    esac
done

if [ -n "$BAD" ]; then
    echo "verify-key.sh: signing key has weak digest algos:$BAD" >&2
    echo "(allowed: 8=SHA256, 9=SHA384, 10=SHA512)" >&2
    echo "RHEL 9 rpm-sequoia will reject this key." >&2
    exit 1
fi

echo "verify-key.sh: OK ($KEY uses SHA-256+ everywhere; algos:$ALGOS)" \
    | tr '\n' ' '
echo
