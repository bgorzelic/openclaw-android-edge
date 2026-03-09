# OpenClaw Skills, Memory, and Agent Configuration: Research Report

> **Date:** 2026-03-08
> **Context:** Pixel 10a edge node running OpenClaw 2026.3.7 in native Termux
> **Device:** 8GB RAM (7.4GB usable), Tensor G4, Android 16, Node.js v25.3.0

---

## Executive Summary

1. **Skills are lightweight Markdown files** -- not code plugins. Installing them adds instructions to the agent's context, not running processes. The 53 official skills in the OpenClaw repo are curated and safe; ClawHub community skills (13,700+) require security vetting.

2. **Memory is file-based, not database-backed.** The workspace at `~/.openclaw/workspace/` uses SOUL.md (identity), AGENTS.md (operating instructions), USER.md (owner profile), MEMORY.md (long-term memory), and daily logs in `memory/YYYY-MM-DD.md`. All bootstrap files reload at every session start and survive compaction.

3. **Model tiering is the primary cost lever.** Using Claude Haiku for heartbeats/simple tasks and reserving Sonnet/Opus for complex work can reduce costs 60-65%. The `openclaw.json` configuration supports primary/fallback chains with per-agent model overrides.

4. **Edge deployment is viable but requires discipline.** The gateway alone uses ~184MB RSS. Skills add context tokens (not RAM), but more skills = more tokens per request = higher cost. A focused set of 6-8 skills is optimal for edge.

5. **Auth profiles rotate automatically on rate limits.** OpenRouter provides the simplest multi-model access for edge deployment. Auth profiles are pinned per session and rotate on 429 errors.

---

## 1. OpenClaw Skills (ClawHub)

### What Skills Actually Are

A skill is a folder containing a `SKILL.md` file with YAML frontmatter and Markdown instructions. When active, the skill's content loads into the agent's context window. Skills are NOT executable code or running processes -- they are structured prompts that teach the agent how to use tools it already has.

```yaml
---
name: tmux
description: Remote-control tmux sessions...
metadata:
  { "openclaw": { "emoji": "...", "os": ["darwin", "linux"], "requires": { "bins": ["tmux"] } } }
---
# Instructions follow in Markdown...
```

### Official Skills (53 in openclaw/openclaw repo)

These ship with OpenClaw and are maintained by the core team:

| Category | Skills |
|----------|--------|
| **Core/Infrastructure** | clawhub, healthcheck, model-usage, session-logs, skill-creator |
| **Coding** | coding-agent, github, gh-issues |
| **Communication** | discord, slack, imsg, bluebubbles, voice-call |
| **Terminal/System** | tmux, oracle, eightctl |
| **Media** | openai-image-gen, openai-whisper, openai-whisper-api, sherpa-onnx-tts, video-frames, camsnap, peekaboo, gifgrep, nano-pdf |
| **Knowledge/Notes** | obsidian, notion, apple-notes, apple-reminders, bear-notes, things-mac, trello |
| **Web/Search** | xurl, summarize, blogwatcher, goplaces, weather |
| **Music** | spotify-player, sonoscli, songsee |
| **Smart Home** | openhue, nano-banana-pro |
| **Utilities** | 1password, canvas, gemini, sag, wacli, ordercli, mcporter, gog, himalaya, blucli |

### ClawHub Community Registry

- **13,729 community skills** as of Feb 28, 2026
- Browse at: https://clawhub.ai (formerly clawhub.com)
- Vector-search powered discovery
- **Security warning:** 12-20% of community skills flagged as malicious in audits. Always review SKILL.md source before installing.

### Installation Commands

```bash
# Install the ClawHub CLI
npm i -g clawhub

# Search for skills
clawhub search "postgres backups"

# Install a skill (goes to ./skills/ in workspace)
clawhub install my-skill
clawhub install my-skill --version 1.2.3

# List installed skills
clawhub list

# Update all installed skills
clawhub update --all

# Update a specific skill
clawhub update my-skill
```

