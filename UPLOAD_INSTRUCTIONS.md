# Инструкция по загрузке модуля в Terralist

## Предварительная подготовка

1. **Проверьте структуру вашего модуля**:
   ```bash
   cd /Users/zhanibek/CursorProjects/terralist/test-module
   ls -la
   ```

   Модуль должен содержать как минимум:
   - `main.tf` - основной файл модуля
   - `README.md` - документация
   - `versions.tf` - требования к версии Terraform (опционально)
   - `variables.tf` - входные переменные (опционально)
   - `outputs.tf` - выходные значения (опционально)

2. **Настройте credentials для Terraform**:
   ```bash
   # Создайте файл ~/.terraformrc
   cat > ~/.terraformrc <<EOF
   credentials "terralist.caas.k-mkaas-dev-1.cloud.preprod.world" {
     token = "4f917a66-f2be-45db-b07e-6b987a97065a"
   }
   EOF
   ```

## Способ 1: Загрузка через скрипт (рекомендуется)

1. **Сделайте скрипт исполняемым**:
   ```bash
   chmod +x upload-module.sh
   ```

2. **Запустите скрипт**:
   ```bash
   ./upload-module.sh
   ```

   Скрипт автоматически:
   - Создаст архив модуля
   - Создаст запись модуля в Terralist
   - Загрузит архив
   - Покажет, как использовать модуль

## Способ 2: Ручная загрузка через API

1. **Создайте архив модуля**:
   ```bash
   cd /Users/zhanibek/CursorProjects/terralist/test-module
   tar -czf test-module-0.1.0.tar.gz --exclude='.git' --exclude='.terraform' .
   ```

2. **Создайте модуль в Terralist**:
   ```bash
   curl -X POST \
     https://terralist.caas.k-mkaas-dev-1.cloud.preprod.world/v1/modules \
     -H "Authorization: Bearer 4f917a66-f2be-45db-b07e-6b987a97065a" \
     -H "Content-Type: application/json" \
     -d '{
       "namespace": "default",
       "name": "test-module",
       "provider": "generic",
       "version": "0.1.0"
     }'
   ```

3. **Загрузите архив**:
   ```bash
   curl -X POST \
     https://terralist.caas.k-mkaas-dev-1.cloud.preprod.world/v1/modules/default/test-module/generic/0.1.0/upload \
     -H "Authorization: Bearer 4f917a66-f2be-45db-b07e-6b987a97065a" \
     -F "file=@test-module-0.1.0.tar.gz"
   ```

## Способ 3: Через Terraform CLI

1. **Войдите в Terralist**:
   ```bash
   terraform login terralist.caas.k-mkaas-dev-1.cloud.preprod.world
   # Введите токен: 4f917a66-f2be-45db-b07e-6b987a97065a
   ```

2. **Опубликуйте модуль**:
   ```bash
   cd /Users/zhanibek/CursorProjects/terralist/test-module
   terraform push -name=default/test-module/generic
   ```

## Использование модуля после загрузки

1. **В вашем Terraform коде**:
   ```hcl
   module "test" {
     source  = "terralist.caas.k-mkaas-dev-1.cloud.preprod.world/default/test-module/generic"
     version = "0.1.0"
     
     # Параметры вашего модуля
   }
   ```

2. **Инициализация**:
   ```bash
   terraform init
   ```

## Проверка загрузки

1. **Через API**:
   ```bash
   curl -s https://terralist.caas.k-mkaas-dev-1.cloud.preprod.world/v1/modules \
     -H "Authorization: Bearer 4f917a66-f2be-45db-b07e-6b987a97065a" | jq
   ```

2. **Через веб-интерфейс**:
   Откройте https://terralist.caas.k-mkaas-dev-1.cloud.preprod.world в браузере

## Возможные проблемы

1. **401 Unauthorized** - проверьте API ключ
2. **409 Conflict** - модуль с такой версией уже существует
3. **400 Bad Request** - проверьте формат данных

## Тестирование API

Запустите тестовый скрипт:
```bash
chmod +x test-terralist-api.sh
./test-terralist-api.sh
```