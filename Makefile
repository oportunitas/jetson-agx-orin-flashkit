.PHONY: help list prepare check flash flash-jp5 flash-jp6 \
        sdkm-list sdkm-load sdkm-load-all load clean

REPO_ROOT := $(CURDIR)

help:  ## Show flashkit help
	@./flashkit help

list:  ## List available OS profiles
	@./flashkit list

prepare:  ## Install Docker, qemu-binfmt, usbutils on the host (one-time)
	./flashkit prepare

check:  ## Verify the Jetson is in recovery mode
	./flashkit check

sdkm-list:  ## List SDK Manager tarballs and loaded Docker images
	@./flashkit sdkm list

sdkm-load:  ## Load one SDK Manager tarball: make sdkm-load IMG=<path|name|pattern>
	@[ -n "$(IMG)" ] || { echo "Set IMG=<path|filename|pattern>" >&2; exit 1; }
	./flashkit sdkm load "$(IMG)"

sdkm-load-all:  ## Load every tarball in sdkmanager/
	./flashkit sdkm load-all

load: sdkm-load  ## Alias for sdkm-load (back-compat)

flash:  ## Flash (interactive picker) — use PROFILE=name and STORAGE=emmc|nvme to override
	@./flashkit flash $(PROFILE) $(if $(STORAGE),--storage $(STORAGE))

setup:  ## Pre-fetch assets for a profile without flashing: make setup PROFILE=name
	@[ -n "$(PROFILE)" ] || { echo "Set PROFILE=<name>" >&2; exit 1; }
	./flashkit setup "$(PROFILE)"

flash-jp5:  ## Flash JetPack 5.1.5 via SDK Manager (shortcut)
	./flashkit flash jetpack-5.1.5 $(if $(STORAGE),--storage $(STORAGE))

flash-jp6:  ## Flash JetPack 6.2 via SDK Manager (shortcut)
	./flashkit flash jetpack-6.2 $(if $(STORAGE),--storage $(STORAGE))

clean:  ## Remove all cached artifacts (downloads, login tokens)
	./flashkit clean --all
