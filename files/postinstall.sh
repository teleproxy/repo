#!/bin/sh
set -e

# Create system user/group
getent group teleproxy >/dev/null || groupadd --system teleproxy
getent passwd teleproxy >/dev/null || \
    useradd --system --gid teleproxy --home-dir /etc/teleproxy \
            --shell /sbin/nologin --comment "Teleproxy daemon" teleproxy

# Lock down config dir
chown root:teleproxy /etc/teleproxy 2>/dev/null || :
chmod 0750 /etc/teleproxy 2>/dev/null || :

# First-install secret randomization (skip if user already has a config)
CONF=/etc/teleproxy/config.toml
if [ ! -f "$CONF" ]; then
    SECRET=$(/usr/bin/teleproxy generate-secret 2>/dev/null || \
             head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')
    cat > "$CONF" <<EOF
# Teleproxy configuration. Edit and run: systemctl reload teleproxy
# Generated on first install; not overwritten on upgrade.
port = 443
stats_port = 8888
http_stats = true
user = "teleproxy"
direct = true
workers = 1

[[secret]]
key = "$SECRET"
label = "default"
EOF
    chmod 0640 "$CONF"
    chown root:teleproxy "$CONF"

    cat <<BANNER
----------------------------------------------------------------------
Teleproxy installed. A random secret was generated.
View it with:   teleproxy link --server <YOUR_IP> --port 443 --secret $SECRET
Edit config:    /etc/teleproxy/config.toml
Start service:  systemctl enable --now teleproxy
----------------------------------------------------------------------
BANNER
fi

systemctl daemon-reload >/dev/null 2>&1 || :
systemctl preset teleproxy.service >/dev/null 2>&1 || :
exit 0
