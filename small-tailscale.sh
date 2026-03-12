#!/bin/sh
# Установка Tailscale на OpenWrt (Cudy TR30)
# https://github.com/vasneverov/cudy-tr-tailscale

ARCH=$(opkg print-architecture | awk 'NF==3 && $3~/^[0-9]+$/ {print $2}' | tail -1)
VERSION="1.92.5"
IPK_URL="https://github.com/GuNanOvO/openwrt-tailscale/releases/download/v${VERSION}/tailscale_${VERSION}_${ARCH}.ipk"

echo "=== [1/4] Установка Tailscale v${VERSION} для ${ARCH} ==="
wget -O /tmp/tailscale.ipk "$IPK_URL"
opkg install /tmp/tailscale.ipk
rm /tmp/tailscale.ipk

echo "=== [2/4] Запуск демона ==="
GW=$(ip route show default | awk '/default/ {print $3; exit}')
DEV=$(ip route show default | awk '/default/ {print $5; exit}')
ip route add 192.200.0.0/24 via $GW dev $DEV 2>/dev/null
nft insert rule inet PodkopTable mangle_output ip daddr 192.200.0.0/24 return 2>/dev/null
nft insert rule inet PodkopTable mangle ip daddr 192.200.0.0/24 return 2>/dev/null
killall tailscaled 2>/dev/null
rm -f /var/run/tailscale/tailscaled.sock
sleep 2
mkdir -p /etc/tailscale /var/run/tailscale
/usr/sbin/tailscaled --port 41641 --state /etc/tailscale/tailscaled.state &
sleep 5

echo "=== [3/4] АВТОРИЗАЦИЯ ==="
tailscale up --accept-dns=false --accept-routes --reset --hostname=$(cat /proc/sys/kernel/hostname)

echo "=== [4/4] Настройка ==="
tailscale serve --bg --tcp 80  tcp://localhost:80
tailscale serve --bg --tcp 443 tcp://localhost:443
tailscale serve --bg --tcp 22  tcp://localhost:22

cat > /etc/rc.local << 'RCEOF'
#!/bin/sh
(sleep 15
GW=$(ip route show default | awk '/default/ {print $3; exit}')
DEV=$(ip route show default | awk '/default/ {print $5; exit}')
ip route add 192.200.0.0/24 via $GW dev $DEV 2>/dev/null
nft insert rule inet PodkopTable mangle_output ip daddr 192.200.0.0/24 return 2>/dev/null
nft insert rule inet PodkopTable mangle ip daddr 192.200.0.0/24 return 2>/dev/null
tailscale serve --bg --tcp 80  tcp://localhost:80
tailscale serve --bg --tcp 22  tcp://localhost:22
tailscale serve --bg --tcp 443 tcp://localhost:443) &
exit 0
RCEOF
chmod +x /etc/rc.local

echo "Готово!"
tailscale status
