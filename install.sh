#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "[*] Installing dependencies..."
apt-get update -q
apt-get install -y hostapd dnsmasq iptables-persistent

echo "[*] Stopping services during configuration..."
systemctl unmask hostapd 2>/dev/null || true
systemctl stop hostapd 2>/dev/null || true
systemctl stop dnsmasq 2>/dev/null || true

echo "[*] Enabling IP forwarding..."
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-pi-router.conf
sysctl -p /etc/sysctl.d/99-pi-router.conf

echo "[*] Configuring static IP for hotspot interface..."
mkdir -p /etc/network/interfaces.d
cat > /etc/network/interfaces.d/pi-router << IFACE
allow-hotplug $HOTSPOT_INTERFACE
iface $HOTSPOT_INTERFACE inet static
    address $HOTSPOT_IP
    netmask 255.255.255.0
IFACE

echo "[*] Writing hostapd config..."
mkdir -p /etc/hostapd
cat > /etc/hostapd/hostapd.conf << HOSTAPD
interface=$HOTSPOT_INTERFACE
driver=nl80211
ssid=$HOTSPOT_SSID
hw_mode=g
channel=6
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$HOTSPOT_PASSWORD
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
HOSTAPD

sed -i 's|#DAEMON_CONF=""|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd

echo "[*] Writing dnsmasq config..."
cat > /etc/dnsmasq.d/pi-router.conf << DNSMASQ
interface=$HOTSPOT_INTERFACE
dhcp-range=$DHCP_RANGE_START,$DHCP_RANGE_END,255.255.255.0,24h
dhcp-option=3,$HOTSPOT_IP
dhcp-option=6,8.8.8.8,8.8.4.4
DNSMASQ

echo "[*] Telling NetworkManager to ignore hotspot interface only..."
mkdir -p /etc/NetworkManager/conf.d
cat > /etc/NetworkManager/conf.d/pi-router-unmanaged.conf << NM
[keyfile]
unmanaged-devices=interface-name:$HOTSPOT_INTERFACE
NM
systemctl reload NetworkManager
sleep 2

echo "[*] Writing laptop wifi credentials..."
cat > /etc/wpa_supplicant/wpa_supplicant-${UPLINK_INTERFACE}.conf << WPA
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=GB

network={
    ssid="$LAPTOP_SSID"
    psk="$LAPTOP_PASSWORD"
    key_mgmt=WPA-PSK
}
WPA
chmod 600 /etc/wpa_supplicant/wpa_supplicant-${UPLINK_INTERFACE}.conf

echo "[*] Installing systemd services..."
cp "$SCRIPT_DIR/pi-router.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable pi-router.service
systemctl enable hostapd
systemctl enable dnsmasq

echo ""
echo "installation complete"
echo "run './start.sh' to bring up the router"
