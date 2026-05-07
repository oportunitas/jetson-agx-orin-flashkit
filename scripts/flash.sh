#!/usr/bin/env bash
# Flash JetPack/L4T to a Jetson AGX Orin in recovery mode using NVIDIA's
# SDK Manager Docker image.
#
# Run AFTER:
#   1. scripts/prepare-host.sh         (one-time host setup)
#   2. scripts/load-sdkmanager.sh ...  (load the NVIDIA SDK Manager tarball)
#   3. Putting the Jetson into Force Recovery and connecting USB-C
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# shellcheck disable=SC1091
source "$REPO_ROOT/config.env"

WORK_DIR="${WORK_DIR:-$REPO_ROOT/work}"

# Preflight: refuse to flash without a Jetson visible in recovery mode.
"$SCRIPT_DIR/check-recovery.sh"

# Resolve the SDK Manager image. Prefer SDKM_IMAGE if set and present;
# otherwise pick the first sdkmanager:* image available locally.
if [[ -z "${SDKM_IMAGE:-}" ]] || ! docker image inspect "$SDKM_IMAGE" >/dev/null 2>&1; then
    detected="$(docker images --format '{{.Repository}}:{{.Tag}}' \
                 | grep -m1 '^sdkmanager:' || true)"
    if [[ -n "$detected" ]]; then
        if [[ -n "${SDKM_IMAGE:-}" ]]; then
            echo "SDKM_IMAGE='$SDKM_IMAGE' not present; using detected '$detected'."
        fi
        SDKM_IMAGE="$detected"
    else
        echo "ERROR: no sdkmanager Docker image found locally." >&2
        echo "Run: scripts/load-sdkmanager.sh /path/to/sdkmanager-...tar.gz" >&2
        exit 1
    fi
fi

# Persist NVIDIA Developer login token and downloaded BSP artifacts across
# runs so the second flash doesn't re-download ~5 GB.
mkdir -p "$WORK_DIR/nvsdkm" "$WORK_DIR/nvidia_sdk"

# The SDK Manager image runs as user 'nvidia' (UID 1000). If the host user
# is not UID 1000, the bind mounts fail with permission errors -- fix that
# by aligning ownership.
if [[ "$(stat -c %u "$WORK_DIR/nvsdkm")" -ne 1000 ]]; then
    echo "Aligning $WORK_DIR ownership with the container's nvidia user (UID 1000)."
    sudo chown -R 1000:1000 "$WORK_DIR"
fi

# /media/$USER:/media/nvidia is documented by NVIDIA for SDK Manager docker;
# ensure the host side exists so the bind mount won't fail on minimal hosts.
HOST_MEDIA="/media/$USER"
[[ -d "$HOST_MEDIA" ]] || sudo mkdir -p "$HOST_MEDIA"

CONTAINER_NAME="jetson_flash_$(date +%Y%m%d_%H%M%S)"

cat <<EOF

==> Flashing Jetson AGX Orin via SDK Manager (Docker)

    JetPack version : $JETPACK_VERSION
    Target          : $SDKM_TARGET
    Storage         : eMMC (default; SDK Manager autoselects for AGX Orin Devkit)
    SDKM image      : $SDKM_IMAGE
    Work dir        : $WORK_DIR
    Container name  : $CONTAINER_NAME

You may be prompted for NVIDIA Developer credentials on first run; the
login token is then saved in $WORK_DIR/nvsdkm and reused on subsequent
runs. Total runtime: ~15-30 minutes (includes a ~5 GB download on first
run, cached afterwards).

EOF

docker run -it --rm \
    --privileged \
    --name "$CONTAINER_NAME" \
    --network host \
    -v /dev/bus/usb:/dev/bus/usb \
    -v /dev:/dev \
    -v "$WORK_DIR/nvsdkm:/home/nvidia/.nvsdkm" \
    -v "$WORK_DIR/nvidia_sdk:/home/nvidia/nvidia_sdk" \
    -v "$HOST_MEDIA:/media/nvidia:slave" \
    "$SDKM_IMAGE" \
        --cli \
        --action install \
        --login-type devzone \
        --product Jetson \
        --version "$JETPACK_VERSION" \
        --show-all-versions \
        --target-os Linux \
        --host \
        --target "$SDKM_TARGET" \
        --flash all \
        --license accept \
        --stay-logged-in true \
        --exit-on-finish true \
        --deselect 'Jetson SDK Components'
