#!/bin/bash

# Скрипт для загрузки Terraform модуля в Terralist

# Конфигурация
TERRALIST_URL="https://terralist.caas.k-mkaas-dev-1.cloud.preprod.world"
API_KEY="4f917a66-f2be-45db-b07e-6b987a97065a"
MODULE_PATH="/Users/zhanibek/CursorProjects/terralist/test-module"

# Параметры модуля
NAMESPACE="default"
MODULE_NAME="test-module"
PROVIDER="aws"  # Можно изменить на нужный: aws, gcp, azure, generic
VERSION="0.1.0"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Terralist Module Upload Script ===${NC}"

# Проверка наличия директории модуля
if [ ! -d "$MODULE_PATH" ]; then
    echo -e "${RED}Error: Module directory not found: $MODULE_PATH${NC}"
    echo "Please check the path and try again."
    exit 1
fi

cd "$MODULE_PATH"

# Проверка структуры модуля
echo -e "\n${YELLOW}Checking module structure...${NC}"
if [ ! -f "main.tf" ]; then
    echo -e "${YELLOW}Warning: main.tf not found. Creating example module...${NC}"
    
    # Создание примера модуля
    cat > main.tf <<'EOF'
# Example Terraform module
terraform {
  required_version = ">= 0.13"
}

variable "name" {
  description = "Name for the resources"
  type        = string
  default     = "test"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

resource "null_resource" "example" {
  provisioner "local-exec" {
    command = "echo Hello from ${var.name} in ${var.environment}"
  }
}

output "message" {
  value = "Module ${var.name} deployed in ${var.environment}"
}
EOF

    cat > README.md <<EOF
# Test Module

This is a test Terraform module uploaded to Terralist.

## Usage

\`\`\`hcl
module "example" {
  source  = "${TERRALIST_URL#https://}/${NAMESPACE}/${MODULE_NAME}/${PROVIDER}"
  version = "${VERSION}"
  
  name        = "my-app"
  environment = "production"
}
\`\`\`

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| name | Name for the resources | string | "test" |
| environment | Environment name | string | "dev" |

## Outputs

| Name | Description |
|------|-------------|
| message | Status message |
EOF

    cat > versions.tf <<'EOF'
terraform {
  required_version = ">= 0.13"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
  }
}
EOF
fi

ls -la

# Создание архива модуля
echo -e "\n${YELLOW}Creating module archive...${NC}"
ARCHIVE_NAME="${MODULE_NAME}-${VERSION}.tar.gz"
tar -czf "/tmp/$ARCHIVE_NAME" \
  --exclude='.git' \
  --exclude='.gitignore' \
  --exclude='.terraform' \
  --exclude='*.tfstate*' \
  --exclude='.terraform.lock.hcl' \
  .

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to create archive${NC}"
    exit 1
fi

ARCHIVE_SIZE=$(ls -lh "/tmp/$ARCHIVE_NAME" | awk '{print $5}')
echo -e "${GREEN}Archive created: /tmp/$ARCHIVE_NAME (${ARCHIVE_SIZE})${NC}"

# Первый метод: Прямая загрузка через multipart form
echo -e "\n${YELLOW}Uploading module to Terralist...${NC}"
echo "Module: ${NAMESPACE}/${MODULE_NAME}/${PROVIDER} v${VERSION}"

# URL для загрузки согласно Terraform Registry Protocol
UPLOAD_URL="${TERRALIST_URL}/v1/modules/${NAMESPACE}/${MODULE_NAME}/${PROVIDER}/${VERSION}/upload"

echo -e "\nUpload URL: $UPLOAD_URL"

# Загрузка модуля
UPLOAD_RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT \
  "$UPLOAD_URL" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/x-tar" \
  --data-binary "@/tmp/$ARCHIVE_NAME")

HTTP_CODE=$(echo "$UPLOAD_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$UPLOAD_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "201" ] || [ "$HTTP_CODE" == "204" ]; then
    echo -e "${GREEN}✓ Module uploaded successfully!${NC}"
    
    echo -e "\n${GREEN}Module Details:${NC}"
    echo "- Namespace: ${NAMESPACE}"
    echo "- Name: ${MODULE_NAME}"
    echo "- Provider: ${PROVIDER}"
    echo "- Version: ${VERSION}"
    
    echo -e "\n${GREEN}To use this module in Terraform:${NC}"
    cat <<EOF

# In your Terraform configuration:
module "${MODULE_NAME//-/_}" {
  source  = "${TERRALIST_URL#https://}/${NAMESPACE}/${MODULE_NAME}/${PROVIDER}"
  version = "${VERSION}"
  
  # Module inputs
  name        = "my-app"
  environment = "production"
}

# Don't forget to add credentials to ~/.terraformrc:
credentials "${TERRALIST_URL#https://}" {
  token = "${API_KEY}"
}
EOF

elif [ "$HTTP_CODE" == "409" ]; then
    echo -e "${YELLOW}Module version already exists. Try with a different version.${NC}"
    exit 1
else
    echo -e "${RED}Error uploading module: HTTP $HTTP_CODE${NC}"
    echo -e "Response: $RESPONSE_BODY"
    
    # Альтернативный метод
    echo -e "\n${YELLOW}Trying alternative upload method...${NC}"
    
    # Сначала создаем модуль
    CREATE_URL="${TERRALIST_URL}/v1/modules/"
    CREATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
      "$CREATE_URL" \
      -H "Authorization: Bearer ${API_KEY}" \
      -H "Content-Type: application/json" \
      -d "{
        \"namespace\": \"${NAMESPACE}\",
        \"name\": \"${MODULE_NAME}\",
        \"provider\": \"${PROVIDER}\"
      }")
    
    HTTP_CODE=$(echo "$CREATE_RESPONSE" | tail -n1)
    echo "Create module response: HTTP $HTTP_CODE"
    
    # Затем загружаем версию
    VERSION_UPLOAD_URL="${TERRALIST_URL}/v1/modules/${NAMESPACE}/${MODULE_NAME}/${PROVIDER}/versions"
    VERSION_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
      "$VERSION_UPLOAD_URL" \
      -H "Authorization: Bearer ${API_KEY}" \
      -F "version=${VERSION}" \
      -F "module=@/tmp/$ARCHIVE_NAME")
    
    HTTP_CODE=$(echo "$VERSION_RESPONSE" | tail -n1)
    if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "201" ]; then
        echo -e "${GREEN}✓ Module uploaded successfully using alternative method!${NC}"
    else
        echo -e "${RED}Alternative method also failed: HTTP $HTTP_CODE${NC}"
        exit 1
    fi
fi

# Проверка загруженного модуля
echo -e "\n${YELLOW}Verifying upload...${NC}"
VERIFY_URL="${TERRALIST_URL}/v1/modules/${NAMESPACE}/${MODULE_NAME}/${PROVIDER}/${VERSION}"
VERIFY_RESPONSE=$(curl -s -w "\n%{http_code}" \
  "$VERIFY_URL" \
  -H "Authorization: Bearer ${API_KEY}")

HTTP_CODE=$(echo "$VERIFY_RESPONSE" | tail -n1)
if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✓ Module verified successfully!${NC}"
else
    echo -e "${YELLOW}Could not verify module (HTTP $HTTP_CODE)${NC}"
fi

# Очистка
rm -f "/tmp/$ARCHIVE_NAME"

echo -e "\n${GREEN}Done!${NC}"