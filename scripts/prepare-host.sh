#!/usr/bin/env bash
# One-time host setup: Docker, USB tools, qemu cross-arch support.
# Tested target: Ubuntu 26.04. Should also work on 22.04/24.04.
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "Run as a regular user; the script invokes sudo where needed." >&2
    exit 1
fi

echo "[1/4] Refreshing apt cache"
sudo apt-get update

echo "[2/4] Installing docker.io, usbutils, qemu-user-static, binfmt-support"
sudo apt-get install -y \
    docker.io \
    usbutils \
    qemu-user-static \
    binfmt-support

echo "[3/4] Enabling docker service"
sudo systemctl enable --now docker

if ! id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
    echo "[4/4] Adding $USER to docker group"
    sudo usermod -aG docker "$USER"
    echo
    echo "  >>> Log out and back in (or run 'newgrp docker') for docker group"
    echo "  >>> membership to take effect, then re-run flash steps."
else
    echo "[4/4] $USER already in docker group"
fi

echo
echo "Done. Sanity check: docker run --rm hello-world"
