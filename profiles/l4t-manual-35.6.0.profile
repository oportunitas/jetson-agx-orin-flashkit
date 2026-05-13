# L4T 35.6.0 manual flash (JP5-era; no SDK Manager / NVIDIA login at flash time).
#
# Downloads NVIDIA's BSP + sample rootfs tarballs directly and runs
# flash.sh inside a small Ubuntu 22.04 container.
#
# To pin integrity, fill in the SHA256s after first verified download:
#   sha256sum work/<profile>/bsp.tbz2 work/<profile>/rootfs.tbz2

PROFILE_NAME="l4t-manual-35.6.0"
PROFILE_DESC="L4T 35.6.0 manual flash (Ubuntu 20.04 sample rootfs; no NVIDIA login)"
PROFILE_METHOD="manual"

L4T_BSP_URL="https://developer.nvidia.com/downloads/embedded/l4t/r35_release_v6.0/release/jetson_linux_r35.6.0_aarch64.tbz2"
L4T_ROOTFS_URL="https://developer.nvidia.com/downloads/embedded/l4t/r35_release_v6.0/release/tegra_linux_sample-root-filesystem_r35.6.0_aarch64.tbz2"
# L4T_BSP_SHA256=""
# L4T_ROOTFS_SHA256=""

L4T_FLASH_TARGET="jetson-agx-orin-devkit"

DEFAULT_STORAGE="emmc"
SUPPORTED_STORAGE="emmc nvme"
