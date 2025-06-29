#!/bin/sh

# Путь к файлу конфигурации zapret
CONFIG_FILE="/opt/zapret/config"
# Путь к файлу, содержащему новые параметры NFQWS_OPT
NEW_OPT_FILE="./nfqws_opt.txt"
# Путь для резервной копии оригинального файла конфигурации
BACKUP_FILE="${CONFIG_FILE}.bak"

# Переменные для хранения аргументов
MAPPING_FILE=""
NETWORK_INTERFACE="" # Изначально пустая, так как параметр опциональный

# Парсинг аргументов командной строки
while getopts "p:i:" opt; do
    case ${opt} in
        p )
            MAPPING_FILE=$OPTARG
            ;;
        i )
            NETWORK_INTERFACE=$OPTARG # Устанавливаем только если -i предоставлен
            ;;
        \? )
            echo "Использование: $0 -p <файл_со_списком_копирования> [-i <имя_сетевого_интерфейса>]"
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

# Проверяем, что ОБЯЗАТЕЛЬНЫЙ аргумент (-p) был передан
if [ -z "$MAPPING_FILE" ]; then
    echo "Ошибка: Файл со списком копирования не указан."
    echo "Использование: $0 -p <файл_со_списком_копирования> [-i <имя_сетевого_интерфейса>]"
    exit 1
fi

# Проверяем, существует ли файл со списком копирования
if [ ! -f "$MAPPING_FILE" ]; then
    echo "Ошибка: Файл со списком копирования '$MAPPING_FILE' не найден."
    exit 1
fi

echo "Начинаем копирование файлов..."

# Читаем файл со списком копирования построчно
while IFS='=' read -r source_path dest_path; do
    # Удаляем пробелы в начале и конце строк
    source_path=$(echo "$source_path" | xargs)
    dest_path=$(echo "$dest_path" | xargs)

    # Пропускаем пустые строки или строки-комментарии (начинающиеся с #)
    if [[ -z "$source_path" || "$source_path" =~ ^# ]]; then
        continue
    fi

    # Проверяем, существует ли исходный файл или директория
    if [ ! -e "$source_path" ]; then
        echo "Предупреждение: Источник '$source_path' не найден. Пропускаем."
        continue
    fi

    # Создаем целевую директорию, если она не существует
    # Получаем директорию из dest_path
    DEST_DIR=$(dirname "$dest_path")
    if [ ! -d "$DEST_DIR" ]; then
        echo "Создаем целевую директорию: $DEST_DIR"
        mkdir -p "$DEST_DIR"
        if [ $? -ne 0 ]; then
            echo "Ошибка: Не удалось создать директорию '$DEST_DIR'. Пропускаем."
            continue
        fi
    fi

    # Копируем файл/директорию
    echo "Копируем: '$source_path' -> '$dest_path'"
    cp -Rv "$source_path" "$dest_path"
    if [ $? -ne 0 ]; then
        echo "Ошибка при копировании '$source_path' в '$dest_path'."
    else
        echo "Успешно скопировано."
    fi
    echo
done < "$MAPPING_FILE"

echo "Копирование файлов завершено."
echo ""

ln -fs /opt/zapret/init.d/sysv/zapret /opt/etc/init.d/S90-zapret

echo "Добавлено в автозагрузку: /opt/etc/init.d/S90-zapret -> /opt/zapret/init.d/sysv/zapret"
echo ""

cp -a /opt/zapret/init.d/custom.d.examples.linux/10-keenetic-udp-fix /opt/zapret/init.d/sysv/custom.d/10-keenetic-udp-fix

echo "Файл 10-keenetic-udp-fix скопирован"
echo ""

chmod +x /opt/etc/ndm/netfilter.d/000-zapret.sh
echo "Права выданы /opt/etc/ndm/netfilter.d/000-zapret.sh"
echo ""

chmod +x /opt/etc/init.d/S00fix
echo "Права выданы /opt/etc/init.d/S00fix"
echo ""

chmod +x /opt/zapret/init.d/sysv/zapret
echo "Права выданы /opt/zapret/init.d/sysv/zapret"
echo ""


echo "Начало обновления конфигурации zapret..."

# --- Проверки перед выполнением ---

# Проверяем, существует ли файл конфигурации
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Ошибка: Файл конфигурации '$CONFIG_FILE' не найден."
    echo "Убедитесь, что файл существует и указан правильный путь."
    exit 1
fi

# Проверяем, существует ли файл с новыми параметрами
if [ ! -f "$NEW_OPT_FILE" ]; then
    echo "Ошибка: Файл с новыми параметрами NFQWS_OPT '$NEW_OPT_FILE' не найден."
    echo "Убедитесь, что 'nfqws_opt.txt' находится в той же директории, что и этот скрипт."
    exit 1
fi

# Создаем резервную копию оригинального файла конфигурации
echo "Создание резервной копии файла '$CONFIG_FILE' -> '$BACKUP_FILE'..."
cp "$CONFIG_FILE" "$BACKUP_FILE"
if [ $? -ne 0 ]; then
    echo "Ошибка: Не удалось создать резервную копию файла '$CONFIG_FILE'."
    echo "Проверьте права доступа к файлу."
    exit 1
fi
echo "Резервная копия успешно создана."

# --- Основная логика замены с использованием AWK ---

echo "Обновление блока NFQWS_OPT, параметров WS_USER, NFQWS_PORTS_UDP, IFACE_WAN (опционально) и IFACE_LAN в '$CONFIG_FILE'..."
# Используем AWK для надежной замены многострочного блока и параметров.
awk -v new_file_path="$NEW_OPT_FILE" -v interface="$NETWORK_INTERFACE" '
BEGIN {
    # Флаг, указывающий, находимся ли мы внутри блока NFQWS_OPT
    in_nfqws_opt_block = 0;
    # Переменная для хранения нового содержимого NFQWS_OPT
    new_nfqws_opt_content = "";

    # Читаем содержимое нового файла один раз в переменную new_nfqws_opt_content
    # Построчно добавляем его, разделяя переносами строки
    while ((getline line < new_file_path) > 0) {
        new_nfqws_opt_content = new_nfqws_opt_content (new_nfqws_opt_content ? "\n" : "") line;
    }
    close(new_file_path); # Закрываем файл сразу после чтения
}

# Когда встречаем начало блока NFQWS_OPT (строка, начинающаяся с NFQWS_OPT=")
/^NFQWS_OPT="/ {
    print "NFQWS_OPT=\""       # Выводим начальную строку с кавычкой
    print new_nfqws_opt_content # Выводим все содержимое, прочитанное из new_nfqws_opt.txt
    print "\""                  # Выводим закрывающую кавычку
    in_nfqws_opt_block = 1;     # Устанавливаем флаг в true, чтобы пропустить оригинальные строки блока
    next;                       # Переходим к следующей строке, избегая печати оригинальной строки NFQWS_OPT="
}

# Когда мы находимся внутри блока и встречаем закрывающую кавычку (строка, содержащая только ")
in_nfqws_opt_block && /^"$/ {
    in_nfqws_opt_block = 0; # Устанавливаем флаг в false, блок NFQWS_OPT завершен
    next;                   # Переходим к следующей строке, пропуская оригинальную закрывающую кавычку
}

