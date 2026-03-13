#!/bin/sh
# =============================================================
# Tailscale setup for Cudy WR3000S / TR30 (OpenWrt)
# https://github.com/vasneverov/cudy-tr-tailscale
# =============================================================

ARCH=$(opkg print-architecture | awk 'NF==3 && $3~/^[0-9]+$/ {print $2}' | tail -1)
VERSION="1.96.0"
IPK_URL="https://github.com/GuNanOvO/openwrt-tailscale/releases/download/v${VERSION}/tailscale_${VERSION}_${ARCH}.ipk"

echo ">>> Arch: $ARCH"
echo ">>> Installing Tailscale $VERSION..."
opkg remove tailscale 2>/dev/null || true
wget -O /tmp/tailscale.ipk "$IPK_URL" && opkg install /tmp/tailscale.ipk
rm -f /tmp/tailscale.ipk

echo ">>> Writing /etc/init.d/tailscale..."
cat > /etc/init.d/tailscale << 'ENDINIT'
#!/bin/sh /etc/rc.common
# Copyright 2020 Google LLC.
# SPDX-License-Identifier: Apache-2.0
USE_PROCD=1
START=80
start_service() {
  local state_file
  local port
  local std_err std_out
  config_load tailscale
  config_get_bool std_out "settings" log_stdout 1
  config_get_bool std_err "settings" log_stderr 1
  config_get port "settings" port 41641
  config_get state_file "settings" state_file /etc/tailscale/tailscaled.state
  config_get fw_mode "settings" fw_mode nftables
  /usr/sbin/tailscaled --cleanup
  procd_open_instance
        procd_set_param command /usr/sbin/tailscaled --tun=userspace-networking --statedir=/var/lib/tailscale --port=41641
  procd_set_param env TS_DEBUG_FIREWALL_MODE="none" GOGC=10 GOMEMLIMIT=128MiB
  procd_append_param command --port "$port"
  procd_append_param command --state "$state_file"
  procd_set_param respawn
  procd_set_param stdout "$std_out"
  procd_set_param stderr "$std_err"
  procd_close_instance
}
stop_service() {
  /usr/sbin/tailscaled --cleanup
}
ENDINIT
chmod +x /etc/init.d/tailscale

echo ">>> Writing /etc/rc.local..."
cat > /etc/rc.local << 'ENDRC'
#!/bin/sh
(sleep 15; tailscale up --accept-dns=false --accept-routes; sleep 5; tailscale serve --bg --tcp 80 tcp://localhost:80; tailscale serve --bg --tcp 22 tcp://localhost:22; tailscale serve --bg --tcp 443 tcp://localhost:443) &
exit 0
ENDRC
chmod +x /etc/rc.local

echo ">>> Installing watchdog..."
cat > /usr/bin/tailscale-watchdog.sh << 'ENDWD'
#!/bin/sh
STATUS=$(tailscale status 2>&1 | grep -c "100\.")
if [ "$STATUS" -eq "0" ]; then
  logger -t tailscale-watchdog "Tailscale is down, restarting..."
  tailscale up --accept-dns=false --accept-routes
fi
ENDWD
chmod +x /usr/bin/tailscale-watchdog.sh
echo "* * * * * /usr/bin/tailscale-watchdog.sh" >> /etc/crontabs/root
/etc/init.d/cron enable
/etc/init.d/cron restart
echo ">>> Watchdog installed. Checks every minute."

echo ">>> Starting tailscaled..."
/etc/init.d/tailscale restart
sleep 8

echo ">>> Authorizing Tailscale..."
echo ">>> Follow the auth URL. SSH may disconnect - that is normal!"
tailscale up --accept-dns=false --accept-routes

echo ">>> Setting up serve ports..."
tailscale serve --bg --tcp 80 tcp://localhost:80
tailscale serve --bg --tcp 443 tcp://localhost:443
tailscale serve --bg --tcp 22 tcp://localhost:22
echo ">>> Done! Tailscale is ready."
tailscale serve status
