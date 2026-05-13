# Jetson AGX Orin Flash Kit (`flashkit`)

A profile-driven app for flashing a Jetson AGX Orin Developer Kit to any
L4T-compatible OS image, from a host that doesn't run a JetPack-supported
Ubuntu (built around an Ubuntu 26.04 host, but works anywhere Docker runs).

```sh
./flashkit              # show help
./flashkit list         # what OS options are available
./flashkit flash        # interactive picker; flashes the chosen profile
```

## What you can flash

The Jetson Orin's boot ROM only accepts NVIDIA-signed bootloaders + L4T-style
images, so "any OS" really means "any L4T-derived image." Within that, the kit
supports four flavors of source:

| Method        | What it flashes                                              | Trade-offs |
| ------------- | ------------------------------------------------------------ | ---------- |
| `sdkmanager`  | Stock JetPack via NVIDIA's SDK Manager Docker image          | Easiest; needs NVIDIA Developer login at flash time |
| `manual`      | Stock L4T BSP downloaded directly from developer.nvidia.com  | No login at flash time; faster; fully scriptable for CI |
| `custom`      | Stock L4T BSP + a rootfs tarball **you supply**              | Bring your own Linux (Yocto, debootstrapped Debian, Nix, …) |
| (community)   | Same as `custom`, but with a curated profile per image       | Add a `.profile` for the image you want; see below |

## Built-in profiles

```
$ ./flashkit list
  jetpack-5.1.5         JetPack 5.1.5 (L4T 35.6.x, Ubuntu 20.04) via SDK Manager
  jetpack-6.2           JetPack 6.2 (L4T 36.4.x, Ubuntu 22.04) via SDK Manager
  l4t-manual-35.6.0     L4T 35.6.0 manual flash (Ubuntu 20.04 sample rootfs; no NVIDIA login)
  l4t-manual-36.4.0     L4T 36.4.0 manual flash (Ubuntu 22.04 sample rootfs; no NVIDIA login)
  custom-rootfs         Bring-your-own rootfs on L4T 36.4.0 BSP (set CUSTOM_ROOTFS_PATH)
```

## Quick start

### 1. One-time host setup

```sh
./flashkit prepare
```

Installs `docker.io`, `usbutils`, `qemu-user-binfmt` (or `qemu-user-static`
on older Ubuntu), and `binfmt-support`. Adds you to the `docker` group —
log out and back in (or `newgrp docker`) before continuing.

After this, verify aarch64 binfmt is registered (the manual / custom flash
methods need it for chroot during `apply_binaries.sh`):

```sh
cat /proc/sys/fs/binfmt_misc/qemu-aarch64       # must show "enabled"
```

If it doesn't exist, run `sudo systemctl restart systemd-binfmt`.

### 2. Put the Jetson into Force Recovery and connect USB

1. Power the Jetson **off** completely.
2. Hold the **Force Recovery** button (middle button on the side).
3. While holding, press and release the **Power** button.
4. Release Force Recovery after ~2 s.
5. Connect a USB-C cable from the Jetson's **front USB-C flash port** to the host.

Then:

```sh
./flashkit check
# [OK] Jetson AGX Orin in recovery mode:
# Bus 003 Device 042: ID 0955:7023 NVIDIA Corp. APX
```

### 3. (Only for `sdkmanager` profiles) Drop in SDK Manager tarballs

Go to https://developer.nvidia.com/sdk-manager (log in) and download the
Docker variant matching each JetPack family you want to flash:

- `sdkmanager-X.Y.Z.NNNN-Ubuntu_20.04_docker.tar.gz` → JetPack 5.x
- `sdkmanager-X.Y.Z.NNNN-Ubuntu_22.04_docker.tar.gz` → JetPack 6.x

Drop them into `sdkmanager/` (in this repo). Keep NVIDIA's original filenames
so flashkit can auto-classify by the `Ubuntu_XX.YY` substring.

```sh
mv ~/Downloads/sdkmanager-*.tar.gz sdkmanager/
./flashkit sdkm list                # show what's there + what's loaded
```

You can either pre-load everything once:

```sh
./flashkit sdkm load-all            # docker load every tarball in sdkmanager/
```

