#!/bin/bash
set -euxo pipefail

exec >> /var/log/bootstrap-master.log 2>&1

export DEBIAN_FRONTEND=noninteractive

echo "===== System update & dependencies installation ====="

apt-get update -y
apt-get install -y --no-install-recommends curl ca-certificates

echo "===== Installing k3s ====="

NODE_IP=$(hostname -I | awk '{print $1}')
NODE_NAME=$(hostname)

%{ if is_first ~}
echo "===== Initializing first control-plane node ====="

curl -sfL https://get.k3s.io | \
  INSTALL_K3S_VERSION="${k3s_version}" \
  INSTALL_K3S_EXEC="server \
    --cluster-init \
    --tls-san ${tls_san} \
    --node-ip $${NODE_IP} \
    --disable servicelb \
    --disable traefik \
    --node-name $${NODE_NAME}" \
  K3S_TOKEN="${cluster_token}" \
  sh -

%{ else ~}
echo "===== Joining additional control-plane node ====="

curl -sfL https://get.k3s.io | \
  INSTALL_K3S_VERSION="${k3s_version}" \
  INSTALL_K3S_EXEC="server \
    --server https://${tls_san}:6443 \
    --tls-san ${tls_san} \
    --node-ip $${NODE_IP} \
    --disable servicelb \
    --disable traefik \
    --node-name $${NODE_NAME}" \
  K3S_TOKEN="${cluster_token}" \
  sh -

%{ endif ~}

echo "===== k3s installation completed successfully ====="
