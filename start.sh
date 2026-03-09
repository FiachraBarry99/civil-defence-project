#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "[*] Bringing up hotspot interface..."
ip link set $HOTSPOT_INTERFACE up
ip addr flush dev $HOTSPOT_INTERFACE
ip addr add $HOTSPOT_IP/24 dev $HOTSPOT_INTERFACE

echo "[*] Scanning for laptop hotspot..."
nmcli device wifi rescan ifname $UPLINK_INTERFACE
sleep 3
echo "[*] Connecting uplink to laptop hotspot via NetworkManager..."
nmcli device wifi connect "$LAPTOP_SSID" password "$LAPTOP_PASSWORD" ifname $UPLINK_INTERFACE
sleep 3

echo "[*] Setting up NAT..."
iptables -t nat -F
iptables -F FORWARD
iptables -t nat -A POSTROUTING -o $UPLINK_INTERFACE -j MASQUERADE
iptables -A FORWARD -i $HOTSPOT_INTERFACE -o $UPLINK_INTERFACE -j ACCEPT
iptables -A FORWARD -i $UPLINK_INTERFACE -o $HOTSPOT_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT

echo "[*] Saving iptables rules..."
netfilter-persistent save

echo "[*] Starting hostapd and dnsmasq..."
systemctl restart hostapd
systemctl restart dnsmasq

echo ""
echo "[✓] Router is up."
echo "    Hotspot SSID : $HOTSPOT_SSID"
echo "    Hotspot IP   : $HOTSPOT_IP"
echo "    Uplink       : $UPLINK_INTERFACE -> $LAPTOP_SSID"