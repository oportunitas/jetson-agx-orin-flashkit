# SDK Manager tarball management.
#
# Tarballs go in $SDKM_DIR (default: $REPO_ROOT/sdkmanager). Filenames
# matter: when an sdkmanager image with the right host-OS variant isn't
# already loaded into Docker, the matching tarball is auto-loaded by
# substring match on its filename. NVIDIA's original filenames
# ("sdkmanager-X.Y.Z.NNNN-Ubuntu_20.04_docker.tar.gz") work out of the box.

SDKM_DIR="${SDKM_DIR:-$REPO_ROOT/sdkmanager}"

# Echo paths of all tarballs in $SDKM_DIR (sorted).
sdkm_list_tarballs() {
    [[ -d "$SDKM_DIR" ]] || return 0
    find "$SDKM_DIR" -maxdepth 1 -type f \
        \( -name '*.tar.gz' -o -name '*.tar.xz' -o -name '*.tar' -o -name '*.tgz' \) \
        2>/dev/null | sort
}

# Echo loaded sdkmanager:* image refs.
sdkm_list_loaded() {
    docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null \
        | grep '^sdkmanager:' || true
}

# sdkm_classify_filename FILENAME -> echoes "JP5"|"JP6"|"?"
sdkm_classify_filename() {
    case "$1" in
        *Ubuntu_20.04*) echo "JP5" ;;
        *Ubuntu_22.04*) echo "JP6" ;;
        *Ubuntu_24.04*) echo "JP7" ;;  # speculative; future proof
        *)              echo "?"  ;;
    esac
}

# sdkm_find_tarball PATTERN -> echo first tarball whose basename contains PATTERN.
sdkm_find_tarball() {
    local pattern="$1" t
    while IFS= read -r t; do
        [[ -z "$t" ]] && continue
        if [[ "$(basename "$t")" == *"$pattern"* ]]; then
            echo "$t"
            return 0
        fi
    done < <(sdkm_list_tarballs)
    return 1
}

# sdkm_load_tarball PATH -> docker load (with progress).
sdkm_load_tarball() {
    local path="$1"
    [[ -f "$path" ]] || { err "Tarball not found: $path"; return 1; }
    info "Loading $(basename "$path") ..."
    docker load -i "$path"
}

# sdkm_ensure_for_filter FILTER
# Make sure an sdkmanager image whose tag contains FILTER is loaded into
# Docker. If not loaded but a matching tarball exists in $SDKM_DIR, auto-load
# it. Returns 0 if a matching image is present after the call, 1 otherwise.
sdkm_ensure_for_filter() {
    local filter="$1"
    if sdkm_list_loaded | grep -q -- "$filter"; then
        return 0
    fi
    local tarball
    tarball="$(sdkm_find_tarball "$filter" 2>/dev/null || true)"
    if [[ -z "$tarball" ]]; then
        return 1
    fi
    info "No sdkmanager image matching '$filter' loaded; auto-loading $tarball"
    sdkm_load_tarball "$tarball" >/dev/null || return 1
    sdkm_list_loaded | grep -q -- "$filter"
}
