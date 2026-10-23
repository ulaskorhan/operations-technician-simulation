#!/usr/bin/env bash
# safety.sh - shared safety checks for every Linux scenario script.
#
# The break.sh and restore.sh scripts "source" this file, which means its
# functions become available inside them. It is not meant to be run on its own.

# Only these hostnames are allowed to run fault-injection scripts.
LAB_HOSTS="ops-lnx01 ops-lnx02"

# Folder where break scripts save the "before" state, so restore can put it back.
STATE_DIR="/var/lib/ops-lab"

# Print an error message to stderr and stop the script with exit code 1.
die() {
    echo "ERROR: $*" >&2
    exit 1
}

# Stop unless the script runs as root (most scenarios change system files).
require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        die "run this script with sudo."
    fi
}

# Stop unless this machine is one of the lab servers.
require_lab_host() {
    local current
    # hostname -s gives the short name; tr makes it lowercase so OPS-LNX01 also matches.
    current="$(hostname -s | tr '[:upper:]' '[:lower:]')"
    for allowed in ${LAB_HOSTS}; do
        if [[ "${current}" == "${allowed}" ]]; then
            return 0
        fi
    done
    die "hostname '${current}' is not a lab host (${LAB_HOSTS}). Refusing to run."
}

# Ask the user to type "yes" before continuing. Anything else aborts.
confirm() {
    local answer
    echo "$1"
    read -r -p "Type 'yes' to continue: " answer
    if [[ "${answer}" != "yes" ]]; then
        echo "Aborted. Nothing was changed."
        exit 0
    fi
}

# Make sure the state folder exists (only root can read or write it).
prepare_state_dir() {
    mkdir -p "${STATE_DIR}"
    chmod 700 "${STATE_DIR}"
}

# Print an OK or FAIL line. Used by the check.sh scripts.
ok()   { echo "[ OK ] $*"; }
fail() { echo "[FAIL] $*"; }
