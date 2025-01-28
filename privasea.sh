#!/bin/bash

# Выполнение обновления системы
echo "Обновляем систему перед настройкой..."
sudo apt update -y && sudo apt upgrade -y

# Проверка наличия необходимых утилит, установка если отсутствует
check_and_install() {
    local package=$1
    local command=$2

    if ! command -v "$command" &> /dev/null; then
        echo "$package не найден. Устанавливаем..."
        sudo apt update && sudo apt install -y "$package"
    fi
}

check_and_install "figlet" "figlet"
check_and_install "whiptail" "whiptail"

# Определяем цвета для удобства
COLORS=( "\e[33m" "\e[36m" "\e[34m" "\e[32m" "\e[31m" "\e[35m" "\e[0m" )
YELLOW=${COLORS[0]}
CYAN=${COLORS[1]}
BLUE=${COLORS[2]}
GREEN=${COLORS[3]}
RED=${COLORS[4]}
PINK=${COLORS[5]}
NC=${COLORS[6]}

# Вывод приветственного текста с помощью figlet
echo -e "${PINK}$(figlet -w 150 -f standard "Softs by Gentleman")${NC}"
echo -e "${PINK}$(figlet -w 150 -f standard "x WESNA")${NC}"

echo "===================================================================================================================================="
echo "Добро пожаловать! Начинаем настройку. Подпишитесь на наши Telegram-каналы для обновлений и поддержки: "
echo ""
echo "Gentleman - https://t.me/GentleChron"
echo "Wesna - https://t.me/softs_by_wesna"
echo "===================================================================================================================================="

echo ""

# Определение функции анимации
animate_loading() {
    local message="Подгружаем меню"
    for _ in {1..5}; do
        for suffix in "" "." ".." "..."; do
            printf "\r${GREEN}%s%s${NC}" "$message" "$suffix"
            sleep 0.3
        done
    done
    echo ""
}

# Вызов функции анимации
animate_loading

install_node() {
    echo -e "${BLUE}Начинаем установку ноды Privasea...${NC}"

    # Обновление системы
    sudo apt update && sudo apt upgrade -y

    # Проверка и установка Docker и Docker Compose
    check_and_install "docker.io" "docker"

    if ! command -v docker-compose &> /dev/null; then
        echo -e "${BLUE}Docker Compose не установлен. Устанавливаем Docker Compose...${NC}"
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi

    # Пуллим проект
    docker pull privasea/acceleration-node-beta:latest
    mkdir -p ~/privasea/config

    echo -e "${GREEN}Установка завершена! Выполняем дополнительные шаги...${NC}"

    # Переход в директорию privasea
    cd ~/privasea || exit 1

    # Запуск команды Docker для создания нового keystore
    echo -e "${YELLOW}Введите пароль для нового keystore, когда вас попросят.${NC}"
    docker run --rm -it -v "$HOME/privasea/config:/app/config" privasea/acceleration-node-beta:latest ./node-calc new_keystore

    # Перемещение созданного keystore-файла
    echo -e "${BLUE}Перемещаем созданный keystore в wallet_keystore...${NC}"
    mv $HOME/privasea/config/UTC--* $HOME/privasea/config/wallet_keystore

    echo -e "${GREEN}Кошелек готов для скачивания.Нода установлена.Далее следуйте инструкциям в гайде.${NC}"
}

# Функция для запуска ноды
start_node() {
    echo -e "${BLUE}Запуск ноды Privasea...${NC}"
    # Запрос пароля от пользователя
        echo -e "${YELLOW}Введите пароль, который вы вводили на этапе создания кошелька:${NC}"
        read -s -p "Пароль: " PASS
        echo

    # Запуск контейнера с нодой
    docker run -d --name privanetix-node -v "$HOME/privasea/config:/app/config" -e KEYSTORE_PASSWORD="$PASS" privasea/acceleration-node-beta:latest
    if [ $? -ne 0 ]; then
        echo -e "${RED}Не удалось запустить контейнер Docker.${NC}"
        exit 1
    fi

    echo -e "${GREEN}Нода успешно запущена!${NC}"
}

# Функция проверки логов
check_logs() {
    echo -e "${BLUE}Просмотр логов Privasea...${NC}"
    docker logs -f privanetix-node
}

# Функция для перезапуска ноды
restart_node() {
    echo -e "${BLUE}Рестарт ноды Privasea...${NC}"
    docker restart privanetix-node
    echo -e "${GREEN}Нода успешно перезапущена!${NC}"
}

# Функция удаления ноды
remove_node() {
    echo -e "${BLUE}Удаляем ноду Privasea...${NC}"
    docker stop privanetix-node
    docker rm privanetix-node
    rm -rf ~/privasea
    echo -e "${GREEN}Нода успешно удалена!${NC}"
}

# Меню действий
CHOICE=$(whiptail --title "Меню действий" \
    --menu "Выберите действие:" 15 60 6 \
    "1" "Установка ноды" \
    "2" "Запуск ноды" \
    "3" "Перезапустить ноду" \
    "4" "Проверить работу ноды" \
    "5" "Удаление ноду" \
    "6" "Покинуть меню" \
    3>&1 1>&2 2>&3)

case $CHOICE in
    1) install_node ;;
    2) start_node ;;
    3) restart_node ;; 
    4) check_logs ;;
    5) remove_node ;;
    6) echo -e "${CYAN}Выход из программы.${NC}" ;;
    *) echo -e "${RED}Неверный выбор. Завершение программы.${NC}" ;;
esac
