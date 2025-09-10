#!/bin/bash

# Команды для исследования работающего контейнера

echo "=== Inspect контейнера ==="
docker inspect a4f45547046d | jq '.[0].Config.Entrypoint, .[0].Config.Cmd, .[0].Args'

echo -e "\n=== Процессы в контейнере ==="
docker exec a4f45547046d ps aux

echo -e "\n=== Переменные окружения ==="
docker exec a4f45547046d env | grep TERRALIST

echo -e "\n=== Содержимое entrypoint скрипта ==="
docker exec a4f45547046d cat /usr/local/bin/docker-entrypoint.sh 2>/dev/null || echo "Entrypoint script not found at /usr/local/bin/"

echo -e "\n=== Поиск entrypoint ==="
docker exec a4f45547046d find / -name "docker-entrypoint*" 2>/dev/null

echo -e "\n=== Как был запущен контейнер ==="
docker ps --no-trunc --format "table {{.Command}}" | grep -A1 COMMAND