# JetPack 6.2 — current JP6 line; L4T 36.4.x; Ubuntu 22.04 rootfs.
# Method: SDK Manager (NVIDIA Developer login required at flash time).

PROFILE_NAME="jetpack-6.2"
PROFILE_DESC="JetPack 6.2 (L4T 36.4.x, Ubuntu 22.04) via SDK Manager"
PROFILE_METHOD="sdkmanager"

JETPACK_VERSION="6.2"
SDKM_IMAGE_FILTER="Ubuntu_22.04"
SDKM_TARGET="JETSON_AGX_ORIN_TARGETS"

DEFAULT_STORAGE="emmc"
SUPPORTED_STORAGE="emmc nvme"
