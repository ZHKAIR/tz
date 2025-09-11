#!/bin/bash

# Скрипт для проверки, где хранятся модули

echo "=== Checking Terralist Storage Configuration ==="

# Проверка pod'а
echo -e "\n1. Checking Terralist pod storage:"
kubectl exec -n terralist terralist-0 -- sh -c 'find /mnt /tmp /var -name "*.tar.gz" -o -name "*.zip" 2>/dev/null | head -20'

echo -e "\n2. Checking data directory:"
kubectl exec -n terralist terralist-0 -- ls -la /mnt/data/

echo -e "\n3. Checking environment variables:"
kubectl exec -n terralist terralist-0 -- env | grep -E "S3|STORAGE|FILE"

echo -e "\n4. Checking disk usage:"
kubectl exec -n terralist terralist-0 -- df -h /mnt/data

echo -e "\n5. Looking for module storage paths:"
kubectl exec -n terralist terralist-0 -- find / -type d -name "modules" -o -name "providers" 2>/dev/null | grep -v proc | head -10