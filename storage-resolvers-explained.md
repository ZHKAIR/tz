# Добавьте в ваш StatefulSet эти переменные окружения

# Вариант 1: Локальное хранение на PVC (рекомендую для начала)
env:
  # ... существующие переменные ...
  
  # Включаем локальное хранение для модулей
  - name: TERRALIST_MODULES_STORAGE_RESOLVER
    value: "local"
  - name: TERRALIST_LOCAL_STORE
    value: "/mnt/data/storage"
  
  # Включаем локальное хранение для провайдеров
  - name: TERRALIST_PROVIDERS_STORAGE_RESOLVER
    value: "local"
  
  # Опционально: путь для локального хранения
  - name: TERRALIST_MODULES_LOCAL_STORE
    value: "/mnt/data/storage/modules"
  - name: TERRALIST_PROVIDERS_LOCAL_STORE
    value: "/mnt/data/storage/providers"

---
# Вариант 2: S3 хранение (для production)
env:
  # ... существующие переменные ...
  
  # Включаем S3 для модулей
  - name: TERRALIST_MODULES_STORAGE_RESOLVER
    value: "s3"
  
  # Включаем S3 для провайдеров  
  - name: TERRALIST_PROVIDERS_STORAGE_RESOLVER
    value: "s3"
  
  # S3 конфигурация (уже есть в вашем конфиге)
  - name: TERRALIST_S3_BUCKET_NAME
    value: "terralist-artifacts"
  - name: TERRALIST_S3_BUCKET_REGION
    value: "eu-central-1"
  # ... остальные S3 параметры ...

---
# Вариант 3: Гибридный (proxy + local для своих)
env:
  # Официальные модули проксируем
  - name: TERRALIST_MODULES_STORAGE_RESOLVER
    value: "proxy"
  
  # Свои модули храним локально
  - name: TERRALIST_CUSTOM_MODULES_STORAGE_RESOLVER
    value: "local"
  - name: TERRALIST_LOCAL_STORE
    value: "/mnt/data/custom-modules"