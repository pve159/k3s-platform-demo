#!/bin/bash
set -euxo pipefail

exec >> /var/log/bootstrap-worker.log 2>&1

export DEBIAN_FRONTEND=noninteractive

echo "===== System update & dependencies installation ====="

apt-get update -y
apt-get install -y --no-install-recommends curl ca-certificates

NODE_IP=$(hostname -I | awk '{print $1}')
NODE_NAME=$(hostname)

echo "===== Installing k3s agent ====="

curl -sfL https://get.k3s.io | \
  INSTALL_K3S_VERSION="${k3s_version}" \
  INSTALL_K3S_EXEC="agent \
    --server https://${api_endpoint}:6443 \
    --node-ip $${NODE_IP} \
    --node-name $${NODE_NAME} \
    --node-label ${node_labels}" \
  K3S_TOKEN="${cluster_token}" \
  sh -

echo "===== Worker successfully joined the cluster ====="