Default install location: `./skills/` under the current working directory (or falls back to the configured OpenClaw workspace at `~/.openclaw/workspace/skills/`).

### Skills vs Tools Distinction

Skills are instruction manuals. Actual capabilities are controlled by `tools.allow` in `openclaw.json`. A skill teaches the agent *how* to use a tool, but the tool must be independently available and permitted.

### Recommended Skills for Pixel 10a Edge Node

**Tier 1: Install immediately (essential for your setup)**

| Skill | Why | Binary Requirement |
|-------|-----|--------------------|
| `tmux` | Monitor/control Claude Code sessions remotely | `tmux` |
| `session-logs` | Search conversation history, track costs | `jq`, `rg` |
| `github` | PR/issue management from edge node | `gh` |
| `healthcheck` | Security audit and host hardening | none (uses openclaw CLI) |
| `clawhub` | Manage skills on-device | `clawhub` (npm) |
| `model-usage` | Track token spend and cost | none |

**Tier 2: Install when needed**

| Skill | Why | Binary Requirement |
|-------|-----|--------------------|
| `coding-agent` | Delegate tasks to Claude Code | `claude` |
| `weather` | Lightweight utility, no API key needed | `curl` |
| `summarize` | Summarize web pages and documents | none |

**Tier 3: Skip for edge (not applicable on Android/Termux)**

- apple-notes, apple-reminders, bear-notes, things-mac (macOS only)
- imsg, bluebubbles (macOS/iOS only)
- peekaboo, camsnap (require macOS camera APIs)
- spotify-player, sonoscli, openhue (desktop/smart home)
- discord, slack (run these on the channel side, not on the edge node)

### Installation Sequence for Pixel 10a

```bash
# SSH into device
ssh termux

# Ensure prerequisites are installed
pkg install tmux jq ripgrep

# Install clawhub CLI
npm i -g clawhub

# Install Tier 1 skills
clawhub install tmux
clawhub install session-logs
clawhub install github
clawhub install healthcheck
clawhub install model-usage

# Verify
clawhub list
```

---

## 2. OpenClaw Memory and Intelligence

### Workspace File Layout

```
~/.openclaw/
├── openclaw.json              # Main configuration
├── credentials/               # API keys and tokens
│   ├── openrouter
│   ├── anthropic
│   └── synthetic
├── agents/<agentId>/
│   ├── agent/
│   │   └── auth-profiles.json # Auth rotation config
│   └── sessions/              # Conversation transcripts
│       ├── sessions.json      # Session index
│       └── <session-id>.jsonl # Full conversation logs
└── workspace/                 # Agent's persistent memory
    ├── SOUL.md                # Identity and values (bootstrap)
    ├── AGENTS.md              # Operating instructions (bootstrap)
    ├── USER.md                # Owner profile (bootstrap)
    ├── TOOLS.md               # Tool usage notes (bootstrap)
    ├── MEMORY.md              # Long-term memory (bootstrap)
    ├── HEARTBEAT.md           # Heartbeat behavior (bootstrap)
    ├── BOOTSTRAP.md           # Additional bootstrap context
    ├── memory/                # Daily logs
    │   ├── 2026-03-07.md
    │   ├── 2026-03-08.md
    │   └── ...
    └── skills/                # Installed skills
        ├── tmux/
        ├── github/
        └── ...
```

### Bootstrap Files (loaded every session)

These files are read at the start of every reasoning cycle and survive context compaction:

| File | Purpose | Size Guidance |
|------|---------|---------------|
| **SOUL.md** | Agent identity, personality, values, boundaries | 50-150 lines |
| **AGENTS.md** | Operating instructions, rules, priorities | As needed |
| **USER.md** | Owner profile, preferences, contact info | Short |
| **TOOLS.md** | Tool usage notes and customizations | As needed |
| **MEMORY.md** | Long-term durable memory (cheat sheet) | Under 100 lines |
| **HEARTBEAT.md** | Heartbeat check-in behavior | Short |

