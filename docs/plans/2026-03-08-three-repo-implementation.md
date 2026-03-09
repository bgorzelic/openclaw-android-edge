# Three-Repo Architecture Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Split the single repo into three (public guide, SIGNAL app, private device config), update all docs to reflect v2026.3.7 + persistence + dev environment, and back up the live device state.

**Architecture:** Create private `pixel-10a-edge-node-config` repo on GitHub, pull device config via SSH, clean public repo of device-specific files, update all version numbers and metrics across docs.

**Tech Stack:** git, gh CLI, SSH (to Pixel 10a via Tailscale), markdown

---

### Task 1: Create Private Repo on GitHub

**Step 1: Create the repo**

```bash
gh repo create bgorzelic/pixel-10a-edge-node-config --private --description "Pixel 10a edge node configuration backup — OpenClaw gateway, Termux, boot scripts, watchdog" --clone
```

Expected: Repo created at github.com/bgorzelic/pixel-10a-edge-node-config, cloned locally.

**Step 2: Set up directory structure**

```bash
cd pixel-10a-edge-node-config
mkdir -p openclaw/cron openclaw/identity openclaw/workspace/scripts openclaw/workspace/credentials
mkdir -p termux/boot shell agents/main/agent snapshots
```

**Step 3: Create .gitignore**

Create: `pixel-10a-edge-node-config/.gitignore`

```gitignore
# Session data (large, transient)
*.jsonl
*.jsonl.reset.*
sessions/

# Node artifacts
node_modules/
.tmp-claude/

# OS
.DS_Store

# Git inside workspace (nested repos)
openclaw/workspace/.git/

# SQLite WAL/journal (transient)
*.sqlite-wal
*.sqlite-journal

# npm cache
npm-cache/
```

**Step 4: Create README.md**

Create: `pixel-10a-edge-node-config/README.md`

