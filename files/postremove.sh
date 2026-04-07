#!/bin/sh
set -e

# $1 == 0 on uninstall, $1 == 1 on upgrade. On upgrade, restart the service.
if [ "${1:-0}" = "1" ]; then
    systemctl daemon-reload >/dev/null 2>&1 || :
    systemctl try-restart teleproxy.service >/dev/null 2>&1 || :
elif [ "${1:-0}" = "0" ]; then
    systemctl daemon-reload >/dev/null 2>&1 || :
fi
exit 0
