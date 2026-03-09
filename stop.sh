#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "[*] Stopping hostapd and dnsmasq..."
systemctl stop hostapd
systemctl stop dnsmasq

echo "[*] Flushing iptables rules..."
iptables -t nat -F
iptables -F FORWARD

echo "[*] Releasing uplink DHCP lease..."
dhclient -r $UPLINK_INTERFACE 2>/dev/null || true
pkill wpa_supplicant 2>/dev/null || true

echo "[*] Bringing down hotspot interface..."
ip addr flush dev $HOTSPOT_INTERFACE
ip link set $HOTSPOT_INTERFACE down

echo "[✓] Router stopped."
