# Jetson AGX Orin Flash Kit

Flash NVIDIA JetPack 5.1.5 (L4T 35.6.x, Ubuntu 20.04) to a Jetson AGX Orin
Developer Kit from a host that is **not** on a JetPack-supported Ubuntu
version. This kit was built around an Ubuntu 26.04 host but works on any
Linux host that can run Docker.

The flash itself runs inside NVIDIA's official SDK Manager Docker image, so
the host's distro/kernel doesn't matter as long as Docker can pass through
USB to the Jetson in recovery mode.

## What gets flashed

- JetPack 5.1.5 (L4T 35.6.x)
- Ubuntu 20.04 root filesystem to the AGX Orin's internal eMMC
- **Only the OS.** SDK components (CUDA, TensorRT, cuDNN, VPI, ...) are
  deselected during flash. Install them on-device after first boot with
  `sudo apt install nvidia-jetpack`.

## Prerequisites

### Host

- Linux with Docker (any modern distro; built around Ubuntu 26.04)
- ~30 GB free disk space (BSP downloads + flash artifacts)
- A USB-C cable (data-capable, not power-only)
- An NVIDIA Developer account — free, https://developer.nvidia.com

### Hardware

- Jetson AGX Orin Developer Kit (any RAM SKU; 32 GB / 64 GB / Industrial)
- Power supply (the included 65 W USB-C adapter)
- USB-C cable from the Jetson's **front USB-C flash port** to the host

## One-time setup

### 1. Install host dependencies

```sh
make prepare
# or directly: ./scripts/prepare-host.sh
```

If your user wasn't already in the `docker` group, log out and back in
(or run `newgrp docker`) before continuing.

### 2. Download the SDK Manager Docker image

1. Open https://developer.nvidia.com/sdk-manager
2. Log in with your NVIDIA Developer account
3. Download the **Ubuntu 20.04 Docker image** variant (a `.tar.gz` of a few
   hundred MB)

### 3. Load the image into Docker

```sh
make load IMG=/path/to/sdkmanager-X.Y.Z.NNNN-Ubuntu_20.04_docker.tar.gz
# or directly: ./scripts/load-sdkmanager.sh /path/to/...tar.gz
```

`docker load` typically tags the image as `sdkmanager:latest`. If yours
ends up tagged differently, set `SDKM_IMAGE` in `config.env` (or export
it) — `flash.sh` also auto-detects when there's only one `sdkmanager:*`
image present.

## Flashing

### 1. Put the Jetson into Force Recovery mode

1. Power the Jetson **off** completely (unplug power if needed).
2. Press and **hold** the **Force Recovery** button (middle button on the
   side of the carrier board).
3. While still holding, press and release the **Power** button.
4. Release Force Recovery after ~2 seconds.
5. Connect the USB-C cable from the Jetson's **front USB-C flash port** to
   the host. (The rear USB-C ports are not the flash port.)

The Jetson will appear silent — no display output, no fan ramp. That's
expected: recovery mode boots only enough USB device firmware to accept a
flash payload.

### 2. Verify the host sees it

```sh
make check
# or: ./scripts/check-recovery.sh
```

Expected:

```
[OK] Jetson AGX Orin in recovery mode:
Bus 003 Device 042: ID 0955:7023 NVIDIA Corp. APX
```

### 3. Run the flash

```sh
make flash
# or: ./scripts/flash.sh
```

What happens, in order:
- SDK Manager prompts for NVIDIA Developer credentials on first run; the
  token is persisted in `work/nvsdkm` and reused next time.
- It downloads ~5 GB of L4T BSP artifacts to `work/nvidia_sdk` (cached for
  subsequent runs).
- It flashes the eMMC. ~15–30 minutes end-to-end on a typical host.
- The Jetson reboots into the OOBE (Out-Of-Box Experience) wizard. Plug a
  keyboard, mouse, and HDMI display into the Jetson and complete OOBE
  on-device.

### 4. After the flash

Once the freshly-flashed Jetson is at a desktop, install the JetPack
runtime if you need CUDA, TensorRT, etc.:

