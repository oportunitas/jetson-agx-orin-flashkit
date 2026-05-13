# Profile loader / lister / validator.

# list_profiles -> echoes <name>\t<desc> per line.
list_profiles() {
    local d f name desc
    declare -A seen
    for d in "$PROFILES_LOCAL_DIR" "$PROFILES_DIR"; do
        [[ -d "$d" ]] || continue
        for f in "$d"/*.profile; do
            [[ -f "$f" ]] || continue
            name="$(basename "$f" .profile)"
            [[ -n "${seen[$name]:-}" ]] && continue
            seen[$name]=1
            desc="$(grep -m1 '^PROFILE_DESC=' "$f" | sed -E 's/^PROFILE_DESC="?(.*)"?$/\1/' | sed 's/"$//')"
            printf "%s\t%s\n" "$name" "$desc"
        done
    done | sort -u
}

# resolve_profile NAME -> echoes path; returns 1 if not found.
resolve_profile() {
    local name="$1" p
    for p in "$PROFILES_LOCAL_DIR/$name.profile" "$PROFILES_DIR/$name.profile"; do
        [[ -f "$p" ]] && { echo "$p"; return 0; }
    done
    return 1
}

# load_profile NAME — sources the profile, exporting PROFILE_* / method vars.
load_profile() {
    local name="$1" path
    path="$(resolve_profile "$name")" \
        || fatal "Profile not found: $name (run 'flashkit list')"

    PROFILE_NAME="" PROFILE_DESC="" PROFILE_METHOD="" DEFAULT_STORAGE=""
    SUPPORTED_STORAGE=""
    JETPACK_VERSION="" SDKM_IMAGE_FILTER="" SDKM_TARGET=""
    L4T_BSP_URL="" L4T_BSP_SHA256="" L4T_ROOTFS_URL="" L4T_ROOTFS_SHA256=""
    L4T_FLASH_TARGET=""

    # shellcheck disable=SC1090
    source "$path"

    [[ -n "$PROFILE_NAME"   ]] || fatal "Profile $path missing PROFILE_NAME"
    [[ -n "$PROFILE_METHOD" ]] || fatal "Profile $path missing PROFILE_METHOD"
    [[ -n "$DEFAULT_STORAGE" ]] || DEFAULT_STORAGE=emmc
    [[ -n "$SUPPORTED_STORAGE" ]] || SUPPORTED_STORAGE="emmc"

    case "$PROFILE_METHOD" in
        sdkmanager|manual|custom) ;;
        *) fatal "Profile $name has unknown PROFILE_METHOD: $PROFILE_METHOD" ;;
    esac
}

# storage_supported PROFILE_STORAGE_LIST STORAGE -> 0/1
storage_supported() {
    local list="$1" want="$2" s
    for s in $list; do
        [[ "$s" == "$want" ]] && return 0
    done
    return 1
}

# profile_check
# Requires a profile to be already loaded (load_profile NAME). Sets:
#   PROFILE_READY  -> "yes" | "auto" | "no"
#   PROFILE_HINT   -> one-line explanation
# "yes"  = ready to flash now
# "auto" = missing assets but they'll be fetched automatically (no user action)
# "no"   = blocked; user must do something (download a gated tarball, set an env var, ...)
profile_check() {
    PROFILE_READY="" PROFILE_HINT=""
    case "$PROFILE_METHOD" in
        sdkmanager)
            local filter="${SDKM_IMAGE_FILTER:-Ubuntu_}"
            if sdkm_list_loaded | grep -q -- "$filter"; then
                PROFILE_READY="yes"
                PROFILE_HINT="SDK Manager image '$filter' loaded"
            elif sdkm_find_tarball "$filter" >/dev/null 2>&1; then
                PROFILE_READY="auto"
                PROFILE_HINT="tarball in sdkmanager/ will be loaded on flash"
            else
                PROFILE_READY="no"
                PROFILE_HINT="missing '$filter' SDK Manager tarball (login at developer.nvidia.com/sdk-manager, drop into sdkmanager/)"
            fi
            ;;
        manual)
            local cache="${WORK_BASE}/${PROFILE_NAME}"
            if [[ -f "$cache/Linux_for_Tegra/.flashkit-binaries-applied" ]]; then
                PROFILE_READY="yes"
                PROFILE_HINT="BSP + rootfs cached and prepared"
            elif [[ -f "$cache/bsp.tbz2" || -f "$cache/rootfs.tbz2" ]]; then
                PROFILE_READY="auto"
                PROFILE_HINT="partial cache present; will resume download (~few GB)"
            else
                PROFILE_READY="auto"
                PROFILE_HINT="will auto-download BSP + rootfs (~3-5 GB) on flash"
            fi
            ;;
        custom)
            local rootfs="${CUSTOM_ROOTFS_PATH:-}"
            if [[ -n "$rootfs" && -f "$rootfs" ]]; then
                PROFILE_READY="yes"
                PROFILE_HINT="custom rootfs at $rootfs"
            else
                PROFILE_READY="no"
                PROFILE_HINT="set CUSTOM_ROOTFS_PATH=/path/to/rootfs.tar.gz before flash"
            fi
            ;;
    esac
}

# profile_status_badge PROFILE_READY -> echoes a short colored badge.
profile_status_badge() {
    case "$1" in
        yes)  printf "%bready%b      " "$C_GREEN"  "$C_RESET" ;;
        auto) printf "%bauto-fetch%b " "$C_BLUE"   "$C_RESET" ;;
        no)   printf "%bblocked%b    " "$C_RED"    "$C_RESET" ;;
        *)    printf "?           " ;;
    esac
}
