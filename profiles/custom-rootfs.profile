# Custom rootfs flash (bring your own Linux).
#
# Uses NVIDIA's stock L4T BSP for the bootloader / kernel / firmware, but
# replaces NVIDIA's sample rootfs with a tarball you supply. Useful for:
#   - Yocto-built rootfs
#   - debootstrapped Debian/Ubuntu variants
#   - Stripped-down embedded rootfs
#   - NixOS-on-Jetson community ports (rootfs portion)
#
# Requirements at flash time:
#   CUSTOM_ROOTFS_PATH=/path/to/rootfs.tar[.gz|.bz2]   (required env var)
# Example:
#   CUSTOM_ROOTFS_PATH=~/builds/yocto-jetson.tar.gz \
#     ./flashkit flash custom-rootfs
#
# The rootfs tarball must contain the rootfs at its root (i.e. tar contains
# bin/ etc/ usr/ ..., not a top-level rootfs/ dir). It must be aarch64.

PROFILE_NAME="custom-rootfs"
PROFILE_DESC="Bring-your-own rootfs on L4T 36.4.0 BSP (set CUSTOM_ROOTFS_PATH)"
PROFILE_METHOD="custom"

# Defaults to the latest JP6-era BSP. Override L4T_BSP_URL via env or
# duplicate this profile to pin a different BSP version.
L4T_BSP_URL="https://developer.nvidia.com/downloads/embedded/l4t/r36_release_v4.0/release/jetson_linux_r36.4.0_aarch64.tbz2"
# L4T_BSP_SHA256=""
L4T_FLASH_TARGET="jetson-agx-orin-devkit"

DEFAULT_STORAGE="emmc"
SUPPORTED_STORAGE="emmc nvme"
