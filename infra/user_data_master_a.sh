#!/bin/bash
set -euxo pipefail

exec >> /var/log/bootstrap-k3s.log 2>&1
export DEBIAN_FRONTEND=noninteractive

echo "===== Starting k3s master bootstrap ====="

apt-get update -y
apt-get install -y curl

if command -v k3s >/dev/null 2>&1; then
  echo "k3s already installed. Skipping."
  exit 0
fi

curl -sfL https://get.k3s.io | \
  INSTALL_K3S_VERSION="v1.29.6+k3s1" \
  K3S_TOKEN="${K3S_TOKEN}" \
  sh -s - server \
  --cluster-init \
  --tls-san "${LB_IP}" \
  --node-ip "$(hostname -I | awk '{print $1}')" \
  --disable servicelb \
  --disable traefik \
  --write-kubeconfig-mode 644 \
  --node-name "$(hostname)"

echo "===== k3s master bootstrap completed ====="
