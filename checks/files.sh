#!/usr/bin/env bash
# File permission checks

# FILE-01: /etc/shadow must be owned by root and not accessible by others
check_shadow_permissions() {
    local file="/etc/shadow"
    local perms owner group
    perms=$(stat -c '%a' "$file")
    owner=$(stat -c '%U' "$file")
    group=$(stat -c '%G' "$file")

    local group_digit="${perms: -2:1}"
    local others_digit="${perms: -1}"

    if [[ "$owner" == "root" && "$others_digit" == "0" && ( "$group_digit" == "0" || "$group_digit" == "4" ) ]]; then
        report "FILE-01" "PASS" "High" "/etc/shadow permissions restricted" "mode=${perms} owner=${owner}:${group}"
    else
        report "FILE-01" "FAIL" "High" "/etc/shadow permissions restricted" "mode=${perms} owner=${owner}:${group}"
    fi
}
