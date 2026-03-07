# OpenClaw on Budget Android: Optimization Guide

> **Device:** Google Pixel 10a (2026) — 8 GB RAM, 128 GB storage, Tensor G5, $349 MSRP
> **Goal:** Run a reliable, always-on AI gateway on the cheapest current-gen Pixel
> **Status:** Working in production — gateway + SSH + Tailscale, accessible from anywhere

---

## Why This Matters

This isn't a novelty. A $349 phone running OpenClaw is:

1. **A personal AI node you own.** No cloud VM, no monthly compute bill, no vendor lock-in. Your AI runs on hardware in your pocket.

2. **Always-on, always-connected.** Phones have LTE/5G + WiFi failover, battery backup, and sleep states optimized over a decade of mobile engineering. No UPS needed.

3. **A bridge to every messaging platform.** OpenClaw connects WhatsApp, Telegram, Discord, Slack, iMessage — your phone already has accounts on all of them. One gateway, all channels.

4. **Proof that AI infrastructure is democratized.** If a budget Pixel can run this, anyone can. No $2000 GPU rig, no cloud credits, no DevOps team. Install Termux, run three commands, done.

5. **A real edge node.** Local file access, camera, sensors, location, Bluetooth — capabilities a cloud VM will never have. Your AI can interact with the physical world.

### Real-World Use Cases (Not Novelty)

| Use Case | How It Works | Why a Phone |
|----------|-------------|-------------|
| **24/7 AI assistant** | OpenClaw gateway routes messages from any channel to Claude/GPT via OpenRouter | Always on, always connected, battery-backed |
| **Home automation hub** | OpenClaw skills trigger smart home APIs, monitor sensors | Local network access, no cloud dependency |
| **Personal API gateway** | Route AI requests from multiple devices through one endpoint | Tailscale gives stable IP from anywhere |
| **Development companion** | SSH in from laptop, ask AI to help with code, search docs | Phone sits on desk, always ready |
| **Field data collector** | Camera + GPS + AI = intelligent data capture | It's a phone — sensors are native |
| **Notification triage** | AI reads incoming messages, prioritizes, summarizes | Connected to all your messaging apps |
| **Content pipeline** | Draft → review → publish across social channels | Multi-channel output from one input |
| **Learning/tutoring** | Always-available AI tutor, conversation history persists | Personal device, private context |
| **Emergency fallback** | If your main infra goes down, the phone keeps working | Independent power, independent network |
| **Multi-agent relay** | Phone runs gateway, routes to different AI models per task | OpenRouter gives access to 100+ models |

---

## Baseline Metrics

Measured on Pixel 10a running Termux + OpenClaw 2026.3.2 + Node.js v24.13.0:

| Metric | Value | Notes |
|--------|-------|-------|
| **Total RAM** | 7.4 GB | Shared with Android OS + apps |
| **Available RAM** | ~930 MB | After Android + Termux + gateway |
| **Gateway RSS** | ~370 MB | 4.7% of total RAM |
| **Gateway CPU** | ~5% idle | Spikes during active chat |
| **Swap used** | 3.7 GB / 3.7 GB | Android zram — fully utilized |
| **OpenClaw on disk** | 641 MB | node_modules |
| **Config on disk** | 458 KB | ~/.openclaw/ |
| **Storage free** | 205 GB / 228 GB | 89% available |
| **Startup time** | ~8 seconds | Cold start to listening |
| **WebSocket latency** | 50-100 ms | Loopback, local |

### What These Numbers Mean

- **370 MB RSS is fine.** The phone has 7.4 GB and Android manages memory aggressively. The gateway will be kept alive as a foreground service.
- **Swap is full** — this is normal on Android. zram compresses inactive memory pages in RAM. It's not disk swap, it's memory compression. No performance penalty.
- **641 MB install** is large but one-time. On a 128 GB phone, this is 0.5% of storage.
- **5% idle CPU** means negligible battery impact. The real CPU cost is in chat responses, which are brief spikes.

---

## Optimized Configuration

