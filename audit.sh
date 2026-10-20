#!/usr/bin/env bash
# Linux Compliance Audit Tool - main entry point

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Prints one result line: ID, status, severity, title, detail
report() {
    local id="$1" status="$2" severity="$3" title="$4" detail="$5"
    printf '%-8s %-6s %-8s %-35s %s\n' "$id" "$status" "$severity" "$title" "$detail"
}

source "$SCRIPT_DIR/checks/ssh.sh"

echo "=== Linux Compliance Audit ==="
check_ssh_root_login
check_ssh_empty_passwords
