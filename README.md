# Linux Compliance Audit Tool

A Bash-based tool that audits Linux security configuration and maps each
technical check to ISO/IEC 27001:2022, NIST SP 800-53 and CIS Controls v8,
with risk ratings and evidence for every finding.

> **Note:** This is a learning and portfolio project. The lab images in
> `lab/` are intentionally vulnerable and must never be used in production.

## Why I built this

I come from a GRC background, where controls are usually assessed through
policies, interviews and documents. After completing the Bash scripting
module on Hack The Box Academy, I wanted to understand what these controls
look like on a real system: how a requirement such as "privileged access
must be restricted" is actually verified, and what evidence an auditor can
collect. This project bridges those two worlds.

## What it does

- Runs 6 security checks on a Linux system
- Reports PASS / FAIL with a risk rating for each check
- Records the actual value found as evidence
- Maps every check to ISO 27001, NIST 800-53 and CIS controls
- Includes a vulnerable and a hardened lab to demonstrate
  **finding → remediation → retest**

## Checks

| ID | Check | Risk | Key controls |
|---|---|---|---|
| SSH-01 | Root login over SSH disabled | High | ISO A.8.2, NIST AC-6 |
| SSH-02 | Empty passwords over SSH disabled | High | ISO A.8.5, NIST IA-5 |
| ACC-01 | No accounts with empty passwords | High | ISO A.5.17, NIST IA-5 |
| ACC-02 | Only root has UID 0 | High | ISO A.8.2, NIST AC-2 |
| ACC-03 | No passwordless sudo rules | High | ISO A.8.2, NIST IA-11 |
| FILE-01 | /etc/shadow permissions restricted | High | ISO A.8.3, NIST AC-3 |

Full mapping, risk rationale and remediation guidance:
[docs/control-mapping.md](docs/control-mapping.md)

## Results: before and after remediation

| ID | Vulnerable lab | Hardened lab |
|---|---|---|
| SSH-01 | FAIL `PermitRootLogin=yes` | PASS `PermitRootLogin=no` |
| SSH-02 | FAIL `PermitEmptyPasswords=yes` | PASS `PermitEmptyPasswords=no` |
| ACC-01 | FAIL `accounts=testuser` | PASS `none found` |
| ACC-02 | FAIL `accounts=backdoor` | PASS `none found` |
| ACC-03 | FAIL `entries=devops` | PASS `none found` |
| FILE-01 | FAIL `mode=644` | PASS `mode=640` |

Sample output from the vulnerable lab:

```
=== Linux Compliance Audit ===
SSH-01   FAIL   High     Root login over SSH disabled        PermitRootLogin=yes
SSH-02   FAIL   High     Empty passwords over SSH disabled   PermitEmptyPasswords=yes
ACC-01   FAIL   High     No accounts with empty passwords    accounts=testuser
ACC-02   FAIL   High     Only root has UID 0                 accounts=backdoor
ACC-03   FAIL   High     No passwordless sudo rules          entries=devops
FILE-01  FAIL   High     /etc/shadow permissions restricted  mode=644 owner=root:shadow
```

## Quick start

Requirements: Docker and a Linux shell (tested on Ubuntu via WSL2).

```bash
git clone https://github.com/NicatAgayev/linux-compliance-audit.git
cd linux-compliance-audit

# Build and start the vulnerable lab
docker build -t audit-lab:vulnerable -f lab/Dockerfile.vulnerable lab/
docker run -d --name vuln-lab audit-lab:vulnerable

# Copy the tool into the lab and run the audit
docker cp . vuln-lab:/opt/audit
docker exec vuln-lab /opt/audit/audit.sh
```

For the hardened lab, repeat the steps with `Dockerfile.hardened` and a
container named `hardened-lab`.

The tool is read-only and does not change any configuration. To audit
your own Linux system: `sudo ./audit.sh`

## How it works

```
linux-compliance-audit/
├── audit.sh                 # Entry point: loads checks, prints results
├── checks/
│   ├── ssh.sh               # SSH-01, SSH-02
│   ├── accounts.sh          # ACC-01, ACC-02, ACC-03
│   └── files.sh             # FILE-01
├── lab/
│   ├── Dockerfile.vulnerable
│   └── Dockerfile.hardened
└── docs/
    └── control-mapping.md
```

`audit.sh` defines a shared `report` function and loads check modules
from `checks/`, grouped by domain. Each check reads system configuration
with standard tools (`grep`, `awk`, `stat`), compares it with the
requirement, and reports the result with the evidence found.

## Limitations

- A PASS means a specific requirement is met, not that the area is fully
  secure (compliance is not the same as security).
- SSH settings must be explicitly configured; implicit defaults are
  reported as FAIL.
- SSH drop-in files in `/etc/ssh/sshd_config.d/` are not yet parsed.
- Risk ratings do not consider system context and should be reviewed
  by an analyst.

Details: [docs/control-mapping.md](docs/control-mapping.md#scope-and-limitations)

## Roadmap

- [ ] Summary line and CSV report export
- [ ] HTML report
- [ ] Use `sshd -T` to evaluate effective SSH configuration
- [ ] Additional checks (password policy, auditd, firewall)
- [ ] Automated tests with GitHub Actions

## What I learned

- **Technical:** Bash functions and modular scripts, text processing with
  `grep`, `awk` and `stat`, Linux account and permission model, Docker
  images and containers, Git workflow and SSH key authentication.
- **GRC:** translating framework controls into testable technical checks,
  likelihood and impact based risk rating, evidence-based findings,
  avoiding false positives, and the difference between compliance and
  security.

## AI assistance

This project was built with the help of an AI assistant (Claude), used as
a tutor: explaining concepts, drafting code and reviewing my reasoning.
I built and tested every step myself, made the risk and design decisions,
and can explain every line of the code.

## License

MIT# linux-compliance-audit
Bash-based Linux security audit tool mapping technical checks to ISO 27001, NIST 800-53 and CIS controls