**Critical detail:** Sub-agent sessions only inject AGENTS.md and TOOLS.md. Other bootstrap files are filtered out.

### Memory Layers

**Layer 1: Daily Logs (`memory/YYYY-MM-DD.md`)**
- Automatically written during pre-compaction flush
- Today + yesterday auto-loaded; older logs pulled on-demand via `memory_search`/`memory_get`
- Capture: decisions, active tasks, status updates, links shared
- These do NOT count against bootstrap truncation limits

**Layer 2: MEMORY.md (Long-term)**
- Persistent cheat sheet, not a journal
- Contains durable decisions, learned preferences, behavioral rules
- Reloads from disk at every turn
- Keep under 100 lines
- Only put things here that should be true across EVERY session

**Layer 3: Session Logs (`sessions/*.jsonl`)**
- Full conversation transcripts in JSONL format
- Searchable via `session-logs` skill with jq/rg
- Include cost tracking per response

### Memory Access Tools

| Tool | Function |
|------|----------|
| `memory_search` | Hybrid keyword/embedding search across all memory files |
| `memory_get` | Targeted file reads by name and line range |

The memory protocol requires the agent to:
1. Search memory first before answering questions about past work
2. Check `memory/today's-date` for active context when starting tasks

### Memory Consolidation Best Practice

Weekly hygiene: promote durable rules and decisions from daily logs into MEMORY.md. This can be automated via `openclaw cron add`.

```bash
# Git-backup the workspace (recommended)
cd ~/.openclaw/workspace
git init
git add -A
git commit -m "Initial workspace backup"
# Add to cron for daily auto-commit
```

Exclude from git: `~/.openclaw/credentials/` and `openclaw.json` (contains tokens).

### Embedding Search on Edge

Track A (built-in search) runs a small embedding model locally. On the Pixel 10a with 8GB RAM, this should work but may add latency. If memory search feels slow, you can disable the vector component and fall back to keyword-only mode.

### SOUL.md Best Practices

Based on community research and the official template:

1. **Keep it 50-150 lines** -- most effective souls are 1-2 pages
2. **Define explicit action tiers:**
   - Auto-execute: read files, search memory
   - Notify after: join servers, update memory
   - Ask first: send emails, spend money, destructive actions
3. **Test across model tiers** -- run the same prompts through your primary model AND your cheap model. Where the cheap model drifts, your spec needs to be more explicit.
4. **Be specific about voice** -- "Have opinions. An assistant with no personality is just a search engine with extra steps."
5. **Skip performative helpfulness** -- "Be genuinely helpful, not performatively helpful. Skip the 'Great question!' filler."

### Example SOUL.md Structure for Edge Node

```markdown
# Soul

You are [name], Brian's always-on edge agent running on a Pixel 10a.

## Identity
- You run 24/7 on a resource-constrained device
- You are cost-conscious -- prefer Haiku for simple tasks
- You are security-aware -- this is a network-exposed device

## Values
- Reliability over features
- Cost efficiency over capability maximalism
- Transparency about what you can and cannot do

## Boundaries
- Auto-execute: memory reads, file reads, weather, status checks
- Notify after: memory writes, git operations
- Ask first: anything that costs money, external API calls, sending messages

## Voice
- Direct, concise, no filler
- Technical when talking to Brian
- Report problems immediately, don't minimize

## Context
- Device: Pixel 10a, 8GB RAM, Termux, native Node.js
- Access: SSH via Tailscale, WebChat on localhost:18789
- Primary model: Claude 3.5 Haiku via OpenRouter
```

---

## 3. Agent Configuration

### openclaw.json Structure

Location: `~/.openclaw/openclaw.json`

