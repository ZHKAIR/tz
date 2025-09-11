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

# Тест 1: Проверка доступности
echo -e "\n${YELLOW}1. Testing API availability...${NC}"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" "${TERRALIST_URL}/health"

# Тест 2: Получение списка модулей
echo -e "\n${YELLOW}2. Getting module list...${NC}"
curl -s -X GET \
  "${TERRALIST_URL}/v1/modules" \
  -H "Authorization: Bearer ${API_KEY}" | jq '.' || echo "No jq installed, showing raw output"

# Тест 3: Проверка аутентификации
echo -e "\n${YELLOW}3. Testing authentication...${NC}"
AUTH_TEST=$(curl -s -w "\n%{http_code}" -X GET \
  "${TERRALIST_URL}/v1/modules" \
  -H "Authorization: Bearer ${API_KEY}")

HTTP_CODE=$(echo "$AUTH_TEST" | tail -n1)
if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}Authentication successful!${NC}"
else
    echo -e "${RED}Authentication failed! HTTP: $HTTP_CODE${NC}"
fi

# Тест 4: Service discovery
echo -e "\n${YELLOW}4. Getting service discovery...${NC}"
curl -s "${TERRALIST_URL}/.well-known/terraform.json" | jq '.' || echo "Failed to get service discovery"

echo -e "\n${GREEN}API testing completed!${NC}"