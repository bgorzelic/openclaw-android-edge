# HANDOFF.md — openclaw-pixel10a-guide

## What This Is

Guide and documentation repo for running OpenClaw (AI agent gateway) on a Google Pixel 10a via Termux. Includes 12-phase install guide, optimization guide, architecture docs, threat model, benchmarks, social launch kit, and all OSS essentials. Public repo at github.com/bgorzelic/openclaw-android-edge.

## Last Session — 2026-03-08

### Done
- Created private repo `pixel-10a-edge-node-config` on GitHub with full device config backup (31 files)
- Pulled complete device state from Pixel 10a via SSH (OpenClaw config, identity, workspace, termux, shell, agents, snapshot)
- Cleaned public repo: removed logs/, added .gitignore entries for device-specific files
- Updated README.md: 323->184 MB RSS, added Claude Code/auto-start/watchdog to "What Works Now", added Related Projects section
- Updated INSTALL-GUIDE.md: version 2026.3.2->2026.3.7, added Phase 12 (Developer Environment), added claude-dev wrapper docs, updated software versions
- Updated OPTIMIZATION-GUIDE.md: NODE_OPTIONS 256->384 MB everywhere
- Updated ROADMAP.md: Phase 2 marked DONE, auto-start/watchdog done, added dev environment and SIGNAL
- Added v0.3.0 CHANGELOG entry
- Added Use Case #9 (SIGNAL - Network Intelligence Sensor) to docs/use-cases.md
- Created design doc: docs/plans/2026-03-08-three-repo-architecture-design.md
- Created implementation plan: docs/plans/2026-03-08-three-repo-implementation.md

### Current Device State
- OpenClaw 2026.3.7 running in native Termux on Pixel 10a
- Node.js v25.3.0, Python 3.13.12, Claude Code 2.1.71
- Gateway RSS: 184 MB, self-healing boot, watchdog every 2 min
- SSH access via Tailscale (Host termux, port 8022)
- Claude Code works via `claude-dev` wrapper (proot /tmp fix)

### Three-Repo Architecture
- `openclaw-android-edge` (public) — Living install guide (this repo)
- `SIGNAL` (public, future) — Network intelligence app
- `pixel-10a-edge-node-config` (private) — Device config backup

## Next Steps

1. Install OpenClaw skills via clawhub (telegram, coding-agent, tmux, session-logs)
2. Configure agent identity and memory on device
3. Tune model config with Haiku/Sonnet/Opus tiers
4. Run `termux-setup-storage` for shared Android storage access
5. Build custom apps leveraging OpenClaw + Termux:API sensors
6. Begin SIGNAL repo (network intelligence sensor)

## Open Questions

- Should OpenClaw skills be documented in this guide or SIGNAL repo?
- Optimal model tier config for cost vs capability on edge

## Key Files

- `README.md` — Public-facing README with badges and metrics table
- `INSTALL-GUIDE.md` — 12-phase install walkthrough (v2026.3.7)
- `OPTIMIZATION-GUIDE.md` — Performance tuning and cost analysis
- `CHANGELOG.md` — Release history
- `ROADMAP.md` — Phase tracking with completion status
- `docs/architecture.md` — System architecture
- `docs/use-cases.md` — 9 deployment patterns including SIGNAL
- `docs/plans/` — Design docs and implementation plans

## Blockers

- None. v0.3.0 release is complete and pushed.
