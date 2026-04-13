#!/bin/bash

set -e

if [[ $EUID -ne 0 ]]; then
    echo "Run as root: sudo ./install.sh"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing dependencies..."
apt-get update -q
apt-get install -y iperf3 iputils-ping python3

echo "Pinning HaLow interface name..."
cat > /etc/udev/rules.d/80-halow.rules <<EOF
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="00:c0:ca:b4:bf:cc", NAME="halow0"
EOF
udevadm control --reload-rules

echo "Creating log directory..."
mkdir -p "$SCRIPT_DIR/logs/drive_test"

echo "Done. Reboot for interface pinning to take effect."