#!/usr/bin/env bash
# Legacy shim. Forwards to: ./flashkit sdkm load <arg>
# Accepts an absolute path, a filename in sdkmanager/, or a substring pattern.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$REPO_ROOT/flashkit" sdkm load "$@"
