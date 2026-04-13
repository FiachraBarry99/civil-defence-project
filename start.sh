#!/bin/bash

set -e

if [[ $EUID -ne 0 ]]; then
    echo "Run as root: sudo ./start.sh <mode>"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE=$1

source "$SCRIPT_DIR/config.sh"

if [[ -z "$MODE" ]]; then
    echo "Usage: sudo ./start.sh <mode>"
    echo "Available modes: drive_test"
    exit 1
fi

MODE_SCRIPT="$SCRIPT_DIR/modes/$MODE.sh"

if [[ ! -f "$MODE_SCRIPT" ]]; then
    echo "Unknown mode: $MODE"
    echo "Available modes: drive_test"
    exit 1
fi

source "$SCRIPT_DIR/lib/checks.sh"
check_halow_link || exit 1

echo "Starting mode: $MODE"
bash "$MODE_SCRIPT"