#!/bin/bash

MAX_RETRIES=5
source "$( cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd )/config.sh"

check_halow_link() {
    local delay=1

    for ((i=1; i<=MAX_RETRIES; i++)); do
        echo "Checking HaLow link (attempt $i/$MAX_RETRIES)..."

        if ping -c 1 -W 2 -I "$HALOW_INTERFACE" "$HALOW_GATEWAY" &>/dev/null; then
            echo "HaLow link is up."
            return 0
        fi

        if [[ $i -lt $MAX_RETRIES ]]; then
            echo "Link down, retrying in ${delay}s..."
            sleep "$delay"
            delay=$((delay * 2))
        fi
    done

    echo "HaLow link failed after $MAX_RETRIES attempts. Exiting."
    return 1
}