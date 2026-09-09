# Security Policy

The Syntrix engineering team takes security and deterministic reliability seriously. We appreciate your efforts to responsibly disclose vulnerabilities.

## Supported Versions

We provide security updates and patches for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0.0 | :x:                |

## Defensive Architecture & Built-in Guarantees

Syntrix is engineered from the ground up with defensive safety mechanisms:

* **Zero Telemetry**: Syntrix does not collect, transmit, or persist codebase telemetry, prompt logs, or source files outside your local machine.
* **Path Traversal Guards**: All file mutations enforce strict path canonicalization to prevent path traversal (../) vulnerabilities.
* **Hermetic Execution**: Audits, sandboxes, and dry runs execute in isolated directory trees without altering ambient system variables or global configurations.
* **Plan-First Execution**: Destructive operations always provide dry-run plans before modifying disk.

## Reporting a Vulnerability

If you discover a potential security vulnerability within Syntrix or any of its subpackages (lutter_package_studio_core, lutter_package_studio_cli), please report it responsibly:

1. **Do NOT open a public issue.**
2. Report the vulnerability privately via **[GitHub Private Security Advisory](https://github.com/Ashish6298/Syntrix/security/advisories/new)** or by opening a confidential security advisory.
3. Include the following details to help us triage effectively:
   - Type of issue (e.g. path traversal, arbitrary execution, command injection)
   - Step-by-step instructions or minimal reproduction code/CLI command
   - Affected CLI or package version
   - Potential impact of the vulnerability

## Response & Disclosure Process

* **Acknowledgment**: We aim to acknowledge reports within **48 hours**.
* **Assessment & Fix**: We will investigate the issue, determine severity, and draft a patch in a private fork.
* **Release & Credit**: Once the fix is verified and released in an updated version, we will publish a security advisory and give public credit to the reporter (if desired).
