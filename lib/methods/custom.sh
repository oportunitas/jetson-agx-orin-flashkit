# Custom rootfs flash method. Uses the manual L4T BSP plus a user-supplied
# rootfs tarball (in place of NVIDIA's sample rootfs).
#
# Profile vars used:
#   L4T_BSP_URL          (required) — BSP only; rootfs comes from user
#   L4T_BSP_SHA256       (optional)
#   L4T_FLASH_TARGET     (optional; default jetson-agx-orin-devkit)
#
# The user must set CUSTOM_ROOTFS_PATH at flash time:
#   CUSTOM_ROOTFS_PATH=/path/to/rootfs.tar.gz flashkit flash custom-rootfs

flash_custom() {
    local work_dir="$1" storage="$2"

    [[ -n "${L4T_BSP_URL:-}" ]] || fatal "Profile missing L4T_BSP_URL"
    [[ -n "${CUSTOM_ROOTFS_PATH:-}" ]] || \
        fatal "CUSTOM_ROOTFS_PATH not set. Pass it as an env var: CUSTOM_ROOTFS_PATH=/path/to/rootfs.tar.gz flashkit flash $PROFILE_NAME"
    [[ -f "$CUSTOM_ROOTFS_PATH" ]] || fatal "Custom rootfs not found: $CUSTOM_ROOTFS_PATH"

    local target="${L4T_FLASH_TARGET:-jetson-agx-orin-devkit}"
    local rootfs_abs
    rootfs_abs="$(readlink -f "$CUSTOM_ROOTFS_PATH")"

    manual_ensure_image
    mkdir -p "$work_dir"

    local container="jetson_flash_custom_$(date +%Y%m%d_%H%M%S)"

    cat <<EOF

==> Flashing via Custom Rootfs on stock L4T BSP

    Profile         : $PROFILE_NAME
    BSP URL         : $L4T_BSP_URL
    Custom rootfs   : $rootfs_abs
    Flash target    : $target
    Storage         : $storage
    Work dir        : $work_dir
    Container       : $container

EOF

    docker run -it --rm \
        --privileged \
        --name "$container" \
        --network host \
        -v /dev/bus/usb:/dev/bus/usb \
        -v /dev:/dev \
        -v "$work_dir:/work" \
        -v "$rootfs_abs:/rootfs.tar:ro" \
        -v "$DOCKER_DIR/manual-flash.sh:/usr/local/bin/manual-flash.sh:ro" \
        -e L4T_BSP_URL="$L4T_BSP_URL" \
        -e L4T_BSP_SHA256="${L4T_BSP_SHA256:-}" \
        -e L4T_ROOTFS_URL="" \
        -e L4T_ROOTFS_SHA256="" \
        -e L4T_FLASH_TARGET="$target" \
        -e FLASH_STORAGE="$storage" \
        -e CUSTOM_ROOTFS_PATH="/rootfs.tar" \
        "$MANUAL_IMAGE_TAG" \
        /usr/local/bin/manual-flash.sh
}
