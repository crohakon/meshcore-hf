#!/bin/bash
set -e

echo "Searching for connected hardware..."

# Helper function to find a tty device by USB VID:PID
find_tty_device() {
    local target_vid="$1"
    local target_pid="$2"
    for sys_path in /sys/class/tty/ttyUSB* /sys/class/tty/ttyACM*; do
        if [ -f "$sys_path/device/idVendor" ]; then
            vid=$(cat "$sys_path/device/idVendor" 2>/dev/null)
            pid=$(cat "$sys_path/device/idProduct" 2>/dev/null)
            if [ "$vid" == "$target_vid" ] && [ "$pid" == "$target_pid" ]; then
                echo "/dev/$(basename "$sys_path")"
                return 0
            fi
        fi
    done
    return 1
}

# 1. Detect PTT Device (AIOC, Digirig, or Custom)
if [ -n "$PTT_VID" ] && [ -n "$PTT_PID" ]; then
    echo "Looking for custom PTT hardware specified in environment ($PTT_VID:$PTT_PID)..."
    PTT_DEV=$(find_tty_device "$PTT_VID" "$PTT_PID")
else
    # Fallback to auto-detecting known standard chips
    PTT_DEV=$(find_tty_device "1209" "7388") # AIOC
    if [ -z "$PTT_DEV" ]; then
        PTT_DEV=$(find_tty_device "10c4" "ea60") # Digirig
    fi
fi

if [ -n "$PTT_DEV" ]; then
    echo "Mapped PTT interface to $PTT_DEV"
    ln -sf "$PTT_DEV" /dev/radio_ptt
else
    echo "ERROR: PTT hardware not found!"
    exit 1
fi

# 2. Detect MeshCore Gateway Node
# Apply overrides if provided, otherwise default to standard CH340 chip (1a86:7523)
TARGET_MESH_VID="${MESH_VID:-1a86}"
TARGET_MESH_PID="${MESH_PID:-7523}"

MESH_DEV=$(find_tty_device "$TARGET_MESH_VID" "$TARGET_MESH_PID")

if [ -n "$MESH_DEV" ]; then
    echo "Mapped MeshCore node to $MESH_DEV"
    ln -sf "$MESH_DEV" /dev/meshcore_node
else
    echo "WARNING: Could not auto-detect MeshCore node."
fi

# ==========================================
# UPDATED SECTION: Smart Startup Sequence
# ==========================================

echo "Starting modem73 service in the foreground..."

# Launch socat in a background subshell that waits for port 8001
(
  echo "Waiting for modem73 to open KISS TCP port 8001..."
  # Bash built-in loop to check if the TCP port is accepting connections
  while ! (echo > /dev/tcp/127.0.0.1/8001) >/dev/null 2>&1; do
    sleep 1
  done
  echo "modem73 is ready! Starting socat serial bridge..."
  socat /dev/meshcore_node,raw,echo=0,b115200 TCP:127.0.0.1:8001
) &

# Exec replaces the shell with modem73, keeping it as PID 1 so Docker can track it
exec modem73 --headless --ptt serial --serial-port /dev/radio_ptt $MODEM_EXTRA_ARGS
