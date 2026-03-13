# Tailscale на OpenWrt с podkop

Универсальный скрипт установки Tailscale на роутеры OpenWrt с podkop.

Использует облегчённую сборку Tailscale ([gunanovo/openwrt-tailscale](https://github.com/gunanovo/openwrt-tailscale)) — сжатую UPX-версию специально для роутеров с ограниченной памятью (~16–128 МБ). Стандартный пакет из репозитория OpenWrt на таких устройствах не помещается.

**Проверено на:** Cudy WR3000S, Cudy TR30 (OpenWrt 24.10.x)

## Установка

```sh
wget -O /tmp/s.sh https://raw.githubusercontent.com/vasneverov/cudy-tr-tailscale/main/small-tailscale.sh && sh /tmp/s.sh
```

Скрипт:
1. Добавляет репозиторий с компактной сборкой Tailscale и устанавливает её
2. Применяет nft/ip rule чтобы трафик к Tailscale controlplane не уходил через podkop
3. Запускает `tailscale up` — открываешь ссылку в браузере и авторизуешься
4. Настраивает serve на порты 80, 443, 22
5. Прописывает rc.local для автозапуска после перезагрузки

## Удаление

```sh
/etc/init.d/tailscale stop 2>/dev/null; killall tailscaled 2>/dev/null; sleep 2; opkg remove tailscale --force-removal-of-dependent-packages 2>/dev/null; rm -rf /var/lib/tailscale /etc/tailscale /var/run/tailscale /etc/rc.local; echo "Чисто"
```

## Как это работает

podkop маркирует трафик через nftables и отправляет его в свой туннель. Без правок трафик к `controlplane.tailscale.com` (192.200.0.0/24) тоже попадает в podkop, из-за чего `tailscale up` зависает.

Скрипт добавляет:
- `nft insert rule` с `return` — исключает 192.200.0.0/24 из цепочек podkop
- `ip rule add to 192.200.0.0/24 priority 50 lookup main` — форсирует маршрутизацию через main таблицу

Оба правила также прописываются в rc.local и применяются при каждой загрузке.
