#!/usr/bin/env bash
# User account checks

SHADOW_FILE="/etc/shadow"
PASSWD_FILE="/etc/passwd"

# ACC-01: No account may have an empty password
check_empty_password_accounts() {
    local accounts
    accounts=$(awk -F: '$2 == "" {print $1}' "$SHADOW_FILE" | paste -sd ',' -)

    if [[ -z "$accounts" ]]; then
        report "ACC-01" "PASS" "High" "No accounts with empty passwords" "none found"
    else
        report "ACC-01" "FAIL" "High" "No accounts with empty passwords" "accounts=${accounts}"
    fi
}

# ACC-02: Only root may have UID 0
check_uid_zero_accounts() {
    local accounts
    accounts=$(awk -F: '$3 == 0 && $1 != "root" {print $1}' "$PASSWD_FILE" | paste -sd ',' -)

    if [[ -z "$accounts" ]]; then
        report "ACC-02" "PASS" "High" "Only root has UID 0" "none found"
    else
        report "ACC-02" "FAIL" "High" "Only root has UID 0" "accounts=${accounts}"
    fi
}
