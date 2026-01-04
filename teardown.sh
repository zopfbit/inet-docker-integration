#!/usr/bin/env bash
set -euo pipefail

LEFT_CONTAINER="${LEFT_CONTAINER:-left}"
RIGHT_CONTAINER="${RIGHT_CONTAINER:-right}"

TAP_LEFT="${TAP_LEFT:-tapa}"
TAP_RIGHT="${TAP_RIGHT:-tapb}"
BR_LEFT="${BR_LEFT:-br-inet-left}"
BR_RIGHT="${BR_RIGHT:-br-inet-right}"
NET_LEFT="${NET_LEFT:-inet-left}"
NET_RIGHT="${NET_RIGHT:-inet-right}"

docker rm -f "${LEFT_CONTAINER}" "${RIGHT_CONTAINER}" 2>/dev/null || true
docker network rm "${NET_LEFT}" "${NET_RIGHT}" 2>/dev/null || true

# Docker should remove these bridges when the networks are removed, but clean them up anyway.
sudo ip link delete "${BR_LEFT}" type bridge 2>/dev/null || true
sudo ip link delete "${BR_RIGHT}" type bridge 2>/dev/null || true

sudo ip tuntap del mode tap dev "${TAP_LEFT}" 2>/dev/null || true
sudo ip tuntap del mode tap dev "${TAP_RIGHT}" 2>/dev/null || true
