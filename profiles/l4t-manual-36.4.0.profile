# L4T 36.4.0 manual flash (JP6-era; no SDK Manager / NVIDIA login at flash time).
#
# Downloads NVIDIA's BSP + sample rootfs tarballs directly and runs
# flash.sh inside a small Ubuntu 22.04 container.

PROFILE_NAME="l4t-manual-36.4.0"
PROFILE_DESC="L4T 36.4.0 manual flash (Ubuntu 22.04 sample rootfs; no NVIDIA login)"
PROFILE_METHOD="manual"

L4T_BSP_URL="https://developer.nvidia.com/downloads/embedded/l4t/r36_release_v4.0/release/jetson_linux_r36.4.0_aarch64.tbz2"
L4T_ROOTFS_URL="https://developer.nvidia.com/downloads/embedded/l4t/r36_release_v4.0/release/tegra_linux_sample-root-filesystem_r36.4.0_aarch64.tbz2"
# L4T_BSP_SHA256=""
# L4T_ROOTFS_SHA256=""

L4T_FLASH_TARGET="jetson-agx-orin-devkit"

DEFAULT_STORAGE="emmc"
SUPPORTED_STORAGE="emmc nvme"
