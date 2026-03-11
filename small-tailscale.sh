#!/bin/sh
# =============================================================
# small-tailscale.sh — универсальная установка Tailscale
# Работает на любом OpenWrt роутере с podkop: Cudy TR30, Xiaomi AX3000T и др.
# https://github.com/vasneverov/cudy-tr-tailscale
# =============================================================

ARCH=$(opkg print-architecture | awk 'NF==3 && $3~/^[0-9]+$/ {print $2}' | tail -1)
VERSION="1.92.5"
IPK_URL="https://github.com/GuNanOvO/openwrt-tailscale/releases/download/v${VERSION}/tailscale_${VERSION}_${ARCH}.ipk"

echo "=== [0/5] Очистка предыдущей установки ==="
/etc/init.d/tailscale stop 2>/dev/null
killall tailscaled 2>/dev/null
sleep 3
opkg remove tailscale --force-removal-of-dependent-packages 2>/dev/null
rm -rf /var/lib/tailscale /etc/tailscale /var/run/tailscale 2>/dev/null

echo "=== [1/5] Установка Tailscale v${VERSION} для ${ARCH} ==="
wget -O /tmp/tailscale.ipk "$IPK_URL"
opkg install /tmp/tailscale.ipk
rm /tmp/tailscale.ipk

echo "=== [2/5] Обходим podkop для трафика роутера ==="
GW=$(ip route show default | awk '/default/ {print $3; exit}')
DEV=$(ip route show default | awk '/default/ {print $5; exit}')
ip route add 192.200.0.0/24 via $GW dev $DEV 2>/dev/null
ip rule add to 192.200.0.0/24 priority 40 lookup main 2>/dev/null
ip rule add priority 50 not fwmark 0x100000 lookup main 2>/dev/null
echo "Маршрут: 192.200.0.0/24 via $GW dev $DEV"
echo "Проверка: $(ip route get 192.200.0.1 2>/dev/null)"

echo "=== [3/5] Запуск демона ==="
# Убиваем всё что могло остаться после opkg install
killall tailscaled 2>/dev/null
rm -f /var/run/tailscale/tailscaled.sock
sleep 2
mkdir -p /etc/tailscale /var/run/tailscale
/usr/sbin/tailscaled --port 41641 --state /etc/tailscale/tailscaled.state > /tmp/tailscaled.log 2>&1 &
TAILSCALED_PID=$!
echo "tailscaled PID: $TAILSCALED_PID"
sleep 5

# Проверяем что демон живой
if ! kill -0 $TAILSCALED_PID 2>/dev/null; then
  echo "ОШИБКА: tailscaled упал. Лог:"
  cat /tmp/tailscaled.log | tail -5
  exit 1
fi
echo "Демон запущен, сокет: $(ls /var/run/tailscale/)"

echo "=== [4/5] АВТОРИЗАЦИЯ ==="
echo "Открой ссылку ниже в браузере и подтверди подключение:"
tailscale up --accept-dns=false --accept-routes --reset \
  --hostname=$(cat /proc/sys/kernel/hostname)

echo "=== [5/5] Финальные настройки ==="
tailscale serve --bg --tcp 80  tcp://localhost:80
tailscale serve --bg --tcp 443 tcp://localhost:443
tailscale serve --bg --tcp 22  tcp://localhost:22

cat > /etc/rc.local << 'RCEOF'
#!/bin/sh
(sleep 15
GW=$(ip route show default | awk '/default/ {print $3; exit}')
DEV=$(ip route show default | awk '/default/ {print $5; exit}')
ip route add 192.200.0.0/24 via $GW dev $DEV 2>/dev/null
ip rule add to 192.200.0.0/24 priority 40 lookup main 2>/dev/null
ip rule add priority 50 not fwmark 0x100000 lookup main 2>/dev/null
tailscale serve --bg --tcp 80  tcp://localhost:80
tailscale serve --bg --tcp 22  tcp://localhost:22
tailscale serve --bg --tcp 443 tcp://localhost:443) &
exit 0
RCEOF
chmod +x /etc/rc.local

echo ""
echo "Готово! Статус:"
tailscale status
