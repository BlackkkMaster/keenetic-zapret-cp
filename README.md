# Копирование и выдача разрешений для установки zapret на роутеры Keenetic

[**Оригинальная статья по установке**](https://habr.com/ru/articles/834826/)

## *Актуально для [zapret v71.4](https://github.com/bol-van/zapret/releases/tag/v71.4)*

## Использование

**Данная инструкция предполагает, что у вас уже установлена** [**Entware**](https://help.keenetic.com/hc/ru/articles/360021214160-%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0-%D1%81%D0%B8%D1%81%D1%82%D0%B5%D0%BC%D1%8B-%D0%BF%D0%B0%D0%BA%D0%B5%D1%82%D0%BE%D0%B2-%D1%80%D0%B5%D0%BF%D0%BE%D0%B7%D0%B8%D1%82%D0%BE%D1%80%D0%B8%D1%8F-Entware-%D0%BD%D0%B0-USB-%D0%BD%D0%B0%D0%BA%D0%BE%D0%BF%D0%B8%D1%82%D0%B5%D0%BB%D1%8C)

### 1. Установка компонентов

```bash
opkg update
opkg install coreutils-sort curl grep gzip ipset iptables kmod_ndms xtables-addons_legacy git git-http
```

### 2. Скачивание и установка zapret

```bash
cd /opt
curl -L https://github.com/bol-van/zapret/releases/download/v71.4/zapret-v71.4.tar.gz > zapret.tar.gz
tar -xvzf zapret.tar.gz
mv zapret-v71.4 zapret
rm zapret.tar.gz
cd zapret
./install_easy.sh
```

В установке рекомендую отвечать как в оригинальной статье

### 3. Настройка параметров и копирование файлов

```bash
git clone https://github.com/BlackkkMaster/keenetic-zapret-cp ~/keenetic-zapret-cp
cd ~/keenetic-zapret-cp
./install.sh -p cfg/paths.txt # -i имя_сетевого_интерфейса
```

Дополнительно в скрипт можно передать аргумент `-i имя_сетевого_интерфейса` чтобы заменить параметр `IFACE_WAN=` в конфиге.
(он указан выше, нужно убрать # и вместо имя_сетевого_интерфейса написапть свой интерфейс)

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