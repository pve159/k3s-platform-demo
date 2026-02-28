#!/bin/bash
set -euxo pipefail

exec >> /var/log/bootstrap-bastion.log 2>&1

export DEBIAN_FRONTEND=noninteractive

echo "===== System update & package installation ====="

apt-get update -y
apt-get install -y --no-install-recommends haproxy iptables-persistent curl

echo "===== Enabling IP forwarding ====="

if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
  echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi

sysctl -w net.ipv4.ip_forward=1

echo "===== Configuring NAT ====="

PRIMARY_IFACE=$(ip -o -4 route show to default | awk '{print $5}' | head -n1)

if ! iptables -t nat -C POSTROUTING -o "$PRIMARY_IFACE" -j MASQUERADE 2>/dev/null; then
  iptables -t nat -A POSTROUTING -o "$PRIMARY_IFACE" -j MASQUERADE
fi

iptables-save > /etc/iptables/rules.v4

echo "===== Configuring HAProxy ====="

cat <<EOF > /etc/haproxy/haproxy.cfg
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
%{ for ip in master_private_ips ~}
    server master-${replace(ip, ".", "-")} ${ip}:6443 check
%{ endfor ~}
EOF

echo "===== Validating HAProxy configuration ====="

haproxy -c -f /etc/haproxy/haproxy.cfg

systemctl enable haproxy
systemctl restart haproxy

echo "===== Bastion NAT + HAProxy bootstrap completed successfully ====="
