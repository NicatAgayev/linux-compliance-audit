#!/usr/bin/env bash
# SSH configuration checks

SSHD_CONFIG="/etc/ssh/sshd_config"

# SSH-01: Root login over SSH must be disabled
check_ssh_root_login() {
    local value
    value=$(grep -Ei '^\s*PermitRootLogin\s+' "$SSHD_CONFIG" | awk '{print tolower($2)}' | head -n 1)

    if [[ "$value" == "no" ]]; then
        report "SSH-01" "PASS" "High" "Root login over SSH disabled" "PermitRootLogin=${value}"
    else
        report "SSH-01" "FAIL" "High" "Root login over SSH disabled" "PermitRootLogin=${value:-not set}"
    fi
}

# SSH-02: Login with empty passwords over SSH must be disabled
check_ssh_empty_passwords() {
    local value
    value=$(grep -Ei '^\s*PermitEmptyPasswords\s+' "$SSHD_CONFIG" | awk '{print tolower($2)}' | head -n 1)

    if [[ "$value" == "no" ]]; then
        report "SSH-02" "PASS" "High" "Empty passwords over SSH disabled" "PermitEmptyPasswords=${value}"
    else
        report "SSH-02" "FAIL" "High" "Empty passwords over SSH disabled" "PermitEmptyPasswords=${value:-not set}"
    fi
}
