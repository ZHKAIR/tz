#!/bin/bash

# Альтернативный способ загрузки через Terraform CLI

# Конфигурация
TERRALIST_URL="https://terralist.caas.k-mkaas-dev-1.cloud.preprod.world"
API_KEY="4f917a66-f2be-45db-b07e-6b987a97065a"
MODULE_PATH="/Users/zhanibek/CursorProjects/terralist/test-module"

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Terraform Module Upload to Terralist ===${NC}"

# Создание .terraformrc для аутентификации
echo -e "\n${YELLOW}Setting up Terraform credentials...${NC}"
cat > ~/.terraformrc <<EOF
credentials "${TERRALIST_URL#https://}" {
  token = "${API_KEY}"
}
EOF

# Переход в директорию модуля
cd "$MODULE_PATH" || exit 1

# Создание примера конфигурации если нужно
if [ ! -f "main.tf" ]; then
    echo -e "${YELLOW}Creating example module files...${NC}"
    
    cat > main.tf <<'EOF'
# Example Terraform module
variable "name" {
  description = "Name of the resource"
  type        = string
  default     = "test"
}

output "message" {
  value = "Hello from ${var.name} module!"
}
EOF

    cat > README.md <<'EOF'
# Test Module

This is a test Terraform module for Terralist.

## Usage

```hcl
module "test" {
  source  = "terralist.example.com/namespace/test-module/provider"
  version = "0.1.0"
  
  name = "my-test"
}
```
EOF

    cat > versions.tf <<'EOF'
terraform {
  required_version = ">= 0.13"
}
EOF
fi

# Инициализация git если нужно (для тегов версий)
if [ ! -d ".git" ]; then
    echo -e "\n${YELLOW}Initializing git repository...${NC}"
    git init
    git add .
    git commit -m "Initial commit"
fi

# Создание версии через git tag
VERSION="0.1.0"
echo -e "\n${YELLOW}Creating version tag: v${VERSION}${NC}"
git tag -a "v${VERSION}" -m "Version ${VERSION}" 2>/dev/null || echo "Tag already exists"

# Метод 1: Прямая загрузка через terraform
echo -e "\n${YELLOW}Method 1: Using terraform login and push${NC}"
echo -e "Run these commands manually:\n"
echo -e "${GREEN}terraform login ${TERRALIST_URL#https://}${NC}"
echo -e "Enter API token when prompted: ${YELLOW}${API_KEY}${NC}"
echo -e "\nThen publish the module:"
echo -e "${GREEN}terraform push -name=default/test-module/generic${NC}"

# Метод 2: Использование curl для прямой загрузки
echo -e "\n${YELLOW}Method 2: Direct API upload${NC}"
./upload-module.sh