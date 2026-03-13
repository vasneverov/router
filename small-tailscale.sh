#!/bin/sh
# Установка Tailscale на OpenWrt с podkop (Cudy WR3000S, TR30 и др.)
# https://github.com/vasneverov/cudy-tr-tailscale

ARCH=$(opkg print-architecture | awk 'NF==3 && $3~/^[0-9]+$/ {print $2}' | tail -1)

echo "=== [1/3] Установка Tailscale ==="
grep -v "openwrt-tailscale" /etc/opkg/customfeeds.conf > /tmp/feeds.tmp
mv /tmp/feeds.tmp /etc/opkg/customfeeds.conf
wget -O /tmp/key-build.pub https://gunanovo.github.io/openwrt-tailscale/key-build.pub
opkg-key add /tmp/key-build.pub
rm /tmp/key-build.pub
echo "src/gz openwrt-tailscale https://gunanovo.github.io/openwrt-tailscale/${ARCH}" >> /etc/opkg/customfeeds.conf
opkg update
opkg install tailscale

echo "=== [2/3] АВТОРИЗАЦИЯ ==="
echo "Открой ссылку в браузере и подтверди. После Success скрипт продолжится."
nft insert rule inet PodkopTable mangle_output ip daddr 192.200.0.0/24 return 2>/dev/null
nft insert rule inet PodkopTable mangle ip daddr 192.200.0.0/24 return 2>/dev/null
ip rule add to 192.200.0.0/24 priority 50 lookup main 2>/dev/null
/etc/init.d/tailscale stop 2>/dev/null
killall tailscaled 2>/dev/null
sleep 3
rm -f /var/run/tailscale/tailscaled.sock
/etc/init.d/tailscale start
sleep 8
tailscale up --accept-dns=false --accept-routes --reset --hostname=$(cat /proc/sys/kernel/hostname) && \
tailscale serve --bg --tcp 80  tcp://localhost:80 && \
tailscale serve --bg --tcp 443 tcp://localhost:443 && \
tailscale serve --bg --tcp 22  tcp://localhost:22

echo "=== [3/3] rc.local ==="
cat > /etc/rc.local << 'RCEOF'
#!/bin/sh
(sleep 15
nft insert rule inet PodkopTable mangle_output ip daddr 192.200.0.0/24 return 2>/dev/null
nft insert rule inet PodkopTable mangle ip daddr 192.200.0.0/24 return 2>/dev/null
ip rule add to 192.200.0.0/24 priority 50 lookup main 2>/dev/null
tailscale serve --bg --tcp 80  tcp://localhost:80
tailscale serve --bg --tcp 22  tcp://localhost:22
tailscale serve --bg --tcp 443 tcp://localhost:443) &
exit 0
RCEOF
chmod +x /etc/rc.local
echo "Готово!"
tailscale status
