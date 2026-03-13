#!/bin/sh
# Шаг 2 из 2: Авторизация и настройка портов Tailscale
# https://github.com/vasneverov/cudy-tr-tailscale
#
# Запусти эту команду ПОСЛЕ install.sh:
#   wget -O /tmp/setup.sh https://raw.githubusercontent.com/vasneverov/cudy-tr-tailscale/main/setup.sh && sh /tmp/setup.sh
#
# ВНИМАНИЕ: После перехода по ссылке авторизации SSH-соединение может оборваться.
# Это нормально! Подожди 30 секунд, переподключись и снова запусти этот скрипт.
# Tailscale уже будет авторизован и скрипт сразу настроит порты.

echo "=== [2/2] Авторизация и настройка Tailscale ==="
echo ""
echo ">>> Сейчас появится ссылка. Перейди по ней для авторизации. <<<"
echo ">>> Если SSH оборвётся — переподключись и запусти скрипт снова. <<<"
echo ""

tailscale up --accept-dns=false --accept-routes --reset

echo ""
echo ">>> Авторизация прошла! Настраиваю порты... <<<"
echo ""

tailscale serve --bg --tcp 80  tcp://localhost:80
tailscale serve --bg --tcp 443 tcp://localhost:443
tailscale serve --bg --tcp 22  tcp://localhost:22
tailscale serve status

# Записываем rc.local с увеличенным sleep чтобы tailscaled успел подняться
printf '#!/bin/sh\n(sleep 30; tailscale serve --bg --tcp 80 tcp://localhost:80; tailscale serve --bg --tcp 22 tcp://localhost:22; tailscale serve --bg --tcp 443 tcp://localhost:443) &\nexit 0\n' > /etc/rc.local
chmod +x /etc/rc.local

echo ""
echo "=== Готово! Tailscale установлен и настроен. ==="
echo "=== После перезагрузки Tailscale поднимется автоматически через ~40 секунд. ==="
