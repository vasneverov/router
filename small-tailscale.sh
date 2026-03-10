#!/bin/sh
# =============================================================
# small-tailscale.sh
# Установка Tailscale для OpenWrt роутеров с малой памятью
# Совместимость: OpenWrt + podkop (GuNanOvO репозиторий)
# https://github.com/vasneverov/router
# =============================================================

ARCH=$(opkg print-architecture | awk 'NF==3 && $3~/^[0-9]+$/ {print $2}' | tail -1)
VERSION="1.92.5"
IPK_URL="https://github.com/GuNanOvO/openwrt-tailscale/releases/download/v${VERSION}/tailscale_${VERSION}_${ARCH}.ipk"

echo "=== [1/4] Установка Tailscale v${VERSION} для ${ARCH} ==="
wget -O /tmp/tailscale.ipk "$IPK_URL"
opkg install /tmp/tailscale.ipk
rm /tmp/tailscale.ipk

echo "=== [2/4] Запуск демона ==="
/etc/init.d/tailscale start
sleep 3

echo "=== [3/4] АВТОРИЗАЦИЯ ==="
echo "Открой ссылку ниже в браузере и подтверди подключение:"
tailscale up --accept-dns=false --accept-routes --reset \
  --hostname=$(cat /proc/sys/kernel/hostname)

echo "=== [4/4] Применяем фиксы ==="
GW=$(ip route show default | awk '/default/ {print $3; exit}')
DEV=$(ip route show default | awk '/default/ {print $5; exit}')
ip route add 192.200.0.0/24 via $GW dev $DEV 2>/dev/null

tailscale serve --bg --tcp 80  tcp://localhost:80
tailscale serve --bg --tcp 443 tcp://localhost:443
tailscale serve --bg --tcp 22  tcp://localhost:22

cat > /etc/rc.local << 'RCEOF'
#!/bin/sh
(sleep 15
ip route add 192.200.0.0/24 via $(ip route show default | awk '/default/ {print $3; exit}') dev $(ip route show default | awk '/default/ {print $5; exit}') 2>/dev/null
tailscale serve --bg --tcp 80  tcp://localhost:80
tailscale serve --bg --tcp 22  tcp://localhost:22
tailscale serve --bg --tcp 443 tcp://localhost:443) &
exit 0
RCEOF
chmod +x /etc/rc.local

echo ""
echo "Готово! Статус:"
tailscale status
