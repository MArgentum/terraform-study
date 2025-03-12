#!/bin/bash

set -o xtrace

terraform validate

terraform apply -auto-approve

alb_dns_name=$(terraform output -raw alb_dns_name)

for i in {1..1000}; do
    if ! curl -s -o /dev/null http://${alb_dns_name}:8080; then
        echo "Ошибка при выполнении запроса номер $i"
        exit 1
    fi
done

echo "Все ок"
