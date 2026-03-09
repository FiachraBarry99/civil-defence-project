#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "[*] Installing dependencies..."
apt-get update -q
apt-get install -y hostapd dnsmasq iptables-persistent

echo "[*] Stopping services during configuration..."
systemctl stop hostapd 2>/dev/null || true
systemctl stop dnsmasq 2>/dev/null || true

echo "[*] Enabling IP forwarding..."
sed -i '/^#net.ipv4.ip_forward/s/^#//' /etc/sysctl.conf
sed -i '/^net.ipv4.ip_forward/s/.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf
grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

echo "[*] Configuring static IP for hotspot interface..."
cat > /etc/network/interfaces.d/pi-router << EOF
allow-hotplug $HOTSPOT_INTERFACE
iface $HOTSPOT_INTERFACE inet static
    address $HOTSPOT_IP
    netmask 255.255.255.0
EOF

echo "[*] Writing hostapd config..."
cat > /etc/hostapd/hostapd.conf << EOF
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
EOF

sed -i 's|#DAEMON_CONF=""|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd

echo "[*] Writing dnsmasq config..."
cat > /etc/dnsmasq.d/pi-router.conf << EOF
interface=$HOTSPOT_INTERFACE
dhcp-range=$DHCP_RANGE_START,$DHCP_RANGE_END,255.255.255.0,24h
dhcp-option=3,$HOTSPOT_IP
dhcp-option=6,8.8.8.8,8.8.4.4
EOF

echo "[*] Telling NetworkManager to ignore both wifi interfaces..."
mkdir -p /etc/NetworkManager/conf.d
cat > /etc/NetworkManager/conf.d/pi-router-unmanaged.conf << EOF
[keyfile]
unmanaged-devices=interface-name:$HOTSPOT_INTERFACE;interface-name:$UPLINK_INTERFACE
EOF
systemctl restart NetworkManager
sleep 2

echo "[*] Writing laptop wifi credentials..."
cat > /etc/wpa_supplicant/wpa_supplicant-${UPLINK_INTERFACE}.conf << EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=GB

network={
    ssid="$LAPTOP_SSID"
    psk="$LAPTOP_PASSWORD"
    key_mgmt=WPA-PSK
}
EOF
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
