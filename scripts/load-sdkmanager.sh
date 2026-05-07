#!/usr/bin/env bash
# Load the NVIDIA SDK Manager Docker tarball into the local Docker daemon.
#
# Download manually from https://developer.nvidia.com/sdk-manager (login
# required). Pick the "Ubuntu 20.04 Docker image" variant - it matches the
# JetPack 5.x host requirements that we are sidestepping by containerizing.
set -euo pipefail

if [[ $# -ne 1 ]]; then
    cat >&2 <<EOF
Usage: $0 <path-to-sdkmanager-X.Y.Z.NNNN-Ubuntu_20.04_docker.tar.gz>

Download from https://developer.nvidia.com/sdk-manager (NVIDIA Developer
account required, free).
EOF
    exit 1
fi

TARBALL="$1"
if [[ ! -f "$TARBALL" ]]; then
    echo "Tarball not found: $TARBALL" >&2
    exit 1
fi

echo "Loading $TARBALL ..."
docker load -i "$TARBALL"

echo
echo "sdkmanager images now available:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" \
    | awk 'NR==1 || /^sdkmanager/'

echo
echo "If the tag is not 'sdkmanager:latest', set SDKM_IMAGE in config.env"
echo "(or export SDKM_IMAGE before running scripts/flash.sh)."