```jsonc
{
  // Gateway settings
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "loopback",          // CRITICAL: never expose to network
    "auth": {
      "mode": "token",
      "token": "<RANDOM_TOKEN>",
      "allowTailscale": true
    }
  },

  // Agent defaults
  "agents": {
    "defaults": {
      "model": {
        "primary": "openrouter/anthropic/claude-3.5-haiku",
        "fallbacks": [
          "openrouter/google/gemini-2.5-flash-lite",
          "openrouter/deepseek/deepseek-chat"
        ]
      },
      // Model catalog (allowlist for /model command)
      "models": {
        "openrouter/anthropic/claude-3.5-haiku": { "alias": "haiku" },
        "openrouter/anthropic/claude-sonnet-4-5": { "alias": "sonnet" },
        "openrouter/anthropic/claude-opus-4-6": { "alias": "opus" },
        "openrouter/google/gemini-2.5-flash-lite": { "alias": "flash" },
        "openrouter/deepseek/deepseek-chat": { "alias": "deepseek" }
      },
      // Heartbeat: cheap model for periodic check-ins
      "heartbeat": {
        "every": "30m",
        "model": "openrouter/google/gemini-2.5-flash-lite"
      },
      // Sub-agent model (for spawned tasks)
      "subagents": {
        "model": "openrouter/deepseek/deepseek-reasoner"
      }
    },
    // Concurrency limits (important for edge!)
    "maxConcurrent": 2,
    "subagents": {
      "maxConcurrent": 4
    }
  },

  // Tools configuration
  "tools": {
    "profile": "full",
    "web": {
      "search": { "enabled": true },
      "fetch": { "enabled": true }
    }
  },

  // Channel configuration (add as needed)
  "telegram": {
    "enabled": true,
    "dmPolicy": "pairing",
    "botToken": "<TELEGRAM_BOT_TOKEN>"
  }
}
```

### Model Tiering Strategy for Edge

| Task | Recommended Model | Cost/1M Tokens | Rationale |
|------|-------------------|----------------|-----------|
| **Heartbeats** | Gemini 2.5 Flash-Lite | $0.50 | Check-ins every 30m should be near-free |
| **Simple queries** | Claude 3.5 Haiku | ~$1.00 | Fast, cheap, good enough for 80% of tasks |
| **Daily work** | Claude Sonnet 4.5 | ~$6.00 | Switch via `/model sonnet` for complex work |
| **Complex reasoning** | Claude Opus 4.6 | ~$30.00 | Reserve for architecture decisions, use sparingly |
| **Sub-agents** | DeepSeek Reasoner | ~$2.74 | Good reasoning at low cost for background tasks |

**Projected edge node cost:** $30-50/month with disciplined tiering (vs $200+ with Opus as default).

### Auth Profiles

Location: `~/.openclaw/agents/<agentId>/agent/auth-profiles.json`

```json
{
  "auth": {
    "profiles": {
      "openrouter:primary": { "mode": "api_key" }
    },
    "order": {
      "openrouter": ["openrouter:primary"]
    }
  }
}
```

Key behaviors:
- Auth profiles are **pinned per session** (not rotated per request) to keep provider caches warm
- Reset on `/new`, `/reset`, or compaction
- Auto-rotate to next profile on rate-limit errors (429)
- Non-rate-limit errors are NOT retried with alternate keys

### Managing Auth via CLI

```bash
# Check auth profile order
openclaw models auth order get --provider openrouter

# Paste a token manually
openclaw models auth paste-token --provider openrouter

# Set up via onboarding wizard
openclaw onboard --auth-choice apiKey --token-provider openrouter --token "$OPENROUTER_API_KEY"
```

---

## 4. Edge Deployment Best Practices

### Resource Budget for Pixel 10a (8GB RAM)

