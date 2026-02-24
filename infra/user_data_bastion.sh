#!/bin/bash
set -euxo pipefail

exec >> /var/log/bootstrap-bastion.log 2>&1

export DEBIAN_FRONTEND=noninteractive

echo "===== Installing kubectl (testing purpose) ====="

apt-get update -y
apt-get install -y curl iptables-persistent haproxy netcat-openbsd

curl -LO "https://dl.k8s.io/release/v1.34.4/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

echo "===== Starting NAT configuration ====="

# Enable IP forwarding persistently
if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
  echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi
sysctl -w net.ipv4.ip_forward=1

# Detect primary network interface dynamically
PRIMARY_IFACE=$(ip -o -4 route show to default | awk '{print $5}' | head -n1)

iptables -t nat -C POSTROUTING -o "$PRIMARY_IFACE" -j MASQUERADE 2>/dev/null \
  || iptables -t nat -A POSTROUTING -o "$PRIMARY_IFACE" -j MASQUERADE

iptables-save > /etc/iptables/rules.v4

echo "===== Starting HAProxy configuration ====="

cat << EOF > /etc/haproxy/haproxy.cfg
global
    log /dev/log local0
    log /dev/log local1 notice
    daemon
    maxconn 4096

defaults
    log     global
    mode    tcp
    option  dontlognull
    timeout connect 5s
    timeout client  50s
    timeout server  50s
    retries 3

########################################################
# Kubernetes API Load Balancing
########################################################

frontend k8s_api
    bind *:6443
    mode tcp
    default_backend k8s_masters

backend k8s_masters
    mode tcp
    balance roundrobin
    default-server inter 5s downinter 5s rise 2 fall 2
    server master-a ${MASTER_A_IP}:6443 check
    server master-b ${MASTER_B_IP}:6443 check
EOF

# Validate configuration before restart
haproxy -c -f /etc/haproxy/haproxy.cfg

systemctl enable haproxy
systemctl restart haproxy

echo "===== NAT and HA configuration completed ====="
