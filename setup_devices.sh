#!/usr/bin/env bash
set -euo pipefail

# Purpose:
# - Create two TAP devices and bridge each one into a dedicated Docker bridge network.
# - INET binds to the TAP devices (L2), containers live on the Docker networks (L3/L2).
#
# Topology:
#   [INET ExtEthernetInterface] <-> tapa <-> br-inet-left  <-> (docker veth) <-> left container
#   [INET ExtEthernetInterface] <-> tapb <-> br-inet-right <-> (docker veth) <-> right container

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERROR: This script requires Linux (ip/bridge/tuntap). Run it in a Linux VM that hosts Docker + OMNeT++/INET." >&2
  exit 1
fi

command -v ip >/dev/null || { echo "ERROR: 'ip' not found (install iproute2)." >&2; exit 1; }
command -v docker >/dev/null || { echo "ERROR: 'docker' not found." >&2; exit 1; }

TAP_LEFT="${TAP_LEFT:-tapa}"
TAP_RIGHT="${TAP_RIGHT:-tapb}"
BR_LEFT="${BR_LEFT:-br-inet-left}"
BR_RIGHT="${BR_RIGHT:-br-inet-right}"
NET_LEFT="${NET_LEFT:-inet-left}"
NET_RIGHT="${NET_RIGHT:-inet-right}"
LEFT_CONTAINER="${LEFT_CONTAINER:-left}"
RIGHT_CONTAINER="${RIGHT_CONTAINER:-right}"

LEFT_SUBNET="${LEFT_SUBNET:-192.168.2.0/24}"
RIGHT_SUBNET="${RIGHT_SUBNET:-192.168.3.0/24}"
LEFT_IP="${LEFT_IP:-192.168.2.99}"
RIGHT_IP="${RIGHT_IP:-192.168.3.99}"
LEFT_MAC="${LEFT_MAC:-12:34:88:5D:61:BD}"
RIGHT_MAC="${RIGHT_MAC:-12:34:88:5D:61:BE}"

echo "Cleaning up any previous run..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/teardown.sh" >/dev/null 2>&1 || true

echo "Configuring bridge netfilter to not interfere with L2 forwarding (ARP/ICMP/etc)..."
sudo modprobe br_netfilter 2>/dev/null || true
sudo sysctl -w net.bridge.bridge-nf-call-iptables=0 >/dev/null 2>&1 || true
sudo sysctl -w net.bridge.bridge-nf-call-ip6tables=0 >/dev/null 2>&1 || true
sudo sysctl -w net.bridge.bridge-nf-call-arptables=0 >/dev/null 2>&1 || true

echo "Creating TAP devices (${TAP_LEFT}, ${TAP_RIGHT})..."
# Make the TAPs accessible to the current user (INET/opp_run won't need sudo just to open them).
sudo ip tuntap add dev "${TAP_LEFT}" mode tap user "$(id -u)"
sudo ip tuntap add dev "${TAP_RIGHT}" mode tap user "$(id -u)"
sudo ip link set dev "${TAP_LEFT}" up promisc on
sudo ip link set dev "${TAP_RIGHT}" up promisc on

echo "Creating Docker bridge networks (${NET_LEFT}, ${NET_RIGHT}) with fixed subnets..."
# Docker creates the Linux bridge device named by com.docker.network.bridge.name.
docker network create \
  --driver bridge \
  --subnet "${LEFT_SUBNET}" \
  -o com.docker.network.bridge.name="${BR_LEFT}" \
  "${NET_LEFT}" >/dev/null

docker network create \
  --driver bridge \
  --subnet "${RIGHT_SUBNET}" \
  -o com.docker.network.bridge.name="${BR_RIGHT}" \
  "${NET_RIGHT}" >/dev/null

echo "Attaching TAPs to Docker bridges..."
sudo ip link set dev "${TAP_LEFT}" master "${BR_LEFT}"
sudo ip link set dev "${TAP_RIGHT}" master "${BR_RIGHT}"

echo "Starting containers (${LEFT_CONTAINER}, ${RIGHT_CONTAINER})..."
docker run -dit \
  --name "${LEFT_CONTAINER}" \
  --network "${NET_LEFT}" \
  --ip "${LEFT_IP}" \
  --mac-address "${LEFT_MAC}" \
  --cap-add NET_ADMIN \
  nicolaka/netshoot >/dev/null

docker run -dit \
  --name "${RIGHT_CONTAINER}" \
  --network "${NET_RIGHT}" \
  --ip "${RIGHT_IP}" \
  --mac-address "${RIGHT_MAC}" \
  --cap-add NET_ADMIN \
  nicolaka/netshoot >/dev/null

cat <<EOF
OK.

TAPs:
  - ${TAP_LEFT}  (bridge: ${BR_LEFT}, docker network: ${NET_LEFT}, container: ${LEFT_CONTAINER} ip=${LEFT_IP})
  - ${TAP_RIGHT} (bridge: ${BR_RIGHT}, docker network: ${NET_RIGHT}, container: ${RIGHT_CONTAINER} ip=${RIGHT_IP})

Quick verification (host):
  python3 sender.py --iface ${TAP_LEFT} --target-ip ${LEFT_IP}

Quick verification (container):
  docker exec -it ${LEFT_CONTAINER} tcpdump -eni eth0 arp
EOF
