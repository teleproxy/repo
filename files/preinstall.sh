#!/bin/sh
set -e

# Create the system user/group BEFORE the package files are extracted,
# so the directory ownership in the rpm metadata can be applied without
# falling back to root. Idempotent across upgrades.
getent group teleproxy >/dev/null || groupadd --system teleproxy
getent passwd teleproxy >/dev/null || \
    useradd --system --gid teleproxy --home-dir /etc/teleproxy \
            --shell /sbin/nologin --comment "Teleproxy daemon" teleproxy
exit 0
