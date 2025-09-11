#!/bin/bash

# Скрипт для тестирования API Terralist

TERRALIST_URL="https://terralist.caas.k-mkaas-dev-1.cloud.preprod.world"
API_KEY="4f917a66-f2be-45db-b07e-6b987a97065a"

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Testing Terralist API ===${NC}"

# Тест 1: Service discovery
echo -e "\n${YELLOW}1. Getting service discovery...${NC}"
curl -s "${TERRALIST_URL}/.well-known/terraform.json" | jq '.'

# Тест 2: Проверка здоровья (правильный путь)
echo -e "\n${YELLOW}2. Testing health endpoint...${NC}"
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" "${TERRALIST_URL}/")
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -n1)
echo "HTTP Status: $HTTP_CODE"

# Тест 3: Получение списка модулей (с правильным trailing slash)
echo -e "\n${YELLOW}3. Getting module list...${NC}"
MODULES_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET \
  "${TERRALIST_URL}/v1/modules/" \
  -H "Authorization: Bearer ${API_KEY}")

HTTP_CODE=$(echo "$MODULES_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$MODULES_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}Success! Modules list:${NC}"
    echo "$RESPONSE_BODY" | jq '.' 2>/dev/null || echo "$RESPONSE_BODY"
else
    echo -e "${RED}Failed! HTTP: $HTTP_CODE${NC}"
    echo "Response: $RESPONSE_BODY"
fi

# Тест 4: Проверка аутентификации через auth endpoint
echo -e "\n${YELLOW}4. Testing authentication...${NC}"
AUTH_TEST=$(curl -s -w "\n%{http_code}" -X GET \
  "${TERRALIST_URL}/v1/auth/authorization" \
  -H "Authorization: Bearer ${API_KEY}")

HTTP_CODE=$(echo "$AUTH_TEST" | tail -n1)
if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "401" ]; then
    echo -e "Auth endpoint responded with HTTP: $HTTP_CODE"
else
    echo -e "${YELLOW}Auth endpoint not available or different response: $HTTP_CODE${NC}"
fi

# Тест 5: Проверка providers endpoint
echo -e "\n${YELLOW}5. Testing providers endpoint...${NC}"
curl -s "${TERRALIST_URL}/v1/providers/" \
  -H "Authorization: Bearer ${API_KEY}" | jq '.' 2>/dev/null || echo "No providers or error"

echo -e "\n${GREEN}API testing completed!${NC}"

# Показать как использовать модуль
echo -e "\n${YELLOW}Module source format:${NC}"
echo "source = \"${TERRALIST_URL#https://}/<namespace>/<name>/<provider>\""
echo "Example: source = \"${TERRALIST_URL#https://}/default/my-module/aws\""