…or skip this and let `flashkit flash` auto-load the matching tarball the
first time it's needed. Multiple variants happily coexist.

`manual` and `custom` profiles don't need any of this.

### 4. Flash

Interactive:

```sh
./flashkit flash
```

Pick the profile from the menu and SDK Manager / `flash.sh` runs. Or by name:

```sh
./flashkit flash jetpack-5.1.5
./flashkit flash l4t-manual-36.4.0
./flashkit flash jetpack-6.2 --storage nvme
```

### 5. Bring your own rootfs

```sh
CUSTOM_ROOTFS_PATH=/path/to/rootfs.tar.gz \
  ./flashkit flash custom-rootfs
```

The tarball must:
- be aarch64
- contain the rootfs at the tar root (i.e. `bin/ etc/ usr/`, not `rootfs/bin/`)
- include enough to boot (init, libc, kernel modules will be supplied by the L4T BSP)

For deeply customized builds, copy `profiles/custom-rootfs.profile` to
`profiles.d/<your-name>.profile`, pin a specific BSP URL + SHA256, and call
`./flashkit flash <your-name>`.

## Profile format

Profiles are bash-sourced files; no YAML parser required. Each one defines
a small set of variables:

```bash
# profiles/<name>.profile
PROFILE_NAME="<name>"
PROFILE_DESC="<one-line description>"
PROFILE_METHOD="sdkmanager" | "manual" | "custom"

# Method-specific (sdkmanager):
JETPACK_VERSION="6.2"
SDKM_IMAGE_FILTER="Ubuntu_22.04"
SDKM_TARGET="JETSON_AGX_ORIN_TARGETS"

# Method-specific (manual / custom):
L4T_BSP_URL="https://..."
L4T_BSP_SHA256="..."          # optional but recommended
L4T_ROOTFS_URL="https://..."  # manual only; ignored for custom
L4T_ROOTFS_SHA256="..."
L4T_FLASH_TARGET="jetson-agx-orin-devkit"

# Common:
DEFAULT_STORAGE="emmc"        # emmc | nvme
SUPPORTED_STORAGE="emmc nvme" # space-separated list
```

Built-in profiles live in `profiles/` (version-controlled). Your own
additions go in `profiles.d/` (gitignored). The local directory wins on
name collision.

## Adding a community / custom image

Most "community Jetson images" are just an L4T BSP plus a custom rootfs.
Make a profile for it:

```sh
cp profiles/custom-rootfs.profile profiles.d/myorg-yocto.profile
$EDITOR profiles.d/myorg-yocto.profile        # adjust PROFILE_NAME / DESC / BSP URL
CUSTOM_ROOTFS_PATH=~/yocto-build.tar.gz \
  ./flashkit flash myorg-yocto
```

For images that ship a complete L4T tarball (BSP + rootfs glued together),
adapt `profiles/l4t-manual-*.profile` instead — point it at the community
tarball URLs and add the SHA256s.

## Storage targets

- `emmc` — default for AGX Orin Devkit; SDK Manager / `flash.sh` writes the
  on-module eMMC.
- `nvme` — flashes onto an installed NVMe SSD. SDK Manager handles this
  automatically. The `manual` / `custom` methods route through
  `tools/kernel_flash/l4t_initrd_flash.sh` with `--external-device nvme0n1p1`.
  Less battle-tested in this kit; expect to iterate.

Override per-flash:

```sh
./flashkit flash jetpack-6.2 --storage nvme
```

## Caches and work dirs

Each profile gets its own cache directory under `work/`:

```
work/
├── jetpack-5.1.5/      # SDK Manager state + downloaded BSP
├── jetpack-6.2/
├── l4t-manual-36.4.0/  # raw BSP + rootfs tarballs
└── custom-rootfs/
```

Switching profiles never re-downloads. To wipe everything:

```sh
./flashkit clean --all
```

Or one profile:

```sh
./flashkit clean l4t-manual-36.4.0
```

To put the cache somewhere with more space:

```sh
WORK_BASE=/mnt/big/jetson-cache ./flashkit flash jetpack-6.2
```

## After the flash

The Jetson reboots into the OOBE wizard. Connect a keyboard, mouse, and
HDMI display to the Jetson and complete OOBE on the device. Then, if you
flashed JetPack via SDK Manager or a stock L4T sample rootfs and want
CUDA / TensorRT / cuDNN / VPI etc.:

