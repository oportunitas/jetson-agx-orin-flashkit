#!/usr/bin/env bash
# Verify a Jetson AGX Orin is connected in USB Force Recovery mode.
#
# In recovery, the SoC enumerates as USB device 0955:7023
# ("NVIDIA Corp. APX"). Other Jetson SKUs use different PIDs; this script
# only matches AGX Orin.
set -euo pipefail

NVIDIA_VID="0955"
ORIN_PIDS=("7023")

if ! command -v lsusb >/dev/null 2>&1; then
    echo "lsusb not found. Install with: sudo apt install usbutils" >&2
    exit 2
fi

for pid in "${ORIN_PIDS[@]}"; do
    if lsusb | grep -qiE "ID ${NVIDIA_VID}:${pid}"; then
        echo "[OK] Jetson AGX Orin in recovery mode:"
        lsusb | grep -i "${NVIDIA_VID}:" || true
        exit 0
    fi
done

cat >&2 <<EOF
[ERROR] No Jetson AGX Orin detected in recovery mode.

How to enter Force Recovery:
  1. Power the Jetson AGX Orin OFF completely.
  2. Press and HOLD the Force Recovery button (middle button on the side).
  3. While still holding it, press and release the Power button.
  4. Release Force Recovery after about 2 seconds.
  5. Connect a USB-C cable from the Jetson's FRONT USB-C flash port to this
     host (rear USB-C ports are not the flash port).
  6. Re-run this check.

Current USB devices on this host (for reference):
EOF
lsusb >&2
exit 1
