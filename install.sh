#!/bin/sh

# Проверяем, что передан один аргумент (путь к файлу со списком копирования)
if [ -z "$1" ]; then
    echo "Использование: $0 <файл_со_списком_копирования>"
    exit 1
fi

MAPPING_FILE="$1"

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

ln -fs /opt/zapret/init.d/sysv/zapret /opt/etc/init.d/S90-zapret

echo "Символическая ссылка создана: /opt/etc/init.d/S90-zapret -> /opt/zapret/init.d/sysv/zapret"

cp -a /opt/zapret/init.d/custom.d.examples.linux/10-keenetic-udp-fix /opt/zapret/init.d/sysv/custom.d/10-keenetic-udp-fix

echo "Файл 10-keenetic-udp-fix скопирован"

chmod +x /opt/etc/ndm/netfilter.d/000-zapret.sh
echo "Права выданы /opt/etc/ndm/netfilter.d/000-zapret.sh"

chmod +x /opt/etc/init.d/S00fix
echo "Права выданы /opt/etc/init.d/S00fix"