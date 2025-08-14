# Копирование и выдача разрешений для установки zapret на роутеры Keenetic

[**Оригинальная статья по установке**](https://habr.com/ru/articles/834826/)

## *Актуально для [zapret v71.3](https://github.com/bol-van/zapret/releases/tag/v71.3)*

## Использование

### 1. Установка компонентов

```bash
opkg update
opkg install coreutils-sort curl grep gzip ipset iptables kmod_ndms xtables-addons_legacy git git-http
```

### 2. Скачивание и установка zapret

```bash
cd /opt
curl -L https://github.com/bol-van/zapret/releases/download/v71.3/zapret-v71.3.tar.gz > zapret.tar.gz
tar -xvzf zapret.tar.gz
mv zapret-v71.3 zapret
rm zapret.tar.gz
cd zapret
./install_easy.sh
```

### 3. Настройка параметров и копирование файлов

```bash
git clone https://github.com/BlackkkMaster/keenetic-zapret-cp ~/keenetic-zapret-cp
cd ~/keenetic-zapret-cp
./install.sh -p cfg/paths.txt # -i имя_сетевого_интерфейса
```

Дополнительно в скрипт можно передать аргумент `-i имя_сетевого_интерфейса` чтобы заменить параметр `IFACE_WAN=` в конфиге.

Узнать нужный сетевой интерфейс можно командой `ifconfig`

<details><summary><h3>Запуск/перезапуск/остановка zapret</h3></summary>

**Запуск:**

```bash
/opt/zapret/init.d/sysv/zapret start
```

**Перезапуск:**

```bash
/opt/zapret/init.d/sysv/zapret restart
```

**Остановка:**

```bash
/opt/zapret/init.d/sysv/zapret stop
```

</details>