# Tailscale на OpenWrt — Cudy WR3000S / TR30

Скрипт автоматической установки и настройки Tailscale на роутеры **Cudy WR3000S** и **Cudy TR30** под управлением OpenWrt 24.10.x.

Проверено на 100+ роутерах в реальных условиях эксплуатации в России.

## Что делает скрипт

1. Определяет архитектуру роутера автоматически
2. Устанавливает облегчённую UPX-сборку Tailscale от [GuNanOvO/openwrt-tailscale](https://github.com/GuNanOvO/openwrt-tailscale) — специально для роутеров с малым объёмом памяти (~16–128 МБ)
3. Прописывает `/etc/init.d/tailscale` с режимом `--tun=userspace-networking` и `TS_DEBUG_FIREWALL_MODE=none` — это ключевое условие стабильной работы на Cudy WR3000S/TR30
4. Прописывает `/etc/rc.local` с автозапуском Tailscale и serve-портами после перезагрузки
5. Запускает авторизацию — появляется ссылка, переходишь, нажимаешь подтвердить
6. Прописывает serve-порты 80, 443, 22 для удалённого доступа к роутеру через Tailscale

## Почему userspace-networking?

На роутерах Cudy WR3000S и TR30 (OpenWrt 24.10.x, nftables) стандартный режим Tailscale конфликтует с сетевым стеком. Это проявляется так:

- Tailscale поднимается, точка зеленеет
- Через 20–90 секунд точка гаснет
- В логах: `control: map response long-poll timed out!`
- При этом интернет работает, подкоп работает — только Tailscale падает

**Решение:** запускать `tailscaled` с флагом `--tun=userspace-networking` и `TS_DEBUG_FIREWALL_MODE=none`. В этом режиме Tailscale не трогает ядро и nftables, работает полностью в userspace. Соединение держится стабильно.

## Установка

Подключись к роутеру по SSH и выполни одну команду:

```sh
wget -O /tmp/setup.sh https://raw.githubusercontent.com/vasneverov/cudy-tr-tailscale/main/setup.sh && sh /tmp/setup.sh
```

Скрипт установит Tailscale, настроит автозапуск и покажет ссылку для авторизации.

После появления ссылки:
1. Перейди по ссылке в браузере
2. Авторизуй устройство в своём Tailscale аккаунте
3. SSH-соединение может оборваться — это нормально
4. Переподключись по SSH и убедись что точка зелёная

## Проверено на

- Cudy WR3000S (aarch64_cortex-a53, OpenWrt 24.10.5)
- Cudy TR30 (aarch64_cortex-a53, OpenWrt 24.10.4)

## Файлы

- `setup.sh` — полная установка, настройка и авторизация (один скрипт, всё включено)
- `install.sh` — только установка пакета (без авторизации)

## Лицензия

MIT
