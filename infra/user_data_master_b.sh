#!/bin/bash
set -euxo pipefail

exec >> /var/log/bootstrap-k3s.log 2>&1
export DEBIAN_FRONTEND=noninteractive

echo "===== Starting secondary k3s master bootstrap ====="

apt-get update -y
apt-get install -y curl

# Wait for Kubernetes API to be fully ready
until curl -k https://${LB_IP}:6443/readyz >/dev/null 2>&1; do
  echo "Waiting for Kubernetes API readiness..."
  sleep 5
done

if command -v k3s >/dev/null 2>&1; then
  echo "k3s already installed. Skipping."
  exit 0
fi

curl -sfL https://get.k3s.io | \
  INSTALL_K3S_VERSION="v1.29.6+k3s1" \
  K3S_TOKEN="${K3S_TOKEN}" \
  sh -s - server \
  --server "https://${LB_IP}:6443" \
  --tls-san "${LB_IP}" \
  --node-ip "$(hostname -I | awk '{print $1}')" \
  --disable servicelb \
  --disable traefik \
  --write-kubeconfig-mode 644 \
  --node-name "$(hostname)"

echo "===== Secondary k3s master bootstrap completed ====="
