# Interactive UI helpers.

# pick_one PROMPT ITEM [ITEM ...]
# Sets PICKED and PICKED_INDEX on success. Reads from /dev/tty so it works
# even when the script's stdout is redirected.
pick_one() {
    local prompt="$1"; shift
    local -a items=("$@")
    local n=${#items[@]}
    (( n > 0 )) || return 1

    if [[ ! -t 0 ]] || [[ ! -e /dev/tty ]]; then
        err "Non-interactive shell; specify the choice as an argument."
        return 1
    fi

    printf "%s\n" "$prompt"
    local i=1 it
    for it in "${items[@]}"; do
        printf "  %s%2d.%s %s\n" "$C_BOLD" "$i" "$C_RESET" "$it"
        ((i++))
    done

    local choice
    while true; do
        read -r -p "Select [1-$n]: " choice </dev/tty || return 1
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= n )); then
            PICKED_INDEX=$((choice - 1))
            PICKED="${items[$PICKED_INDEX]}"
            return 0
        fi
        warn "Invalid; enter a number 1-$n."
    done
}

confirm() {
    local prompt="${1:-Continue?}"
    [[ ! -t 0 ]] && return 0
    local ans
    read -r -p "$prompt [y/N] " ans </dev/tty || return 1
    [[ "$ans" =~ ^[Yy]$ ]]
}
