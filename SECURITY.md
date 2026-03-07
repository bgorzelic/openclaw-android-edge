# Security Policy

## Scope

This repository contains documentation, scripts, and guides for running OpenClaw on Android devices. It does **not** contain OpenClaw source code. For security issues in OpenClaw itself, report to the OpenClaw project directly.

## Reporting a Vulnerability

If you find a security issue in this repository's scripts or documentation that could lead to credential exposure, unauthorized access, or other security risks:

**Email:** support@spookyjuice.ai

**Include:**
- Description of the issue
- Steps to reproduce
- Potential impact
- Suggested fix (if you have one)

We will acknowledge receipt within 48 hours and provide a timeline for resolution.

## Security Practices in This Project

- **No secrets in the repo.** API keys, tokens, and credentials must never be committed. The `.gitignore` excludes `.env` files.
- **Loopback binding.** The gateway configuration defaults to `bind: loopback`, meaning only localhost can connect.
- **SSH key authentication.** The guide recommends key-based SSH auth and documents `IdentitiesOnly yes` to prevent key confusion.
- **Tailscale encryption.** All remote access routes through Tailscale's WireGuard mesh, not exposed ports.

## Known Considerations

- The `scripts/benchmark.sh` script executes SSH commands against a configured host. Review it before running.
- The `.env` file (excluded from git) may contain API keys. Ensure it is never committed.
- Gateway auth is set to `none` in the optimized config because it binds to loopback only. If you change the bind address, re-enable authentication.
