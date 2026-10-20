# Control Mapping

This document explains why each check exists, which risk it addresses,
and which framework requirements it supports.

Frameworks referenced: ISO/IEC 27001:2022 Annex A, NIST SP 800-53 Rev. 5,
CIS Controls v8.

## Summary

| ID | Check | Risk | ISO 27001:2022 | NIST 800-53 | CIS v8 |
|---|---|---|---|---|---|
| SSH-01 | Root login over SSH disabled | High | A.8.2, A.8.5 | AC-6, IA-2 | 5.4 |
| SSH-02 | Empty passwords over SSH disabled | High | A.8.5, A.5.17 | IA-2, IA-5 | 5.2 |
| ACC-01 | No accounts with empty passwords | High | A.5.17, A.8.5 | IA-5 | 5.2 |
| ACC-02 | Only root has UID 0 | High | A.8.2, A.5.18 | AC-2, AC-6 | 5.1, 5.4 |
| ACC-03 | No passwordless sudo rules | High | A.8.2, A.8.5 | AC-6, IA-11 | 5.4 |
| FILE-01 | /etc/shadow permissions restricted | High | A.8.3, A.5.17 | AC-3, AC-6 | 3.3 |

---

### SSH-01 — Root login over SSH disabled

**Requirement:** The SSH server must not allow direct login as `root`
(`PermitRootLogin no`).

**Risk rating:** High

**Rationale:**
- *Likelihood:* The `root` username exists on every Linux system, so an
  attacker only needs to guess the password. Internet-facing SSH servers
  receive constant automated brute-force attempts targeting `root`.
- *Impact:* Successful login grants full control of the system. Direct
  root login also breaks accountability, as actions cannot be attributed
  to an individual administrator.
- *Context note:* Risk may be lower if SSH is not internet-facing or uses
  key-only authentication; the tool rates conservatively.

**Control mapping:**

| Framework | Control | Relevance |
|---|---|---|
| ISO 27001:2022 | A.8.2 Privileged access rights | Root is the highest privileged account; access must be restricted |
| ISO 27001:2022 | A.8.5 Secure authentication | Authentication mechanisms must be securely configured |
| NIST SP 800-53 | AC-6 Least Privilege | Admins should log in as themselves and elevate only when needed |
| NIST SP 800-53 | IA-2 Identification and Authentication | Users must be uniquely identified; shared root login prevents this |
| CIS Controls v8 | 5.4 Restrict Administrator Privileges | Admin rights should be used via dedicated accounts |

**Evidence collected:** Value of `PermitRootLogin` in `/etc/ssh/sshd_config`.

**Remediation:** Set `PermitRootLogin no`, restart the SSH service, and
ensure administrators use personal accounts with `sudo`.

---

### SSH-02 — Empty passwords over SSH disabled

**Requirement:** The SSH server must reject login attempts for accounts
with empty passwords (`PermitEmptyPasswords no`).

**Risk rating:** High

**Rationale:**
- *Likelihood:* No password guessing is required. An attacker only needs
  a valid username, and usernames are often predictable (`test`, `admin`,
  `user`, company names).
- *Impact:* Even without root privileges, access to the system gives the
  attacker a foothold: they can read files available to normal users and
  look for further weaknesses.
- *Chained risk:* Combined with other misconfigurations (for example a
  world-readable `/etc/shadow`, see FILE-01), an unprivileged foothold can
  lead to privilege escalation. The setting alone is harmless only if no
  account has an empty password; together with ACC-01 it effectively
  leaves the system open.

**Control mapping:**

| Framework | Control | Relevance |
|---|---|---|
| ISO 27001:2022 | A.8.5 Secure authentication | Authentication must not be bypassable |
| ISO 27001:2022 | A.5.17 Authentication information | Authentication information (passwords) must be managed and required |
| NIST SP 800-53 | IA-2 Identification and Authentication | Users must actually authenticate before access is granted |
| NIST SP 800-53 | IA-5 Authenticator Management | Authenticators must exist and meet defined requirements |
| CIS Controls v8 | 5.2 Use Unique Passwords | Every account must be protected by a password |

**Evidence collected:** Value of `PermitEmptyPasswords` in `/etc/ssh/sshd_config`.

**Remediation:** Set `PermitEmptyPasswords no` and restart the SSH service.

---

### ACC-01 — No accounts with empty passwords

**Requirement:** No local account may have an empty password field in
`/etc/shadow`. Locked accounts (`!` or `*`) are acceptable.

**Risk rating:** High

**Rationale:**
- *Likelihood:* Anyone who knows the username can log in through any
  local or remote mechanism that accepts passwords.
- *Impact:* Unauthenticated access to the system under that account's
  identity, and a starting point for privilege escalation.

**Control mapping:**

| Framework | Control | Relevance |
|---|---|---|
| ISO 27001:2022 | A.5.17 Authentication information | Accounts must have managed authentication information |
| ISO 27001:2022 | A.8.5 Secure authentication | Login must require authentication |
| NIST SP 800-53 | IA-5 Authenticator Management | An account without an authenticator violates authenticator requirements |
| CIS Controls v8 | 5.2 Use Unique Passwords | Every account must have a password |

