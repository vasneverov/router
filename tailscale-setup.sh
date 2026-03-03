#!/bin/sh

# === 1. Установка Tailscale из компактного репозитория ===
wget -O /tmp/key-build.pub https://gunanovo.github.io/openwrt-tailscale/key-build.pub
opkg-key add /tmp/key-build.pub
rm /tmp/key-build.pub
echo "src/gz openwrt-tailscale https://gunanovo.github.io/openwrt-tailscale/$(opkg print-architecture | awk 'NF==3 && $3~/^[0-9]+$/ {print $2}' | tail -1)" >> /etc/opkg/customfeeds.conf
opkg update && opkg install tailscale

# === 2. Продувка ===
/etc/init.d/tailscale stop
rm -rf /var/lib/tailscale/tailscaled.state
sed -i 's/TS_DEBUG_FIREWALL_MODE=".*"/TS_DEBUG_FIREWALL_MODE="none" GOGC=10 GOMEMLIMIT=128MiB/' /etc/init.d/tailscale
sed -i '/procd_set_param command/d' /etc/init.d/tailscale
sed -i '/procd_open_instance/a \ \ \ \ \ \ \ \ procd_set_param command /usr/sbin/tailscaled --tun=userspace-networking --statedir=/var/lib/tailscale --port=41641' /etc/init.d/tailscale
cat > /etc/rc.local << 'RCEOF'
#!/bin/sh
(sleep 15; tailscale up --accept-dns=false --accept-routes; sleep 5; tailscale serve --bg --tcp 80 tcp://localhost:80; tailscale serve --bg --tcp 22 tcp://localhost:22; tailscale serve --bg --tcp 443 tcp://localhost:443) &
exit 0
RCEOF
chmod +x /etc/rc.local

# === 3. Запуск и авторизация ===
/etc/init.d/tailscale restart; sleep 8; tailscale up --accept-dns=false --accept-routes
