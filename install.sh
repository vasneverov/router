#!/bin/sh
# Шаг 1 из 2: Установка Tailscale
# https://github.com/vasneverov/cudy-tr-tailscale
#
# Запусти эту команду:
#   wget -O /tmp/install.sh https://raw.githubusercontent.com/vasneverov/cudy-tr-tailscale/main/install.sh && sh /tmp/install.sh
#
# После установки выполни авторизацию:
#   wget -O /tmp/setup.sh https://raw.githubusercontent.com/vasneverov/cudy-tr-tailscale/main/setup.sh && sh /tmp/setup.sh

echo "=== [1/2] Установка Tailscale ==="

echo "[1/4] Очистка дублей репозитория..."
grep -v "openwrt-tailscale" /etc/opkg/customfeeds.conf > /tmp/feeds.tmp
mv /tmp/feeds.tmp /etc/opkg/customfeeds.conf

echo "[2/4] Добавление ключа..."
wget -O /tmp/key-build.pub https://gunanovo.github.io/openwrt-tailscale/key-build.pub || { echo "ERROR: не удалось скачать ключ"; exit 1; }
opkg-key add /tmp/key-build.pub
rm /tmp/key-build.pub

echo "[3/4] Добавление репозитория..."
ARCH=$(opkg print-architecture | awk 'NF==3 && $3~/^[0-9]+$/ {print $2}' | tail -1)
echo "Архитектура: $ARCH"
echo "src/gz openwrt-tailscale https://gunanovo.github.io/openwrt-tailscale/$ARCH" >> /etc/opkg/customfeeds.conf

echo "[4/4] Установка пакета..."
opkg update || { echo "ERROR: opkg update failed"; exit 1; }
opkg install tailscale || { echo "ERROR: install failed"; exit 1; }

echo ""
echo "=== Tailscale установлен! ==="
echo ""
echo ">>> Теперь выполни шаг 2 — авторизацию: <<<"
echo "wget -O /tmp/setup.sh https://raw.githubusercontent.com/vasneverov/cudy-tr-tailscale/main/setup.sh && sh /tmp/setup.sh"
echo ""
