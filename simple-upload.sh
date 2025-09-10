#!/bin/bash

# Простой скрипт для загрузки модуля в Terralist

TERRALIST_URL="https://terralist.caas.k-mkaas-dev-1.cloud.preprod.world"
API_KEY="4f917a66-f2be-45db-b07e-6b987a97065a"
MODULE_PATH="/Users/zhanibek/CursorProjects/terralist/test-module"

# Параметры модуля
NAMESPACE="default"
MODULE_NAME="test-module"
PROVIDER="aws"
VERSION="1.0.0"

echo "=== Uploading module to Terralist ==="

# Переход в директорию модуля
cd "$MODULE_PATH" || exit 1

# Создание простого модуля если его нет
if [ ! -f "main.tf" ]; then
    echo "Creating example module..."
    cat > main.tf <<'EOF'
variable "name" {
  default = "test"
}

output "message" {
  value = "Hello from ${var.name}"
}
EOF
fi

# Создание архива
echo "Creating archive..."
tar -czf module.tar.gz *.tf README.md 2>/dev/null || tar -czf module.tar.gz *.tf

# Метод 1: Terraform Registry API v1
echo -e "\nTrying Terraform Registry API v1 protocol..."

# Создание модуля
curl -X POST "${TERRALIST_URL}/v1/modules/" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "namespace": "'${NAMESPACE}'",
    "name": "'${MODULE_NAME}'",
    "provider": "'${PROVIDER}'"
  }'

echo -e "\n\nUploading module version..."

# Загрузка версии модуля
curl -X POST "${TERRALIST_URL}/v1/modules/${NAMESPACE}/${MODULE_NAME}/${PROVIDER}/${VERSION}/upload" \
  -H "Authorization: Bearer ${API_KEY}" \
  -F "file=@module.tar.gz"

# Проверка
echo -e "\n\nChecking modules list..."
curl -s "${TERRALIST_URL}/v1/modules/" \
  -H "Authorization: Bearer ${API_KEY}" | jq '.'

# Cleanup
rm -f module.tar.gz

echo -e "\n\nUsage:"
echo "module \"test\" {"
echo "  source  = \"${TERRALIST_URL#https://}/${NAMESPACE}/${MODULE_NAME}/${PROVIDER}\""
echo "  version = \"${VERSION}\""
echo "}"