| Component | RAM Usage | Notes |
|-----------|-----------|-------|
| Android OS + system | ~3.5 GB | Baseline, non-negotiable |
| Termux runtime | ~50 MB | Shell + basic tools |
| OpenClaw gateway | ~184 MB | Measured RSS on your device |
| Node.js overhead | ~100 MB | V8 heap + runtime |
| Claude Code (if running) | ~200-300 MB | Separate Node.js process |
| Tailscale | ~30 MB | Always-on VPN |
| **Available headroom** | **~3.5 GB** | Comfortable margin |

### Performance Tuning

```bash
# NODE_OPTIONS for gateway (already configured per your OPTIMIZATION-GUIDE)
export NODE_OPTIONS="--max-old-space-size=384"

# Keep Termux alive
termux-wake-lock

# Disable battery optimization for Termux (in Android Settings)
# Settings > Apps > Termux > Battery > Unrestricted

# Watchdog (already configured, runs every 2 min)
```

### Skill Selection Principles for Edge

1. **Fewer skills = fewer tokens per request = lower cost.** Each active skill adds its full SKILL.md to the agent's context. On a cost-constrained edge node, be selective.

2. **Prefer skills with no binary requirements** or skills whose binaries are already installed (tmux, jq, rg, gh, curl).

3. **Skip browser automation skills** -- headless browser runtimes are unreliable in Termux.

4. **Skip macOS/iOS-only skills** -- apple-notes, imsg, peekaboo, etc.

5. **Install skills that reduce costs** -- model-usage and session-logs help you monitor spend.

### Heartbeat Configuration

Heartbeats are periodic check-ins where the agent reviews its state. On edge:

- Use the cheapest possible model (Gemini Flash-Lite at $0.50/M tokens)
- Set interval to 30m (default) or longer to reduce costs
- Heartbeat DM delivery: opt-out if you don't want unsolicited messages

```jsonc
"heartbeat": {
  "every": "30m",
  "model": "openrouter/google/gemini-2.5-flash-lite"
  // Set "dm": false to disable heartbeat DMs
}
```

### Security Hardening for Edge

1. **Gateway bind to loopback only** (`bind: "loopback"`) -- never expose to network
2. **Use Tailscale for remote access** -- encrypted, authenticated tunnel
3. **Run `openclaw security audit --deep`** after initial setup
4. **Review memory files regularly** for unexpected persistent rules (memory poisoning is a known attack vector)
5. **Pin skill versions** -- `clawhub install my-skill --version 1.2.3`
6. **Never install unreviewed community skills** -- 12-20% flagged as malicious

### Cron Scheduling for Maintenance

```bash
# Schedule daily security audit
openclaw cron add --name "healthcheck:security-audit" \
  --schedule "0 3 * * *" \
  --prompt "Run openclaw security audit and report findings to memory"

# Schedule weekly memory consolidation
openclaw cron add --name "memory:consolidate" \
  --schedule "0 4 * * 0" \
  --prompt "Review this week's daily logs. Promote any durable decisions or rules to MEMORY.md. Keep MEMORY.md under 100 lines."

# Schedule daily version check
openclaw cron add --name "healthcheck:update-status" \
  --schedule "0 6 * * *" \
  --prompt "Run openclaw update status and note if an update is available"
```

### Workspace Git Backup

```bash
# Initialize workspace as git repo
cd ~/.openclaw/workspace
git init
echo "# OpenClaw Workspace" > .gitignore

# Add and commit (exclude credentials)
git add SOUL.md AGENTS.md USER.md TOOLS.md MEMORY.md HEARTBEAT.md memory/ skills/
git commit -m "Initial workspace backup"

# Add remote (use your private config repo)
git remote add origin git@github.com:bgorzelic/pixel-10a-edge-node-config.git
```

---

## 5. Implementation Checklist

### Immediate Actions (This Session)

- [ ] SSH into Pixel 10a and install clawhub CLI: `npm i -g clawhub`
- [ ] Install Tier 1 skills: tmux, session-logs, github, healthcheck, model-usage
- [ ] Create/refine SOUL.md with edge-appropriate identity
- [ ] Create USER.md with owner profile
- [ ] Review and update MEMORY.md
- [ ] Run `openclaw security audit --deep`