```markdown
# Pixel 10a Edge Node Configuration

Private backup of the Google Pixel 10a running OpenClaw as an always-on AI edge node.

## What This Is

Complete configuration backup for device restore. If the phone dies, this repo + a new Pixel + the [public install guide](https://github.com/bgorzelic/openclaw-android-edge) = full restore.

## Structure

- `openclaw/` — OpenClaw gateway config, identity, workspace, credentials
- `termux/` — Termux properties and boot scripts
- `shell/` — .bashrc, watchdog script, crontab
- `agents/` — Agent model and auth config
- `snapshots/` — Periodic version/package snapshots

## Restore Procedure

1. Follow the [install guide](https://github.com/bgorzelic/openclaw-android-edge) through Phase 6
2. Copy `shell/bashrc` to `~/.bashrc`
3. Copy `termux/termux.properties` to `~/.termux/termux.properties`
4. Copy `termux/boot/start-openclaw.sh` to `~/.termux/boot/start-openclaw.sh`
5. Copy `shell/watchdog.sh` to `~/openclaw-watchdog.sh` and `chmod +x`
6. Import crontab: `crontab shell/crontab.txt`
7. Copy `openclaw/*` to `~/.openclaw/` (preserves config, identity, workspace)
8. Copy `agents/` contents to `~/.openclaw/agents/`
9. Install Claude Code: `npm install -g @anthropic-ai/claude-code`
10. Install dev tools: `pkg install -y python tmux jq sqlite`
11. Authenticate Claude Code: `claude-dev` (run on phone screen, follow OAuth flow)
12. Restart gateway: reboot phone or run `~/.termux/boot/start-openclaw.sh`

## Related Repos

- [openclaw-android-edge](https://github.com/bgorzelic/openclaw-android-edge) — Public install guide
- [SIGNAL](https://github.com/bgorzelic/SIGNAL) — Network intelligence app

## Security

This repo contains API keys and device identity. Keep it private.
```

**Step 5: Commit skeleton**

```bash
git add -A
git commit -m "feat: initial repo structure with README and restore guide"
```

---

### Task 2: Pull Device Config via SSH

**Step 1: Pull OpenClaw config**

```bash
cd pixel-10a-edge-node-config
scp -P 8022 termux:~/.openclaw/openclaw.json openclaw/openclaw.json
scp -P 8022 termux:~/.openclaw/.env openclaw/.env
scp -P 8022 termux:~/.openclaw/cron/jobs.json openclaw/cron/jobs.json
```

**Step 2: Pull identity**

```bash
scp -P 8022 termux:~/.openclaw/identity/device.json openclaw/identity/device.json
scp -P 8022 termux:~/.openclaw/identity/device-auth.json openclaw/identity/device-auth.json
```

**Step 3: Pull agent config**

```bash
scp -P 8022 termux:~/.openclaw/agents/main/agent/models.json agents/main/agent/models.json
scp -P 8022 termux:~/.openclaw/agents/main/agent/auth-profiles.json agents/main/agent/auth-profiles.json
```

**Step 4: Pull workspace docs (not .git, not nested repos)**

```bash
for f in IDENTITY.md SOUL.md USER.md TOOLS.md AGENTS.md BOOTSTRAP.md HEARTBEAT.md README.md ANDROID_OPTIMIZATION.md BUDGET_ANDROID_GUIDE.md OPTIMIZATION_COMPLETE.md SUMMARY.md; do
  scp -P 8022 "termux:~/.openclaw/workspace/$f" "openclaw/workspace/$f" 2>/dev/null
done
```

**Step 5: Pull workspace scripts and credentials**

```bash
scp -P 8022 termux:~/.openclaw/workspace/scripts/* openclaw/workspace/scripts/
scp -P 8022 termux:~/.openclaw/workspace/credentials/* openclaw/workspace/credentials/
```

**Step 6: Pull Termux config**

```bash
scp -P 8022 termux:~/.termux/termux.properties termux/termux.properties
scp -P 8022 termux:~/.termux/boot/start-openclaw.sh termux/boot/start-openclaw.sh
```

**Step 7: Pull shell config**

```bash
scp -P 8022 termux:~/.bashrc shell/bashrc
scp -P 8022 termux:~/openclaw-watchdog.sh shell/watchdog.sh
ssh termux "crontab -l" > shell/crontab.txt
```

**Step 8: Create version snapshot**

```bash
ssh termux 'echo "# Device Snapshot — $(date +%Y-%m-%d)"
echo
echo "## Software Versions"
echo "| Component | Version |"
echo "|-----------|---------|"
echo "| OpenClaw | $(openclaw --version 2>&1) |"
echo "| Node.js | $(node --version) |"
echo "| npm | $(npm --version) |"
echo "| Python | $(python3 --version 2>&1 | cut -d" " -f2) |"
echo "| Claude Code | $(claude --version 2>&1) |"
echo "| git | $(git --version | cut -d" " -f3) |"
echo "| gh | $(gh --version 2>&1 | head -1 | cut -d" " -f3) |"
echo "| tmux | $(tmux -V | cut -d" " -f2) |"
echo "| sqlite3 | $(sqlite3 --version 2>&1 | cut -d" " -f1) |"
echo "| Termux | 0.118.3 |"
echo "| Termux:API | $(dpkg -s termux-api 2>/dev/null | grep Version | cut -d" " -f2) |"
echo
echo "## Resources"
echo "| Metric | Value |"
echo "|--------|-------|"
MEM=$(ps -o rss= -p $(pgrep -f openclaw-gateway) 2>/dev/null | head -1)
echo "| Gateway RSS | ${MEM:-unknown} KB |"
echo "| Free RAM | $(free -m | grep Mem | awk "{print \$4}") MB |"
echo "| Free Disk | $(df -h /data 2>/dev/null | tail -1 | awk "{print \$4}") |"
echo
echo "## Installed Packages"
echo "\`\`\`"
pkg list-installed 2>/dev/null | grep -E "^[a-z]" | head -50
echo "\`\`\`"' > snapshots/2026-03-08.md
```

**Step 9: Commit all device config**

```bash
git add -A
git commit -m "feat: pull complete device config from Pixel 10a

OpenClaw 2026.3.7, Node v25.3.0, Python 3.13.12, Claude Code 2.1.71.
Includes gateway config, boot script, watchdog, workspace, credentials."
```

**Step 10: Push to GitHub**

```bash
git push -u origin main
```

---

### Task 3: Clean Public Repo — Remove Device-Specific Files

Working directory: `/Users/bgorzelic/dev/projects/openclaw-pixel10a-guide`

**Step 1: Remove logs directory (now in private repo)**

```bash
git rm -r logs/
```

**Step 2: Remove .env file if tracked**

```bash
git rm --cached .env 2>/dev/null || true
```

**Step 3: Update .gitignore to exclude device state**

Modify: `.gitignore` — add entries for device-specific files:

```
.env
logs/
*.sqlite
*.jsonl
```

**Step 4: Commit cleanup**

```bash
git add -A
git commit -m "chore: remove device-specific files (moved to private config repo)"
```

---

### Task 4: Update README.md

Modify: `README.md`

**Changes:**
- Hero metrics table: 323 MB → 184 MB
- "What Works Now" table: mark auto-start and persistence as Stable
- Architecture diagram: update OpenClaw version reference
- Add Claude Code to "What Works Now"
- Add "Related Projects" section before "Built By" linking to SIGNAL
- Update "Last updated" date to March 8, 2026
- Add dev environment mention in "What You Get" section

---

### Task 5: Update INSTALL-GUIDE.md

Modify: `INSTALL-GUIDE.md`

**Changes:**
- Header: OpenClaw Version 2026.3.2 → 2026.3.7
- Device Specs table: $499 → $349 (line 38, already wrong in some places)
- Phase 7: Add note about `claude-dev` wrapper for Claude Code
- Phase 11: Update optimized .bashrc with NODE_OPTIONS=384 (matches boot script)
- Software Versions appendix: Update Node.js, npm, OpenClaw versions
- Add Phase 12: Developer Environment Setup (Claude Code, Python, tmux, dev tools)
- Errors table: Add entry for Claude Code /tmp sandbox fix

---

### Task 6: Update OPTIMIZATION-GUIDE.md

Modify: `OPTIMIZATION-GUIDE.md`

**Changes:**
- Update benchmark numbers: 323 MB → 184 MB RSS
- Note Node.js v25 memory improvements
- Update NODE_OPTIONS from 256 to 384 (matches production boot script)

---

### Task 7: Update ROADMAP.md

Modify: `ROADMAP.md`

**Changes:**
- Phase 2: Mark as DONE (was IN PROGRESS)
- Phase 4: Mark auto-start as done, watchdog as done
- Add SIGNAL reference under Phase 5 (Edge Intelligence)
- Add dev environment (Claude Code on device) under Phase 4

---

### Task 8: Update CHANGELOG.md

Modify: `CHANGELOG.md`

**Add v0.3.0 entry:**

```markdown
## [0.3.0] - 2026-03-08

### Added
- Claude Code (v2.1.71) running on the Pixel 10a with proot /tmp wrapper
- Full dev environment: Python 3.13, tmux, jq, sqlite3
- claude-dev wrapper script for Termux /tmp sandbox fix
- Phase 12: Developer Environment Setup in INSTALL-GUIDE.md
- Private config backup repo (pixel-10a-edge-node-config)
- Related Projects section in README linking to SIGNAL
- Design doc for three-repo architecture

### Changed
- OpenClaw upgraded: 2026.3.2 → 2026.3.7
- Node.js upgraded: v22.x (proot) → v25.3.0 (native)
- Gateway RSS reduced: 323 MB → 184 MB (43% reduction)
- NODE_OPTIONS memory cap: 256 MB → 384 MB (matches production)
- Boot persistence: documented as stable (was optional/planned)
- Watchdog: documented as production-proven

### Removed
- logs/ directory (moved to private config repo)
- Device-specific files from public repo

### Fixed
- Consistent $349 pricing across all docs
```

---

### Task 9: Update docs/use-cases.md

Modify: `docs/use-cases.md`

**Changes:**
- Add Use Case #9: Network Intelligence (SIGNAL) — brief description linking to the SIGNAL repo, explaining it runs as an OpenClaw skill on the Pixel 10a using termux-wifi-scaninfo, termux-telephony-cellinfo, and termux-location

---

### Task 10: Update HANDOFF.md and Commit Everything

Modify: `HANDOFF.md`

**Rewrite for current session state.**

**Final commit and tag:**

```bash
git add -A
git commit -m "docs: v0.3.0 — three-repo architecture, dev environment, version updates

- OpenClaw 2026.3.7, Node v25.3.0, gateway RSS 184 MB
- Claude Code running on Pixel 10a via claude-dev wrapper
- Private config repo created (pixel-10a-edge-node-config)
- Full dev environment: Python, tmux, jq, sqlite3
- SIGNAL linked as related project
- Persistence and watchdog documented as stable"

git tag -a v0.3.0 -m "Three-repo architecture, dev environment, OpenClaw 2026.3.7"
git push origin main --tags
```