### Gateway Config (`~/.openclaw/openclaw.json`)

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "openrouter/anthropic/claude-3.5-haiku"
      },
      "compaction": {
        "mode": "safeguard"
      }
    }
  },
  "commands": {
    "native": "auto",
    "nativeSkills": "auto",
    "restart": false,
    "ownerDisplay": "raw"
  },
  "discovery": {
    "mdns": {
      "mode": "off"
    }
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "loopback",
    "auth": {
      "mode": "none"
    }
  }
}
```

### Environment (`~/.openclaw/.env`)

```bash
OPENROUTER_API_KEY=sk-or-v1-your-key-here
OPENCLAW_DISABLE_BONJOUR=1
```

### Key Optimization Decisions

| Setting | Value | Why |
|---------|-------|-----|
| `model.primary` | `openrouter/anthropic/claude-3.5-haiku` | Fastest, cheapest model. Phone is just a relay — inference runs on OpenRouter's servers |
| `discovery.mdns.mode` | `off` | Termux can't do multicast. Disabling stops log spam and saves CPU cycles |
| `OPENCLAW_DISABLE_BONJOUR` | `1` | Belt-and-suspenders with mdns.mode=off |
| `gateway.bind` | `loopback` | Only localhost can connect. Security without auth overhead |
| `gateway.auth.mode` | `none` | Safe because bind=loopback. Eliminates rate-limiter issues with multiple local clients |
| `commands.restart` | `false` | Prevents runaway restart loops on crash. Manual restart is more predictable |
| `compaction.mode` | `safeguard` | Prevents context window overflow on long conversations |

### Model Selection Strategy

The phone doesn't run the AI model — it relays to OpenRouter. Choose models based on:

| Model | Cost (per 1M tokens) | Speed | Best For |
|-------|---------------------|-------|----------|
| `openrouter/anthropic/claude-3.5-haiku` | ~$0.25 in / $1.25 out | Fastest | Quick tasks, triage, simple Q&A |
| `openrouter/anthropic/claude-sonnet-4-5` | ~$3 in / $15 out | Fast | Code, analysis, complex tasks |
| `openrouter/anthropic/claude-opus-4-6` | ~$15 in / $75 out | Slower | Deep reasoning, long documents |
| `openrouter/google/gemini-2.5-pro` | ~$1.25 in / $10 out | Fast | Large context, multimodal |

Switch models from the canvas UI or CLI:
```bash
openclaw config set agents.defaults.model.primary "openrouter/anthropic/claude-sonnet-4-5"
```

---

## Performance Optimizations Applied

### 1. Disable mDNS/Bonjour

Termux lacks multicast socket permissions. Without disabling, the gateway retries every 60 seconds, generating ~1440 useless log entries per day.

```bash
openclaw config set discovery.mdns.mode off
```

### 2. Use Loopback + No Auth

When the gateway only binds to `127.0.0.1`, authentication adds overhead without security benefit. Every app connecting from localhost would need the token, and rate limiting can lock you out if multiple clients connect simultaneously (phone browser + SSH tunnel).

```bash
openclaw config set gateway.bind loopback
openclaw config set gateway.auth.mode none
```

### 3. Node.js Memory Limit (Optional)

Cap Node.js heap to prevent the gateway from growing unbounded:

```bash
# In ~/.bashrc or startup script:
export NODE_OPTIONS="--max-old-space-size=256"
```

This limits the V8 heap to 256 MB. The gateway typically uses ~150-200 MB of heap, so this provides headroom while preventing runaway growth.

### 4. Termux Wake Lock

Prevent Android from killing Termux in the background:

```bash
# Acquire wake lock (in Termux notification, tap and select "Acquire wakelock")
termux-wake-lock
```

Or from the Termux notification shade: long-press → "Acquire wakelock"

### 5. Termux Battery Optimization Exemption

Android aggressively kills background apps. Exempt Termux:

1. Settings → Apps → Termux → Battery → Unrestricted
2. Or: Settings → Battery → Battery optimization → All apps → Termux → Don't optimize

### 6. Auto-Start Gateway on Termux Launch

Add to `~/.bashrc`:

```bash
# Auto-start OpenClaw gateway if not already running
if ! pgrep -f "openclaw-gateway" > /dev/null 2>&1; then
  echo "[openclaw] Starting gateway..."
  nohup openclaw gateway run > ~/openclaw-gateway.log 2>&1 &
  sleep 3
  echo "[openclaw] Gateway started (PID $(pgrep -f openclaw-gateway))"
fi
```

### 7. SSH Auto-Start on Boot

```bash
# In ~/.bashrc:
if ! pgrep -f sshd > /dev/null 2>&1; then
  sshd
  echo "[sshd] Started on port 8022"
fi
```

---

## Native Termux vs proot-distro

**Use native Termux for OpenClaw.** We tested both:

| Feature | Native Termux | proot-distro Ubuntu |
|---------|--------------|-------------------|
| `os.networkInterfaces()` | Works | EACCES (error 13) — **blocks gateway** |
| `tmux` | Works | Dies silently (ptrace limitation) |
| `npm install` cross-fs | Works | `rename()` syscall fails |
| Gateway startup | 8 seconds | Crashes immediately |
| Overhead | None | ptrace interception on every syscall |

proot-distro is great for apt-based tools and development, but OpenClaw's gateway must run in native Termux where Node.js has direct access to network interfaces.

### Hybrid Approach

Run OpenClaw in native Termux, use proot-distro for other tools:

```bash
# Native Termux (gateway lives here):
nohup openclaw gateway run &

# proot Ubuntu (dev tools live here):
proot-distro login ubuntu -- bash -c "python3 my_script.py"
```

---

## Remote Access Architecture

```
┌─────────────────────────────────────────────┐
│  Your Mac / Laptop                          │
│                                             │
│  Browser → http://127.0.0.1:18789/canvas/   │
│       ↓                                     │
│  SSH Tunnel (port 18789 → Pixel:18789)      │
│       ↓                                     │
│  ssh -f -N -L 18789:127.0.0.1:18789 termux │
│       ↓ (via Tailscale 100.80.237.25:8022)  │
└─────────────────────────────────────────────┘
          ↓
