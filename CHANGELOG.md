# Changelog

All notable changes to this project will be documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.3.0] - 2026-03-08

### Added
- Claude Code (v2.1.71) running on the Pixel 10a with proot /tmp wrapper
- Full dev environment: Python 3.13, tmux, jq, sqlite3
- claude-dev wrapper script for Termux /tmp sandbox fix
- Phase 12: Developer Environment Setup in INSTALL-GUIDE.md
- Private config backup repo (pixel-10a-edge-node-config)
- Related Projects section in README linking to SIGNAL
- Design doc for three-repo architecture
- Use Case #9: Network Intelligence (SIGNAL)

### Changed
- OpenClaw upgraded: 2026.3.2 → 2026.3.7
- Node.js upgraded: v22.x (proot) → v25.3.0 (native)
- Gateway RSS reduced: 323 MB → 184 MB (43% reduction)
- NODE_OPTIONS memory cap: 256 MB → 384 MB (matches production)
- Boot persistence: documented as stable (was optional/planned)
- Watchdog: documented as production-proven
- Phase 2 (Public Launch): marked as DONE in roadmap

### Removed
- Device-specific files from public repo (moved to private config repo)

## [0.2.0] - 2026-03-07

### Added
- OPTIMIZATION-GUIDE.md with performance tuning, cost analysis, and real-world use cases
- Phase 11 (Gateway Optimization) in INSTALL-GUIDE.md
- Benchmark script (`scripts/benchmark.sh`) for automated metrics collection
- Auto-start scripts for sshd and gateway in `.bashrc`
- Node.js memory cap (`--max-old-space-size=256`)
- mDNS/Bonjour disable for Termux compatibility
- Architecture diagrams (Mermaid) in assets/
- README.md for public launch
- docs/ folder with architecture, use cases, device strategy, threat model, FAQ
- Social launch kit for X, LinkedIn, Reddit, HN, Discord
- OSS essentials: LICENSE, CONTRIBUTING, SECURITY, ROADMAP
- GitHub issue and PR templates

### Fixed
- Gateway model ID format (must use `openrouter/` prefix)
- Auth rate limiting issue with multiple local clients
- Gateway startup in native Termux (was failing in proot)

### Changed
- Default model from `anthropic/claude-opus-4-6` to `openrouter/anthropic/claude-3.5-haiku`
- Gateway auth from token to none (safe on loopback)
- Moved gateway from proot-distro to native Termux

## [0.1.0] - 2026-03-06

### Added
- Initial install guide (Phases 1-10)
- SSH remote access setup (Phase 8)
- Tailscale networking setup (Phase 9)
- 10 workflows and use cases (Phase 10)
- Newsletter Issue #2 HTML and metadata
- Social media posts for 6 platforms
- Install screenshots (10 images)
- PII scrubbing across all customer-facing docs
- Newsletter publish pipeline documentation
