# Common helpers for flashkit. Sourced, not executed.
# Expects REPO_ROOT to be set by the caller.

if [[ -t 1 ]]; then
    C_RESET=$'\e[0m'; C_BOLD=$'\e[1m'; C_DIM=$'\e[2m'
    C_RED=$'\e[31m'; C_GREEN=$'\e[32m'; C_YELLOW=$'\e[33m'
    C_BLUE=$'\e[34m'; C_CYAN=$'\e[36m'
else
    C_RESET=""; C_BOLD=""; C_DIM=""
    C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_CYAN=""
fi

info()  { printf "%s[INFO]%s  %s\n" "$C_BLUE"   "$C_RESET" "$*"; }
ok()    { printf "%s[OK]%s    %s\n" "$C_GREEN"  "$C_RESET" "$*"; }
warn()  { printf "%s[WARN]%s  %s\n" "$C_YELLOW" "$C_RESET" "$*" >&2; }
err()   { printf "%s[ERR]%s   %s\n" "$C_RED"    "$C_RESET" "$*" >&2; }
fatal() { err "$*"; exit 1; }

WORK_BASE="${WORK_BASE:-$REPO_ROOT/work}"
DOCKER_DIR="$REPO_ROOT/docker"
PROFILES_DIR="$REPO_ROOT/profiles"
PROFILES_LOCAL_DIR="$REPO_ROOT/profiles.d"
