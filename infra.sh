#!/bin/bash

set -o xtrace

terraform apply -auto-approve

PUBLIC_IP=$(terraform output -raw public_ip)

curl http://${PUBLIC_IP}:8080
