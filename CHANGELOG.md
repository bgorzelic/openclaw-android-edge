# Changelog

All notable changes to this project will be documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
