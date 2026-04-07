#!/bin/sh
set -e

# $1 == 0 on uninstall, $1 == 1 on upgrade. Only act on full removal.
if [ "${1:-0}" = "0" ]; then
    systemctl --no-reload disable --now teleproxy.service >/dev/null 2>&1 || :
fi
exit 0
