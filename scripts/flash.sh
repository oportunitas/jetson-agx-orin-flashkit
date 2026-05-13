#!/usr/bin/env bash
# Legacy entry point. Forwards to ./flashkit flash.
#
# Back-compat env-var mapping:
#   FLAVOR=jp5 -> profile jetpack-5.1.5
#   FLAVOR=jp6 -> profile jetpack-6.2
# With no FLAVOR set, falls through to the interactive picker.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "${FLAVOR:-}" in
    jp5) exec "$REPO_ROOT/flashkit" flash jetpack-5.1.5 "$@" ;;
    jp6) exec "$REPO_ROOT/flashkit" flash jetpack-6.2   "$@" ;;
    "")  exec "$REPO_ROOT/flashkit" flash "$@" ;;
    *)   echo "Unknown FLAVOR='$FLAVOR' (expected jp5, jp6, or unset)" >&2; exit 1 ;;
esac