```sh
# on the Jetson:
sudo apt update
sudo apt install nvidia-jetpack
```

That installs the full JetPack 5.1.5 runtime stack on top of the OS we
just flashed.

## Configuration

`config.env` defines:

| Variable          | Default                         | Notes                                            |
| ----------------- | ------------------------------- | ------------------------------------------------ |
| `JETPACK_VERSION` | `5.1.5`                         | Any 5.x string SDK Manager recognizes            |
| `SDKM_TARGET`     | `JETSON_AGX_ORIN_TARGETS`       | Family target; SDK Manager autodetects the SOM   |
| `SDKM_IMAGE`      | (auto-detected)                 | Override when multiple sdkmanager images coexist |
| `WORK_DIR`        | `<repo>/work`                   | Persisted state + downloads                      |

Override per-run by exporting the variable: `JETPACK_VERSION=5.1.4 make flash`.

To target NVMe instead of eMMC, append `--storage NVMe` to the SDK Manager
arguments at the bottom of `scripts/flash.sh`. (Default eMMC matches the
choice this kit was scaffolded for.)

## Troubleshooting

### `[ERROR] No Jetson AGX Orin detected in recovery mode`

- Re-do the recovery procedure carefully — sequence and timing matter.
- Try a different USB-C cable; cheap cables are often charge-only.
- Confirm you're on the **front** USB-C (the labeled flash port), not rear.
- Run `lsusb` and look for any NVIDIA-VID (`0955:`) device. If the PID is
  not `7023`, your board may be a SKU we didn't list — add it to
  `ORIN_PIDS` in `scripts/check-recovery.sh`.

### SDK Manager hangs on "Waiting for the device to boot"

The flash itself succeeded; SDK Manager is now trying to install runtime
SDK components over SSH. We deselect that step, but if you somehow hit it,
just `Ctrl-C` — the OS is already on eMMC.

### Permission denied writing into `work/`

The container runs as UID 1000. If your host UID differs, `flash.sh`
chowns `work/` to `1000:1000` on first run. To clean up afterwards:

```sh
make clean       # falls back to sudo rm -rf if needed
```

### Docker can't access USB

- Confirm `make prepare` ran and you re-logged in for `docker` group.
- The `--privileged` and `-v /dev/bus/usb:/dev/bus/usb` flags in
  `flash.sh` are required for raw USB access. Don't strip them.
- Some hosts have `usbguard` blocking new devices — temporarily stop it
  with `sudo systemctl stop usbguard` if so.

### "no space left on device" mid-flash

`work/` needs ~25 GB free for the L4T BSP plus rootfs build. Move the
work dir to a larger volume: `WORK_DIR=/mnt/big/jetson-work make flash`.

## Files

```
.
├── README.md               (this file)
├── Makefile                convenience targets
├── config.env              JetPack version / target / paths
├── .gitignore
└── scripts/
    ├── prepare-host.sh     install Docker + USB tools on the host
    ├── load-sdkmanager.sh  docker load the SDK Manager tarball
    ├── check-recovery.sh   verify Jetson is in recovery mode
    └── flash.sh            run SDK Manager and flash eMMC
```

## Why a flash kit

NVIDIA SDK Manager officially supports Ubuntu 18.04 / 20.04 / 22.04 hosts.
On newer distros (Ubuntu 26.04, Fedora, Arch, ...) it hits dependency
mismatches that are tedious to work around. Running it inside the official
SDK Manager Docker image sidesteps the host-OS issue entirely — Docker
sees `0955:7023` USB devices in recovery mode regardless of what kernel
or distro the host runs.

## References

- NVIDIA SDK Manager: https://developer.nvidia.com/sdk-manager
- SDK Manager Docker docs: https://docs.nvidia.com/sdk-manager/sdkm-docker/
- Jetson Linux (L4T) downloads: https://developer.nvidia.com/embedded/jetson-linux
- AGX Orin Developer Kit user guide: https://developer.nvidia.com/embedded/learn/jetson-agx-orin-devkit-user-guide
