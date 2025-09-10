#!/bin/bash

# Скрипт для загрузки Terraform модуля в Terralist

# Конфигурация
TERRALIST_URL="https://terralist.caas.k-mkaas-dev-1.cloud.preprod.world"
API_KEY="4f917a66-f2be-45db-b07e-6b987a97065a"
MODULE_PATH="/Users/zhanibek/CursorProjects/terralist/test-module"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Terralist Module Upload Script ===${NC}"

# Проверка наличия директории модуля
if [ ! -d "$MODULE_PATH" ]; then
    echo -e "${RED}Error: Module directory not found: $MODULE_PATH${NC}"
    exit 1
fi

cd "$MODULE_PATH"

# Проверка наличия необходимых файлов
echo -e "\n${YELLOW}Checking module structure...${NC}"
if [ ! -f "main.tf" ] && [ ! -f "README.md" ]; then
    echo -e "${RED}Warning: No main.tf or README.md found. Make sure your module is properly structured.${NC}"
fi

# Определение имени модуля и версии
MODULE_NAME=$(basename "$MODULE_PATH")
MODULE_VERSION="0.1.0"  # Измените на нужную версию

echo -e "Module name: ${GREEN}$MODULE_NAME${NC}"
echo -e "Module version: ${GREEN}$MODULE_VERSION${NC}"

# Создание архива модуля
echo -e "\n${YELLOW}Creating module archive...${NC}"
ARCHIVE_NAME="${MODULE_NAME}-${MODULE_VERSION}.tar.gz"
tar -czf "/tmp/$ARCHIVE_NAME" --exclude='.git' --exclude='.terraform' --exclude='*.tfstate*' .

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to create archive${NC}"
    exit 1
fi

echo -e "${GREEN}Archive created: /tmp/$ARCHIVE_NAME${NC}"

# Загрузка модуля через API
echo -e "\n${YELLOW}Uploading module to Terralist...${NC}"

# Сначала нужно создать модуль, если он не существует
echo -e "Creating module entry..."
CREATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  "${TERRALIST_URL}/v1/modules" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "namespace": "default",
    "name": "'${MODULE_NAME}'",
    "provider": "generic",
    "version": "'${MODULE_VERSION}'"
  }')

HTTP_CODE=$(echo "$CREATE_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$CREATE_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" != "201" ] && [ "$HTTP_CODE" != "409" ]; then
    echo -e "${RED}Error creating module: HTTP $HTTP_CODE${NC}"
    echo -e "Response: $RESPONSE_BODY"
else
    echo -e "${GREEN}Module entry created or already exists${NC}"
fi

# Загрузка файла модуля
echo -e "\nUploading module archive..."
UPLOAD_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  "${TERRALIST_URL}/v1/modules/default/${MODULE_NAME}/generic/${MODULE_VERSION}/upload" \
  -H "Authorization: Bearer ${API_KEY}" \
  -F "file=@/tmp/$ARCHIVE_NAME")

HTTP_CODE=$(echo "$UPLOAD_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$UPLOAD_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "201" ]; then
    echo -e "${GREEN}Module uploaded successfully!${NC}"
    echo -e "\nModule URL: ${GREEN}${TERRALIST_URL}/modules/default/${MODULE_NAME}/generic${NC}"
    echo -e "\nTo use this module in Terraform:"
    echo -e "${YELLOW}"
    echo "module \"$MODULE_NAME\" {"
    echo "  source  = \"${TERRALIST_URL}/default/${MODULE_NAME}/generic\""
    echo "  version = \"${MODULE_VERSION}\""
    echo "}"
    echo -e "${NC}"
else
    echo -e "${RED}Error uploading module: HTTP $HTTP_CODE${NC}"
    echo -e "Response: $RESPONSE_BODY"
    exit 1
fi

# Очистка временного файла
rm -f "/tmp/$ARCHIVE_NAME"

echo -e "\n${GREEN}Done!${NC}"