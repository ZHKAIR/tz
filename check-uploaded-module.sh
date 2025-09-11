#!/bin/bash

echo "=== Проверка загруженного модуля ==="

TERRALIST_URL="https://terralist.caas.k-mkaas-dev-1.cloud.preprod.world"
API_KEY="4f917a66-f2be-45db-b07e-6b987a97065a"

# 1. Проверяем список модулей
echo -e "\n1. Список модулей в Terralist:"
curl -s "${TERRALIST_URL}/v1/modules/" \
  -H "Authorization: Bearer ${API_KEY}" | jq '.' || echo "Нет модулей или ошибка"

# 2. Пробуем получить конкретный модуль
echo -e "\n2. Пробуем получить модуль test-module:"
curl -s -w "\nHTTP Status: %{http_code}\n" \
  "${TERRALIST_URL}/v1/modules/default/test-module/aws/1.0.0" \
  -H "Authorization: Bearer ${API_KEY}"

# 3. Пробуем скачать модуль
echo -e "\n3. Пробуем скачать файл модуля:"
curl -s -w "\nHTTP Status: %{http_code}\n" \
  "${TERRALIST_URL}/v1/modules/default/test-module/aws/1.0.0/download" \
  -H "Authorization: Bearer ${API_KEY}" \
  -o /tmp/test-download.tar.gz

# 4. Проверяем что скачалось
if [ -f /tmp/test-download.tar.gz ]; then
  echo "Файл скачался, размер: $(ls -lh /tmp/test-download.tar.gz | awk '{print $5}')"
else
  echo "Файл НЕ скачался - модуль не сохранен на сервере!"
fi