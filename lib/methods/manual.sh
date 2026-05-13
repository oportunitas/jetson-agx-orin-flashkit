# Manual L4T BSP flash method (no SDK Manager / NVIDIA login at flash time).
#
# Profile vars used:
#   L4T_BSP_URL          (required)
#   L4T_BSP_SHA256       (optional; recommended)
#   L4T_ROOTFS_URL       (required)
#   L4T_ROOTFS_SHA256    (optional; recommended)
#   L4T_FLASH_TARGET     (optional; default jetson-agx-orin-devkit)

MANUAL_IMAGE_TAG="flashkit-manual-l4t:latest"

manual_ensure_image() {
    if ! docker image inspect "$MANUAL_IMAGE_TAG" >/dev/null 2>&1; then
        info "Building manual L4T flash image ($MANUAL_IMAGE_TAG) ..."
        docker build -t "$MANUAL_IMAGE_TAG" \
            -f "$DOCKER_DIR/Dockerfile.manual-l4t" "$DOCKER_DIR"
    fi
}

flash_manual() {
    local work_dir="$1" storage="$2" mode="${3:-flash}"  # flash | setup-only

    [[ -n "${L4T_BSP_URL:-}"    ]] || fatal "Profile missing L4T_BSP_URL"
    [[ -n "${L4T_ROOTFS_URL:-}" ]] || fatal "Profile missing L4T_ROOTFS_URL"
    local target="${L4T_FLASH_TARGET:-jetson-agx-orin-devkit}"

    manual_ensure_image
    mkdir -p "$work_dir"

    local container_prefix="jetson_flash_manual"
    [[ "$mode" == "setup-only" ]] && container_prefix="jetson_setup_manual"
    local container="${container_prefix}_$(date +%Y%m%d_%H%M%S)"

    cat <<EOF

==> ${mode^} via Manual L4T BSP (Docker)

    Profile         : $PROFILE_NAME
    BSP URL         : $L4T_BSP_URL
    Rootfs URL      : $L4T_ROOTFS_URL
    Flash target    : $target
    Storage         : $storage
    Work dir        : $work_dir
    Container       : $container
    Mode            : $mode

EOF

    local setup_only=0
    [[ "$mode" == "setup-only" ]] && setup_only=1

    docker run -it --rm \
        --privileged \
        --name "$container" \
        --network host \
        -v /dev/bus/usb:/dev/bus/usb \
        -v /dev:/dev \
        -v "$work_dir:/work" \
        -v "$DOCKER_DIR/manual-flash.sh:/usr/local/bin/manual-flash.sh:ro" \
        -e L4T_BSP_URL="$L4T_BSP_URL" \
        -e L4T_BSP_SHA256="${L4T_BSP_SHA256:-}" \
        -e L4T_ROOTFS_URL="$L4T_ROOTFS_URL" \
        -e L4T_ROOTFS_SHA256="${L4T_ROOTFS_SHA256:-}" \
        -e L4T_FLASH_TARGET="$target" \
        -e FLASH_STORAGE="$storage" \
        -e CUSTOM_ROOTFS_PATH="" \
        -e SETUP_ONLY="$setup_only" \
        "$MANUAL_IMAGE_TAG" \
        /usr/local/bin/manual-flash.sh
}
