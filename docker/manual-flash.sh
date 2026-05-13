#!/usr/bin/env bash
# Runs INSIDE the manual-l4t docker container. Handles BSP/rootfs download,
# extraction, apply_binaries, and flash. Bind-mount /work as the cache dir.
#
# Env vars (set by the caller):
#   L4T_BSP_URL               URL to jetson_linux_*.tbz2
#   L4T_BSP_SHA256            (optional) sha256 of the BSP tarball
#   L4T_ROOTFS_URL            URL to tegra_linux_sample-root-filesystem_*.tbz2
#                             (ignored when CUSTOM_ROOTFS_PATH is set)
#   L4T_ROOTFS_SHA256         (optional) sha256 of the rootfs tarball
#   L4T_FLASH_TARGET          e.g. jetson-agx-orin-devkit
#   FLASH_STORAGE             emmc | nvme
#   CUSTOM_ROOTFS_PATH        (optional) path inside container to a custom rootfs tarball
set -euo pipefail

cd /work

dl() {
    local url="$1" out="$2" sha="${3:-}"
    if [[ -f "$out" ]]; then
        echo ">>> $out already cached"
    else
        echo ">>> downloading $url"
        wget -q --show-progress -O "$out.tmp" "$url"
        mv "$out.tmp" "$out"
    fi
    if [[ -n "$sha" ]]; then
        echo "$sha  $out" | sha256sum -c -
    fi
}

# 1. BSP
dl "$L4T_BSP_URL" bsp.tbz2 "${L4T_BSP_SHA256:-}"
if [[ ! -d Linux_for_Tegra ]]; then
    echo ">>> extracting BSP"
    tar xf bsp.tbz2
fi

# 2. Rootfs (NVIDIA sample, or user-provided)
cd Linux_for_Tegra/rootfs
if [[ -n "${CUSTOM_ROOTFS_PATH:-}" ]]; then
    if [[ ! -e etc/passwd ]]; then
        echo ">>> extracting CUSTOM rootfs from $CUSTOM_ROOTFS_PATH"
        sudo tar xpf "$CUSTOM_ROOTFS_PATH" -C .
    else
        echo ">>> custom rootfs already extracted"
    fi
else
    if [[ ! -f /work/rootfs.tbz2 ]]; then
        cd /work
        dl "$L4T_ROOTFS_URL" rootfs.tbz2 "${L4T_ROOTFS_SHA256:-}"
        cd Linux_for_Tegra/rootfs
    fi
    if [[ ! -e etc/passwd ]]; then
        echo ">>> extracting NVIDIA sample rootfs"
        sudo tar xpf /work/rootfs.tbz2 -C .
    else
        echo ">>> rootfs already extracted"
    fi
fi
cd /work/Linux_for_Tegra

# 3. apply_binaries.sh (needs qemu-aarch64 host binfmt for chroot)
if [[ ! -f .flashkit-binaries-applied ]]; then
    echo ">>> running apply_binaries.sh"
    sudo ./apply_binaries.sh
    sudo touch .flashkit-binaries-applied
else
    echo ">>> binaries already applied (skip)"
fi

# Setup-only mode: stop here, before touching the Jetson.
if [[ "${SETUP_ONLY:-0}" == "1" ]]; then
    echo ">>> setup-only mode: BSP + rootfs prepared; skipping flash step."
    exit 0
fi

# 4. Flash
echo ">>> flashing target=$L4T_FLASH_TARGET storage=$FLASH_STORAGE"
case "$FLASH_STORAGE" in
    emmc)
        sudo ./flash.sh "$L4T_FLASH_TARGET" internal
        ;;
    nvme)
        # Initrd flash for external NVMe is the supported Orin path.
        sudo ./tools/kernel_flash/l4t_initrd_flash.sh \
            --external-device nvme0n1p1 \
            -c tools/kernel_flash/flash_l4t_external.xml \
            --showlogs --network usb0 \
            "$L4T_FLASH_TARGET" external
        ;;
    *)
        echo "Unknown FLASH_STORAGE='$FLASH_STORAGE' (expected emmc or nvme)" >&2
        exit 1
        ;;
esac

echo ">>> flash complete."
