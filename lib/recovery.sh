# Jetson recovery-mode detection (sourced).
# scripts/check-recovery.sh is the standalone CLI wrapper.

NVIDIA_VID="0955"
ORIN_PIDS=("7023")

is_in_recovery() {
    command -v lsusb >/dev/null 2>&1 || return 2
    local pid
    for pid in "${ORIN_PIDS[@]}"; do
        if lsusb | grep -qiE "ID ${NVIDIA_VID}:${pid}"; then
            return 0
        fi
    done
    return 1
}

require_recovery() {
    if is_in_recovery; then
        ok "Jetson AGX Orin in recovery mode:"
        lsusb | grep -i "${NVIDIA_VID}:" || true
        return 0
    fi
    err "No Jetson AGX Orin detected in recovery mode."
    cat >&2 <<'EOF'

How to enter Force Recovery:
  1. Power the Jetson AGX Orin OFF completely.
  2. Press and HOLD the Force Recovery button (middle button on the side).
  3. While still holding it, press and release the Power button.
  4. Release Force Recovery after about 2 seconds.
  5. Connect a USB-C cable from the Jetson's FRONT USB-C flash port to this host.
EOF
    return 1
}
