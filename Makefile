.PHONY: help prepare load check flash clean

REPO_ROOT := $(CURDIR)

help:  ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

prepare:  ## Install Docker, qemu, usbutils on the host (one-time)
	./scripts/prepare-host.sh

load:  ## Load SDK Manager tarball: make load IMG=/path/to/sdkmanager-...tar.gz
	@[ -n "$(IMG)" ] || { echo "Set IMG=/path/to/sdkmanager-tarball.tar.gz" >&2; exit 1; }
	./scripts/load-sdkmanager.sh "$(IMG)"

check:  ## Verify the Jetson is in recovery mode
	./scripts/check-recovery.sh

flash:  ## Flash JetPack to the Jetson (eMMC)
	./scripts/flash.sh

clean:  ## Remove the work directory (downloaded artifacts, login token)
	@echo "Removing $(REPO_ROOT)/work"
	@rm -rf "$(REPO_ROOT)/work" 2>/dev/null || sudo rm -rf "$(REPO_ROOT)/work"