┌─────────────────────────────────────────────┐
│  Pixel 10a (Termux)                         │
│                                             │
│  sshd :8022 ← accepts key-based auth       │
│       ↓                                     │
│  OpenClaw Gateway :18789 (loopback only)    │
│       ↓                                     │
│  WebSocket → OpenRouter API                 │
│       ↓                                     │
│  Claude / GPT / Gemini (cloud inference)    │
└─────────────────────────────────────────────┘
```

### SSH Config (Mac: `~/.ssh/config`)

```
Host termux
    HostName 100.80.237.25
    Port 8022
    User u0_aXXX
    IdentityFile ~/.ssh/id_ed25519_github
    AddKeysToAgent yes
    UseKeychain yes
    IdentitiesOnly yes
    # Optional: auto-tunnel
    LocalForward 18789 127.0.0.1:18789
    LocalForward 18791 127.0.0.1:18791
```

With `LocalForward` in SSH config, just `ssh termux` and the tunnel is automatic.

### Quick Access Commands

```bash
# One-liner: tunnel + browser
ssh -f -N -L 18789:127.0.0.1:18789 termux && open http://127.0.0.1:18789/__openclaw__/canvas/

# Check if gateway is running
ssh termux 'pgrep -af openclaw-gateway'

# View live logs
ssh termux 'tail -f ~/openclaw-gateway.log'

# Restart gateway
ssh termux 'kill -9 $(pgrep -f openclaw-gateway); sleep 2; nohup openclaw gateway run > ~/openclaw-gateway.log 2>&1 &'
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Gateway won't start | `gateway.mode` not set | `openclaw config set gateway.mode local` |
| "No API key for provider anthropic" | Model ID uses `anthropic/` prefix | Change to `openrouter/anthropic/model-name` |
| "gateway already running" | Previous instance still alive | `kill -9 $(pgrep -f openclaw-gateway)` |
| Auth rate limited | Too many failed token attempts | Set `gateway.auth.mode none` and restart |
| Bonjour log spam every 60s | mDNS can't broadcast on Termux | `openclaw config set discovery.mdns.mode off` |
| "uv_interface_addresses error 13" | Running inside proot-distro | Run gateway in native Termux instead |
| SSH "too many auth failures" | Multiple SSH keys offered | Add `IdentitiesOnly yes` to SSH config |
| Termux killed in background | Android battery optimization | Exempt Termux from battery optimization |
| Gateway slow after hours | Node.js memory growth | Set `NODE_OPTIONS="--max-old-space-size=256"` |
| Canvas loads but chat fails | WebSocket not connected | Check gateway logs: `tail ~/openclaw-gateway.log` |

---

## Cost Analysis

### Hardware (One-Time)

| Item | Cost |
|------|------|
| Pixel 10a (128 GB) | $349 |
| USB-C cable (charging) | $10 |
| **Total** | **$359** |

### Monthly Operating Cost

| Item | Cost |
|------|------|
| Electricity (phone charger, ~5W) | ~$0.50 |
| OpenRouter tokens (moderate use, ~1M tokens/day) | ~$5-15 |
| Tailscale (free tier, 1 user) | $0 |
| **Total** | **~$5-16/mo** |

### vs Cloud VM

| | Phone Node | Cloud VM (e.g., GCP e2-medium) |
|--|-----------|-------------------------------|
| Hardware | $349 one-time | $0 |
| Monthly compute | $0 | ~$25-35/mo |
| AI tokens | $5-15/mo | $5-15/mo |
| Network | Your plan | Included |
| Break-even | ~12 months | Never — ongoing |
| After 2 years | $349 + $240 = **$589** | $720 + $240 = **$960** |
| Battery backup | Built-in | $200+ UPS |
| LTE failover | Built-in | Not available |
| Camera/sensors | Yes | No |

---

## What's Next

### Immediate (Issue #3)
- [ ] Auto-start gateway with Termux:Boot plugin
- [ ] Health check cron (restart if gateway dies)
- [ ] Log rotation (prevent disk fill)
- [ ] Connect WhatsApp channel
- [ ] Connect Telegram channel

### Medium Term
- [ ] Multiple AI models with routing rules (Haiku for triage, Sonnet for work)
- [ ] Scheduled tasks via OpenClaw skills
- [ ] Local file management via AI
- [ ] Voice interaction via Termux:API microphone

### Long Term
- [ ] Multi-phone cluster (home + office + car)
- [ ] Phone-to-phone agent communication
- [ ] Edge AI model running locally (llama.cpp on Tensor G5)
- [ ] Sensor fusion (GPS + camera + AI for field work)

---

*Guide created March 7, 2026. Tested on Pixel 10a, OpenClaw 2026.3.2, Termux 0.119.*
*If this runs on a $349 phone, it runs on anything.*
