# Design: Three-Repo Architecture + Edge Dev Platform

> **Date:** 2026-03-08
> **Author:** Brian Gorzelic / AI Aerial Solutions
> **Status:** Approved

## Problem

The `openclaw-android-edge` repo mixes public documentation with device-specific state (logs, screenshots, `.env`). The SIGNAL network intelligence project lives on GitHub but isn't properly separated as its own application. There's no backup of the actual device configuration. The dev environment on the Pixel 10a was incomplete.

## Decision

Split into three repos with clear boundaries. Establish the Pixel 10a as an edge development platform with Claude Code running locally.

## Three-Repo Architecture

### Repo 1: `openclaw-android-edge` (Public)

**Purpose:** Living install guide for running OpenClaw on Android. Updated every time the setup is hardened.

**Contains:**
- Install guide (INSTALL-GUIDE.md)
- Optimization guide (OPTIMIZATION-GUIDE.md)
- Architecture, use cases, device strategy, threat model, FAQ docs
- Sanitized examples (no real keys, no device identity)
- OSS essentials (LICENSE, CONTRIBUTING, SECURITY, ROADMAP, CHANGELOG)
- "Related Projects" link to SIGNAL repo

**Does NOT contain:**
- Real API keys or credentials
- Device-specific state (identity, sessions, memory DB)
- Raw device logs or properties
- Actual boot scripts with hardcoded keys

**Changes for this release (v0.3.0):**
- Update OpenClaw version: 2026.3.2 → 2026.3.7
- Update Node.js version: v22.x (proot) → v25.3.0 (native)
- Update gateway RSS: 323 MB → 184 MB
- Mark persistence/auto-start as working (was "optional/planned")
- Add Claude Code on Termux as documented capability
- Add dev environment setup section
- Remove `logs/` directory (moves to private repo)
- Add "Related Projects" section linking to SIGNAL
- Update ROADMAP: Phase 2 done, auto-start done
- Add v0.3.0 CHANGELOG entry

### Repo 2: `SIGNAL` (Public)

**Purpose:** Standalone network intelligence application. Own lifecycle.

**No changes in this session.** The `openclaw-android-edge` README links to it as a related project.

### Repo 3: `pixel-10a-edge-node-config` (Private, NEW)

**Purpose:** Complete device config backup. If the phone dies, this repo + a new Pixel = full restore.

**Structure:**
```
pixel-10a-edge-node-config/
├── README.md                        # What this is + restore guide
├── .gitignore                       # Exclude sessions, node_modules, .tmp-claude
│
├── openclaw/
│   ├── openclaw.json                # Gateway config
│   ├── .env                         # API keys (OPENROUTER_API_KEY, etc.)
│   ├── cron/
│   │   └── jobs.json
│   ├── identity/
│   │   ├── device.json
│   │   └── device-auth.json
│   └── workspace/
│       ├── IDENTITY.md
│       ├── SOUL.md
│       ├── USER.md
│       ├── TOOLS.md
│       ├── AGENTS.md
│       ├── BOOTSTRAP.md
│       ├── HEARTBEAT.md
│       ├── README.md
│       ├── ANDROID_OPTIMIZATION.md
│       ├── BUDGET_ANDROID_GUIDE.md
│       ├── OPTIMIZATION_COMPLETE.md
│       ├── SUMMARY.md
│       ├── scripts/
│       │   ├── auto_restart.sh
│       │   ├── controlled_reboot.sh
│       │   ├── openclaw_systemd_service.sh
│       │   ├── telegram_bot_monitor.py
│       │   └── telegram_bot_security.sh
│       └── credentials/
│           ├── telegram_bot.env
│           └── telegram_bot_security_notes.md
│
├── termux/
│   ├── termux.properties
│   └── boot/
│       └── start-openclaw.sh        # Self-healing boot script
│
├── shell/
│   ├── bashrc                       # .bashrc with auto-start + env vars
│   ├── watchdog.sh                  # openclaw-watchdog.sh (cron every 2m)
│   └── crontab.txt                  # Exported crontab
│
├── agents/
│   └── main/
│       └── agent/
│           ├── models.json          # Model provider config
│           └── auth-profiles.json   # Auth profiles (contains API key)
│
└── snapshots/
    └── 2026-03-08.md                # Version + package snapshot
```

## Dev Environment (Confirmed Working)

The Pixel 10a runs a complete development environment in native Termux:

| Tool | Version | Purpose |
|------|---------|---------|
| Node.js | v25.3.0 | OpenClaw runtime, skill development |
| Python | 3.13.12 | App development (SIGNAL, sensors) |
| Claude Code | 2.1.71 | AI coding agent on the phone itself |
| git + gh | 2.53.0 / 2.87.3 | Version control, GitHub ops |
| tmux | 3.6a | Persistent dev sessions |
| jq | 1.8.1 | JSON processing |
| sqlite3 | 3.52.0 | Data persistence |
| Termux:API | 0.59.1 | 80+ Android sensor commands |
| OpenClaw | 2026.3.7 | AI gateway (running) |

**Claude Code wrapper:** `claude-dev` command installed at `$PREFIX/bin/claude-dev` — uses `proot -b $PREFIX/tmp:/tmp` to solve the `/tmp` sandbox issue on Termux.

**Sensor access limitation:** `termux-api` commands (camera, GPS, WiFi scan, cellular info) require Android foreground context. They work from the phone's Termux session but hang over SSH. Sensor-heavy apps must be triggered locally or via OpenClaw (which has foreground context).

**Available on demand:** `openjdk-21`, `kotlin`, `gradle`, `aapt2`, `d8`, `apksigner` — full APK build toolchain in Termux repos.

## Implementation Order

1. Create `pixel-10a-edge-node-config` private repo on GitHub
2. Pull device config files via SSH and commit to private repo
3. Clean `openclaw-android-edge`: remove device-specific files, update docs
4. Update version numbers, metrics, and status across all public docs
5. Add v0.3.0 changelog and tag release
6. Update HANDOFF.md