# Для строки #WS_USER=nobody, заменяем её на WS_USER=nobody
/^#WS_USER=nobody$/ {
    print "WS_USER=nobody";
    next;
}

# Для строки NFQWS_PORTS_UDP=443, заменяем её на NFQWS_PORTS_UDP=443,50000-50099
/^NFQWS_PORTS_UDP=443$/ {
    print "NFQWS_PORTS_UDP=443,50000-50099";
    next;
}

# Для строки IFACE_WAN=, заменяем её на IFACE_WAN=<NETWORK_INTERFACE> только если интерфейс указан
/^IFACE_WAN=/ {
    if (interface != "") { # Проверяем, что переменная interface не пустая
        print "IFACE_WAN=" interface;
    } else {
        print $0; # Если interface пустая, просто печатаем оригинальную строку
    }
    next;
}

# Для строки IFACE_LAN=, заменяем её на IFACE_LAN=br0
/^IFACE_LAN=/ {
    print "IFACE_LAN=br0";
    next;
}

# Для всех остальных строк: если мы не находимся внутри блока NFQWS_OPT, печатаем строку
!in_nfqws_opt_block {
    print $0;
}
' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" # Перенаправляем вывод AWK во временный файл

# Проверяем успешность выполнения AWK
if [ $? -eq 0 ]; then
    # Если AWK выполнился успешно, заменяем оригинальный файл временным
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    echo "Параметры NFQWS_OPT, WS_USER, NFQWS_PORTS_UDP, IFACE_WAN (если указан) и IFACE_LAN успешно обновлены в '$CONFIG_FILE'."
    echo "Скрипт выполнен успешно!"
else
    echo "Ошибка: Не удалось обновить параметры NFQWS_OPT, WS_USER, NFQWS_PORTS_UDP, IFACE_WAN и IFACE_LAN в '$CONFIG_FILE'."
    rm -f "${CONFIG_FILE}.tmp" # Удаляем временный файл в случае ошибки
    exit 1
fi

exit 0