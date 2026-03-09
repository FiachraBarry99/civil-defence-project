#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "this script will pin your wifi interfaces to fixed names"
echo "make sure both wifi adapters are plugged in before continuing"
echo ""

get_mac() {
    cat /sys/class/net/$1/address 2>/dev/null
}

BUILTIN_MAC=$(get_mac wlan0)
DONGLE_MAC=$(get_mac wlan1)

if [ -z "$BUILTIN_MAC" ] || [ -z "$DONGLE_MAC" ]; then
    echo "[!] could not find both interfaces (run 'ip link show')."
    exit 1
fi

echo "Detected:"
echo "  wlan0 (built-in) MAC : $BUILTIN_MAC"
echo "  wlan1 (USB dongle) MAC : $DONGLE_MAC"
echo ""
read -p "Is this correct? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo "Aborted. Plug in both adapters and retry."
    exit 1
fi

echo "[*] Writing udev rules..."
cat > /etc/udev/rules.d/72-wifi-interfaces.rules << EOF
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="$BUILTIN_MAC", NAME="$UPLINK_INTERFACE"
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="$DONGLE_MAC", NAME="$HOTSPOT_INTERFACE"
EOF

echo "[*] Reloading udev rules..."
udevadm control --reload-rules
udevadm trigger