```sh
# on the Jetson
sudo apt update
sudo apt install nvidia-jetpack
```

## Troubleshooting

### "File System and OS: Failed" mid-flash (sdkmanager method)

Host kernel doesn't have aarch64 binfmt registered. Fix:

```sh
sudo apt install qemu-user-binfmt binfmt-support
sudo systemctl restart systemd-binfmt
cat /proc/sys/fs/binfmt_misc/qemu-aarch64    # must say "enabled"
```

Re-run the flash. The downloaded BSP is cached, so retry skips straight to
the rootfs prep step.

### `apply_binaries.sh` fails inside the manual container

Same root cause: binfmt registration missing on the host kernel. The
container can't register binfmt itself; it inherits whatever the host has.
Fix as above.

### `[ERROR] No Jetson AGX Orin detected in recovery mode`

- Recovery sequence: power off, hold Force Recovery, tap Power, release.
- Use the **front** USB-C (the labeled flash port), not rear ports.
- Try a different USB-C cable; many are charge-only.
- If your AGX Orin enumerates with a different PID than `7023`, edit
  `ORIN_PIDS` in `lib/recovery.sh`.

### "EXT4 file system" warning during `sdkmanager` flash

Often a false positive caused by Docker's overlay magic. Choose **Ignore**.
If a real non-ext4 host filesystem causes hardlink errors later, relocate:

```sh
WORK_BASE=/mnt/ext4-volume/jetson-cache ./flashkit flash jetpack-5.1.5
```

### SDK Manager hangs on "Waiting for the device to boot"

Flash succeeded; SDK Manager is trying post-flash SSH installs. We
deselect those, but if you somehow hit this, `Ctrl-C` is safe — eMMC is
already written.

### Permission denied writing `work/`

The SDK Manager image runs as UID 1000. The `sdkmanager` method's flash
script aligns ownership automatically. To clean up later:

```sh
./flashkit clean --all     # falls back to sudo rm -rf if needed
```

## Files

```
.
├── flashkit                  # main CLI entry point
├── README.md
├── Makefile                  # convenience wrapper around flashkit
├── .gitignore
├── docker/
│   ├── Dockerfile.manual-l4t # base image for manual + custom methods
│   └── manual-flash.sh       # flash script run inside the container
├── lib/
│   ├── common.sh             # logging, paths
│   ├── ui.sh                 # interactive picker
│   ├── profile.sh            # profile loader / lister
│   ├── recovery.sh           # recovery-mode detection
│   └── methods/
│       ├── sdkmanager.sh
│       ├── manual.sh
│       └── custom.sh
├── profiles/                 # built-in OS profiles
│   ├── jetpack-5.1.5.profile
│   ├── jetpack-6.2.profile
│   ├── l4t-manual-35.6.0.profile
│   ├── l4t-manual-36.4.0.profile
│   └── custom-rootfs.profile
├── profiles.d/               # your local profiles (gitignored)
├── sdkmanager/               # drop SDK Manager tarballs here (gitignored except README)
│   └── README.md
└── scripts/
    ├── prepare-host.sh
    ├── check-recovery.sh
    ├── load-sdkmanager.sh
    └── flash.sh              # legacy back-compat wrapper around flashkit
```

## Why a flash kit

NVIDIA SDK Manager officially supports Ubuntu 18.04 / 20.04 / 22.04 hosts.
Newer distros (Ubuntu 26.04, Fedora, Arch, …) hit dependency mismatches
that are tedious to work around natively. Running flash tooling inside
Docker sidesteps the host-OS issue entirely — Docker sees `0955:7023` USB
devices in recovery mode regardless of what kernel/distro the host runs.

## References

- NVIDIA SDK Manager: https://developer.nvidia.com/sdk-manager
- SDK Manager Docker docs: https://docs.nvidia.com/sdk-manager/sdkm-docker/
- Jetson Linux (L4T) downloads: https://developer.nvidia.com/embedded/jetson-linux
- AGX Orin Developer Kit user guide: https://developer.nvidia.com/embedded/learn/jetson-agx-orin-devkit-user-guide
