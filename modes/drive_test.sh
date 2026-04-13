#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$SCRIPT_DIR/config.sh"

echo "Checking iperf3 server on laptop..."
if ! iperf3 -c "$LAPTOP_IP" -B "$PI_IP" -t 1 &>/dev/null; then
    echo "Cannot reach iperf3 server at $LAPTOP_IP. Is it running?"
    exit 1
fi

echo "iperf3 server reachable. Starting drive test..."
python3 "$SCRIPT_DIR/modes/drive_test.py"