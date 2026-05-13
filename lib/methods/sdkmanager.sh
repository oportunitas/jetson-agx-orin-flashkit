# SDK Manager flash method. Profile vars used:
#   JETPACK_VERSION       (required)
#   SDKM_IMAGE_FILTER     (optional; substring used to pick a loaded image)
#   SDKM_TARGET           (optional; default JETSON_AGX_ORIN_TARGETS)
#   SDKM_IMAGE            (optional; pin a specific image tag)

flash_sdkmanager() {
    local work_dir="$1" storage="$2"

    local filter="${SDKM_IMAGE_FILTER:-Ubuntu_}"

    # Try to auto-load a matching tarball from sdkmanager/ if no matching
    # docker image is loaded yet.
    sdkm_ensure_for_filter "$filter" || true

    local image="${SDKM_IMAGE:-}"
    if [[ -z "$image" ]] || ! docker image inspect "$image" >/dev/null 2>&1; then
        image="$(sdkm_list_loaded | grep -m1 -- "$filter" || true)"
        if [[ -z "$image" ]]; then
            local fallback
            fallback="$(sdkm_list_loaded | head -n1 || true)"
            if [[ -n "$fallback" ]]; then
                warn "No sdkmanager image matching '$filter'; falling back to $fallback."
                image="$fallback"
            else
                err "No sdkmanager Docker image loaded for '$filter'."
                err "Drop a tarball into sdkmanager/ and run 'flashkit sdkm load-all',"
                err "or pass a path: flashkit sdkm load /path/to/tarball.tar.gz"
                fatal "Aborting flash."
            fi
        fi
    fi

    mkdir -p "$work_dir/nvsdkm" "$work_dir/nvidia_sdk"
    if [[ "$(stat -c %u "$work_dir/nvsdkm")" -ne 1000 ]]; then
        info "Aligning $work_dir ownership to UID 1000 (matches container's nvidia user)."
        sudo chown -R 1000:1000 "$work_dir"
    fi

    local host_media="/media/$USER"
    [[ -d "$host_media" ]] || sudo mkdir -p "$host_media"

    local container="jetson_flash_$(date +%Y%m%d_%H%M%S)"
    local target="${SDKM_TARGET:-JETSON_AGX_ORIN_TARGETS}"

    cat <<EOF

==> Flashing via SDK Manager (Docker)

    Profile         : $PROFILE_NAME
    JetPack version : $JETPACK_VERSION
    SDK Mgr image   : $image
    Target          : $target
    Storage         : $storage
    Work dir        : $work_dir
    Container       : $container

EOF

    local -a sdkm_args=(
        --cli
        --action install
        --login-type devzone
        --product Jetson
        --version "$JETPACK_VERSION"
        --target-os Linux
        --host
        --target "$target"
        --flash all
        --license accept
        --stay-logged-in true
        --exit-on-finish true
        --deselect 'Jetson SDK Components'
    )

    if [[ "$storage" == "nvme" ]]; then
        sdkm_args+=(--storage NVMe)
    fi

    docker run -it --rm \
        --privileged \
        --name "$container" \
        --network host \
        -v /dev/bus/usb:/dev/bus/usb \
        -v /dev:/dev \
        -v "$work_dir/nvsdkm:/home/nvidia/.nvsdkm" \
        -v "$work_dir/nvidia_sdk:/home/nvidia/nvidia_sdk" \
        -v "$host_media:/media/nvidia:slave" \
        "$image" \
        "${sdkm_args[@]}"
}
