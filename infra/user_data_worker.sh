#!/bin/bash
set -euxo pipefail

exec >> /var/log/bootstrap-k3s.log 2>&1
export DEBIAN_FRONTEND=noninteractive

echo "===== Starting k3s worker bootstrap ====="

apt-get update -y
apt-get install -y curl

# Wait for Kubernetes API readiness
until curl -k https://${LB_IP}:6443/readyz >/dev/null 2>&1; do
  echo "Waiting for Kubernetes API readiness..."
  sleep 5
done

if command -v k3s-agent >/dev/null 2>&1; then
  echo "k3s agent already installed. Skipping."
  exit 0
fi

curl -sfL https://get.k3s.io | \
  INSTALL_K3S_VERSION="v1.29.6+k3s1" \
  K3S_URL="https://${LB_IP}:6443" \
  K3S_TOKEN="${K3S_TOKEN}" \
  sh -s - \
  --node-name "$(hostname)" \
  --node-ip "$(hostname -I | awk '{print $1}')"

echo "===== k3s worker bootstrap completed ====="