**Evidence collected:** Usernames whose password field in `/etc/shadow` is empty.

**Remediation:** Set a strong password (`passwd <user>`) or lock the
account (`passwd -l <user>`) if it is not needed.

---

### ACC-02 — Only root has UID 0

**Requirement:** `root` must be the only account with UID 0.

**Risk rating:** High

**Rationale:**
- *Likelihood:* Additional UID 0 accounts are a common persistence
  technique after a compromise, and can also result from poor admin practice.
- *Impact:* Linux grants privileges by UID, not by name. Any UID 0 account
  has full root privileges while being harder to notice during reviews.
- *Indicators:* In the lab, the account also had an empty comment field
  and a non-existent home directory, typical signs of a suspicious account.

**Control mapping:**

| Framework | Control | Relevance |
|---|---|---|
| ISO 27001:2022 | A.8.2 Privileged access rights | Hidden privileged accounts bypass privileged access control |
| ISO 27001:2022 | A.5.18 Access rights | Access rights must be provisioned, reviewed and justified |
| NIST SP 800-53 | AC-2 Account Management | All accounts must be authorized and monitored |
| NIST SP 800-53 | AC-6 Least Privilege | No account should hold root privileges without need |
| CIS Controls v8 | 5.1 Inventory of Accounts | Unknown accounts indicate an incomplete account inventory |
| CIS Controls v8 | 5.4 Restrict Administrator Privileges | Admin privileges must be limited and controlled |

**Evidence collected:** Usernames other than `root` with UID 0 in `/etc/passwd`.

**Remediation:** Investigate the account's origin (it may indicate a
compromise), then remove it (`userdel <user>`) or assign a unique UID.

---

### ACC-03 — No passwordless sudo rules

**Requirement:** No active sudo rule may contain `NOPASSWD`.

**Risk rating:** High

**Rationale:**
- *Likelihood:* Anyone who gains access to the affected account (stolen
  SSH key, unlocked session, compromised application) can elevate
  privileges immediately.
- *Impact:* `NOPASSWD: ALL` is effectively passwordless root. The password
  prompt is the last barrier between an account compromise and a full
  system compromise.

**Control mapping:**

| Framework | Control | Relevance |
|---|---|---|
| ISO 27001:2022 | A.8.2 Privileged access rights | Use of privileges must be controlled |
| ISO 27001:2022 | A.8.5 Secure authentication | Privilege elevation must require authentication |
| NIST SP 800-53 | AC-6 Least Privilege | Elevated rights must be granted and used deliberately |
| NIST SP 800-53 | IA-11 Re-authentication | Users must re-authenticate before privileged operations |
| CIS Controls v8 | 5.4 Restrict Administrator Privileges | Admin privileges must be controlled |

**Evidence collected:** Users or groups with active `NOPASSWD` rules in
`/etc/sudoers` and `/etc/sudoers.d/`.

**Remediation:** Remove `NOPASSWD` from the rule. Where automation
requires it, restrict the rule to specific commands instead of `ALL`.

---

### FILE-01 — /etc/shadow permissions restricted

**Requirement:** `/etc/shadow` must be owned by `root`, grant no
permissions to others, and at most read permission to the group
(for example `640 root:shadow`).

**Risk rating:** High

**Rationale:**
- *Likelihood:* Any local user, or an attacker with any foothold, can
  copy the file.
- *Impact:* Password hashes can be cracked offline with tools such as
  John the Ripper or Hashcat. Offline attacks trigger no logs and no
  account lockouts.

**Control mapping:**

| Framework | Control | Relevance |
|---|---|---|
| ISO 27001:2022 | A.8.3 Information access restriction | Access to sensitive files must be restricted |
| ISO 27001:2022 | A.5.17 Authentication information | Stored authentication information must be protected |
| NIST SP 800-53 | AC-3 Access Enforcement | File permissions enforce authorized access |
| NIST SP 800-53 | AC-6 Least Privilege | Only processes that need the hashes should read them |
| CIS Controls v8 | 3.3 Configure Data Access Control Lists | Sensitive data must be protected with access controls |

**Evidence collected:** Octal mode, owner and group of `/etc/shadow`.

**Remediation:** `chown root:shadow /etc/shadow && chmod 640 /etc/shadow`

---

## Scope and limitations

- **Compliance is not the same as security.** A PASS means the specific
  requirement is met, not that the area is fully secure. Example: in the
  hardened lab, ACC-03 passes because sudo requires a password, yet the
  `devops` account can still run any command as root. Restricting sudo
  to specific commands would be a separate requirement.
- **Explicit configuration required.** If an SSH setting is not explicitly
  defined, the tool reports FAIL even when the OpenSSH default is secure,
  because CIS benchmarks expect explicit configuration and an implicit
  default cannot be shown as evidence.
- **SSH drop-in files are not parsed.** Settings in
  `/etc/ssh/sshd_config.d/` are not evaluated. A future version could use
  `sshd -T` to read the effective configuration.
- **Risk ratings are context-free.** The tool cannot know whether a system
  is internet-facing or has compensating controls; ratings should be
  reviewed by an analyst.
- **Root privileges required.** Some checks read `/etc/shadow` and
  therefore must run as root.
