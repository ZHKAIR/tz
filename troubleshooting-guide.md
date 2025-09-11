# Руководство по устранению ошибки Terralist в Kubernetes

## Описание проблемы
При запуске Terralist в Kubernetes возникает ошибка:
```
panic: runtime error: invalid memory address or nil pointer dereference
[signal SIGSEGV: segmentation violation code=0x1 addr=0x40 pc=0x608cb6]
```

Ошибка происходит в функции `sanitizePath`, что указывает на проблемы с обработкой путей.

## Основные причины и решения

### 1. Проблемы с переменными окружения

**Проблемы в исходной конфигурации:**
- `TERRALIST_HOME` - эта переменная не документирована и может вызывать конфликты
- Неправильные имена переменных для OIDC (должны быть `TERRALIST_OIDC_*`, а не `TERRALIST_OI_*`)
- Отсутствует явное указание бэкенда для хранения модулей
- Формат `TERRALIST_S3_PRESIGN_EXPIRE` должен включать единицы времени (например, "15m")

**Решение:** Используйте исправленную конфигурацию из `terralist-statefulset-fixed.yaml`

### 2. Проблемы с правами доступа и путями

**Возможные проблемы:**
- SQLite база данных может не создаваться корректно
- Проблемы с правами доступа к файлам
- Конфликты между абсолютными и относительными путями

**Решение:** 
- Используйте улучшенный init container для создания базы данных
- Убедитесь, что пользователь 1000:1000 имеет права на запись в директорию

### 3. Альтернативные подходы

#### Вариант 1: Использование ConfigMap
Создайте ConfigMap с файлом конфигурации вместо переменных окружения:
```bash
kubectl apply -f terralist-configmap.yaml
kubectl apply -f terralist-statefulset-fixed.yaml
```

#### Вариант 2: Минимальная конфигурация
Начните с минимальной конфигурации для проверки базовой работоспособности:
```bash
kubectl apply -f terralist-minimal-statefulset.yaml
```

#### Вариант 3: Debug Pod
Используйте debug pod для диагностики:
```bash
kubectl apply -f terralist-debug-pod.yaml
kubectl exec -it terralist-debug -- /bin/sh

# Внутри пода:
# Попробуйте запустить terralist с разными параметрами
/terralist server --help
/terralist server --log-level debug
```

## Шаги по диагностике

1. **Проверьте логи init container:**
   ```bash
   kubectl logs <pod-name> -c init-db
   ```

2. **Проверьте логи основного контейнера:**
   ```bash
   kubectl logs <pod-name> -c terralist
   ```

3. **Проверьте состояние volume:**
   ```bash
   kubectl exec <pod-name> -- ls -la /data/
   kubectl exec <pod-name> -- cat /data/terralist.db
   ```

4. **Проверьте переменные окружения:**
   ```bash
   kubectl exec <pod-name> -- env | grep TERRALIST
   ```

## Рекомендации

1. **Используйте последнюю версию Terralist** - убедитесь, что используете актуальную версию образа

2. **Начните с простого** - сначала запустите Terralist с минимальной конфигурацией, затем добавляйте функциональность

3. **Используйте health checks** - замените tcpSocket на httpGet для более точной проверки состояния

4. **Безопасность** - храните секреты (S3 credentials, OAuth secrets) в Kubernetes Secrets, а не в открытом виде

5. **Мониторинг** - добавьте prometheus metrics для отслеживания состояния

## Проверка работоспособности

После применения исправлений:

1. Проверьте, что pod запустился:
   ```bash
   kubectl get pods
   ```

2. Проверьте логи на наличие ошибок:
   ```bash
   kubectl logs -f <pod-name>
   ```

3. Проверьте доступность сервиса:
   ```bash
   kubectl port-forward <pod-name> 5758:5758
   curl http://localhost:5758/health
   ```