### Configuration Actions

- [ ] Update `openclaw.json` with model tiering (Haiku primary, Flash-Lite heartbeat)
- [ ] Configure model catalog with aliases for quick `/model` switching
- [ ] Set `maxConcurrent: 2` and `subagents.maxConcurrent: 4` for edge
- [ ] Set heartbeat to 30m with cheapest model
- [ ] Verify auth-profiles.json is using OpenRouter

### Ongoing Maintenance

- [ ] Schedule daily security audit via cron
- [ ] Schedule weekly memory consolidation
- [ ] Back up workspace to private git repo
- [ ] Monitor costs via model-usage skill and session-logs
- [ ] Review MEMORY.md weekly for unexpected entries

---

## 6. Open Questions and Gaps

1. **Embedding search on Termux**: The built-in memory search runs a small embedding model locally. Unknown whether this works reliably in Termux's ARM64 environment or requires a native binary that may not be available. May need to fall back to keyword-only search.

2. **ClawHub community skill vetting**: No automated way to verify community skills are safe. The 12-20% malicious rate means manual SKILL.md review is essential for every community skill.

3. **Heartbeat cost at scale**: Even at $0.50/M tokens, heartbeats every 30 minutes accumulate. If the agent writes substantial daily logs during heartbeats, costs could exceed projections. Monitor via model-usage skill.

4. **Sub-agent spawning on edge**: The coding-agent skill can spawn Claude Code as a sub-agent, which creates a second Node.js process. On 8GB RAM this should work but needs monitoring -- two heavy processes could trigger Android's OOM killer.

5. **Skill context window budget**: With Claude 3.5 Haiku's context window, loading 6+ skills plus all bootstrap files plus conversation history could approach limits. Need to measure actual token usage with the recommended skill set.

---

## Sources

- [OpenClaw GitHub Repository](https://github.com/openclaw/openclaw) -- Official source, 283k stars
- [OpenClaw ClawHub Registry](https://github.com/openclaw/clawhub) -- Skill directory
- [Awesome OpenClaw Skills](https://github.com/VoltAgent/awesome-openclaw-skills) -- 5,400+ curated skills
- [OpenClaw Multi-Model Routing Guide](https://velvetshark.com/openclaw-multi-model-routing) -- Cost optimization
- [OpenClaw Memory Masterclass](https://velvetshark.com/openclaw-memory-masterclass) -- Memory architecture deep dive
- [OpenClaw Config Reference (MoltFounders)](https://moltfounders.com/openclaw-runbook/config-reference) -- Annotated openclaw.json
- [OpenClaw on Android Setup (AidanPark)](https://github.com/AidanPark/openclaw-android) -- Native Termux approach
- [OpenClaw Android Full Setup Guide](https://vpn07.com/en/blog/2026-openclaw-android-phone-full-setup-guide.html) -- Android-specific guidance
- [OpenClaw SOUL.md Templates Discussion](https://github.com/openclaw/openclaw/discussions/20131) -- Community templates
- [OpenClaw 2026.2.25 Release Notes (GlobalClaw)](https://globalclaw.github.io/globalclaw-blog/posts/2026-02-26-openclaw-2026-2-25.html) -- Heartbeat changes
- [DigitalOcean: What are OpenClaw Skills](https://www.digitalocean.com/resources/articles/what-are-openclaw-skills) -- Skill architecture overview
- [Microsoft Security: Running OpenClaw Safely](https://www.microsoft.com/en-us/security/blog/2026/02/19/running-openclaw-safely-identity-isolation-runtime-risk/) -- Security considerations
- [OpenClaw Auth Profiles Issue #19649](https://github.com/openclaw/openclaw/issues/19649) -- Web UI for auth management
- [ClawHub.ai](https://clawhub.ai/) -- Official skill registry browser
