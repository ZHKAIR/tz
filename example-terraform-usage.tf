# Пример использования модуля из Terralist

# Настройка Terralist как registry
terraform {
  required_version = ">= 0.13"
}

# Добавление credentials в ~/.terraformrc:
# credentials "terralist.caas.k-mkaas-dev-1.cloud.preprod.world" {
#   token = "4f917a66-f2be-45db-b07e-6b987a97065a"
# }

# Использование модуля
module "test_module" {
  source  = "terralist.caas.k-mkaas-dev-1.cloud.preprod.world/default/test-module/generic"
  version = "0.1.0"
  
  # Параметры модуля
  name = "my-test-instance"
}

# Вывод результатов
output "module_message" {
  value = module.test_module.message
}