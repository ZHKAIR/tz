#!/bin/bash

echo "=== Тест terraform init с модулем из Terralist ==="

# Создаем тестовый проект
mkdir -p /tmp/terraform-test
cd /tmp/terraform-test

# Создаем .terraformrc с credentials
cat > ~/.terraformrc <<EOF
credentials "terralist.caas.k-mkaas-dev-1.cloud.preprod.world" {
  token = "4f917a66-f2be-45db-b07e-6b987a97065a"
}
EOF

# Создаем main.tf
cat > main.tf <<EOF
terraform {
  required_version = ">= 0.13"
}

module "test" {
  source  = "terralist.caas.k-mkaas-dev-1.cloud.preprod.world/default/test-module/aws"
  version = "1.0.0"
}

output "test_message" {
  value = module.test.message
}
EOF

# Пробуем terraform init
echo -e "\nЗапускаем terraform init..."
terraform init

# Проверяем результат
if [ -d ".terraform/modules" ]; then
  echo -e "\n✅ Модуль скачался!"
  ls -la .terraform/modules/
else
  echo -e "\n❌ Модуль НЕ скачался - его нет на сервере!"
fi