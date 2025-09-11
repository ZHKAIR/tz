#!/bin/bash
# Скрипт для локального тестирования Terralist

echo "Тестируем Terralist локально..."

# Создаем временную директорию
mkdir -p /tmp/terralist-test
cd /tmp/terralist-test

# Запускаем Terralist в Docker для проверки
docker run --rm -it \
  -e TERRALIST_LOG_LEVEL=debug \
  -e TERRALIST_DATABASE_BACKEND=sqlite \
  -e TERRALIST_SQLITE_PATH=/data/terralist.db \
  -e TERRALIST_SERVER_HOST=0.0.0.0 \
  -e TERRALIST_SERVER_PORT=5758 \
  -v $(pwd):/data \
  ghcr.io/terralist/terralist:latest \
  /terralist server

# Или для диагностики:
echo ""
echo "Для диагностики запустите:"
echo "docker run --rm -it ghcr.io/terralist/terralist:latest /terralist server --help"