# Run OpenClaw on a $349 Google Pixel

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Device: Pixel 10a](https://img.shields.io/badge/Device-Pixel_10a-4285F4?logo=google)](docs/device-strategy.md)
[![Gateway: OpenClaw](https://img.shields.io/badge/Gateway-OpenClaw-blueviolet)](https://openclaw.com)
[![Models: OpenRouter](https://img.shields.io/badge/Models-OpenRouter-orange)](https://openrouter.ai)
[![Newsletter](https://img.shields.io/badge/Newsletter-SpookyJuice.AI-black)](https://spookyjuice.ai)

> **An always-on AI gateway in your pocket. No cloud VM. No monthly compute bills. Just a phone, Termux, and 30 minutes.**

<table>
<tr>
<td align="center"><strong>184 MB</strong><br><sub>Gateway RAM</sub></td>
<td align="center"><strong>0% idle</strong><br><sub>CPU at rest</sub></td>
<td align="center"><strong>65 ms</strong><br><sub>HTTP latency</sub></td>
<td align="center"><strong>$349</strong><br><sub>Total hardware</sub></td>
<td align="center"><strong>$5-15/mo</strong><br><sub>API tokens</sub></td>
<td align="center"><strong>30 min</strong><br><sub>Setup time</sub></td>
</tr>
</table>

This guide documents how to transform a retail Google Pixel 10a into a production-grade AI edge node running OpenClaw — capable of processing messages from Telegram, WhatsApp, Discord, Slack, and more via Claude, GPT, or Gemini. It works. The phone sits on a desk, powered via USB-C, accessible from anywhere through Tailscale. Total hardware cost: $349. Monthly operating cost: $5-15 in API tokens.

This isn't a novelty demo. It's a blueprint for why you don't need a $25/month cloud VM to run a personal AI assistant.

---

## What You Get

After following this guide, you'll have:

- **Always-on OpenClaw gateway** running in Termux on the Pixel 10a
- **Remote SSH access** from your laptop via Tailscale (works from anywhere)
- **Multi-channel integration** — messages from WhatsApp, Telegram, Discord route to the phone's gateway
- **Local file access** — the phone's camera, microphone, GPS, storage are available to AI skills
- **Scheduled automation** — run recurring tasks like "7 AM briefing" or "end-of-day summary"
- **Sub-100ms latency** over local network or Tailscale VPN
- **Live logs and monitoring** with a web dashboard
- **Developer environment** — Python, Claude Code, and full dev tooling run directly on the phone

The phone never touches inference — it relays messages to OpenRouter (giving access to Haiku, Sonnet, Opus, Gemini, and 100+ other models). All compute happens in the cloud at cheaper rates because you're not renting the server.

---

## Why a Phone?

| What | Phone | Cloud VM |
|-----|-------|----------|
| **Hardware (one-time)** | $349 | $0 |
| **Monthly compute** | $0 | $25-35 |
| **Tokens/inference** | $5-15 | $5-15 |
| **Power/UPS** | Built-in battery | $200+ |
| **LTE failover** | Yes, native | No |
| **Camera/sensors** | Yes | No |
| **Total after 2 years** | $589 | $960+ |

A phone is already designed to be always-on. It has its own power supply, can survive network interruptions, and includes sensors (camera, GPS, mic, accelerometer) that give AI real-world context. The Pixel 10a gets 7 years of OS updates and costs $30 less than the monthly compute bill for a equivalent cloud VM.

---

## What Works Now

| Feature | Status | Notes |
|---------|--------|-------|
| OpenClaw gateway on Termux | Stable | Runs in native Termux (not proot) |
| SSH remote access | Stable | Port 8022, key-based auth recommended |
| Tailscale networking | Stable | Gives stable IP from anywhere |
| Multiple AI models | Stable | Claude Haiku (default), can switch to Sonnet/Opus |
| HTML/CSS dashboard | Working | Access via SSH tunnel or Tailscale |
| Scheduled cron tasks | Working | Via system cron + watchdog |
| Claude Code on device | Working | v2.1.71 via claude-dev wrapper |
| Auto-start on boot | Stable | Termux:Boot + self-healing script |
| Watchdog auto-restart | Stable | Cron every 2 min, HTTP health check |
| WhatsApp channel | Planned | Issue #3 |
| Telegram channel | Planned | Issue #3 |
| Local llama.cpp inference | Exploring | Edge AI on Tensor G4 |

---

## Architecture

```
Your Device (Mac/Laptop)
  ├─ SSH tunnel via Tailscale IP (100.x.y.z:8022)
  └─ Browser → http://127.0.0.1:18789/canvas/

         ↓ (SSH port forward)

Pixel 10a (Termux)
  ├─ sshd :8022 (Termux, no root needed)
  ├─ OpenClaw Gateway :18789 (loopback only)
  └─ Tailscale daemon (always-on VPN)

         ↓ (HTTPS WebSocket)

OpenRouter API
  ├─ Claude 3.5 Haiku (default — fast, cheap)
  ├─ Claude Sonnet 4.5 (switchable)
  ├─ Claude Opus 4.6 (switchable)
  ├─ Gemini 2.5 Pro (switchable)
  └─ 100+ other models (available)
```

The phone does zero AI inference. It's a relay and a dashboard. All the compute happens on OpenRouter's servers, which is cheaper than running a VM and gives you choice of models.

---

## Key Use Cases

1. **24/7 Personal AI Assistant** — Message the gateway via Telegram/WhatsApp and get instant responses. No phone screen required — it all happens via text.

2. **Mobile Command Center** — SSH into your phone from anywhere and ask OpenClaw to check server status, fetch logs, or restart services. The phone acts as a portable gateway to your infrastructure.

3. **Field Data Collection** — The phone's camera + GPS + AI means you can snap a photo of equipment and get structured analysis. Site inspections, document scanning, drone integration.

4. **Home Automation Hub** — Control lights, thermostats, cameras via natural language from any messaging app. Requires Home Assistant or direct IoT API skills.

5. **Scheduled Content Pipeline** — Automated workflows: "8 AM: summarize email + calendar", "Friday 5 PM: weekly status report from git commits", "Every 2 hours: check monitoring alerts".

6. **Multi-Node Relay** — Run the phone as a secondary node alongside your main Mac or VPS. The phone provides camera/sensors; the laptop provides compute for heavy tasks.

---

## Quick Start

### Prerequisites

- Google Pixel 10a (128 GB, $349 from Best Buy or Google Store)
- macOS or Linux with `adb` installed (`brew install android-platform-tools`)
- USB-C cable
- WiFi or cellular internet
- Tailscale account (free)
- OpenRouter account with API key (~$5-15/month usage)

### 30-Minute Installation

1. **Connect phone via USB, enable USB debugging**
   ```bash
   adb devices  # verify connection
   ```

2. **Optimize Android for background processes** (run from Mac)
   ```bash
   adb shell dumpsys deviceidle whitelist +com.termux
   adb shell cmd appops set com.termux RUN_IN_BACKGROUND allow
   adb shell cmd appops set com.termux RUN_ANY_IN_BACKGROUND allow
   adb shell svc power stayon usb
   adb shell settings put system screen_off_timeout 1800000
   adb shell settings put global wifi_sleep_policy 2
   ```

3. **Install Termux** (via ADB from your Mac)
   ```bash
   curl -L -o /tmp/termux.apk \
     "https://github.com/termux/termux-app/releases/download/v0.118.3/termux-app_v0.118.3%2Bgithub-debug_arm64-v8a.apk"
   adb install /tmp/termux.apk
   adb shell am start -n com.termux/.HomeActivity
   ```

4. **Inside Termux, install OpenClaw**
   ```bash
   pkg update -y && pkg install -y proot-distro openssh
   proot-distro install ubuntu
   proot-distro login ubuntu

   # Inside Ubuntu:
   apt update && apt install -y curl
   curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
   apt install -y nodejs
   npm config set cache /tmp/npm-cache
   npm install -g openclaw
   ```

5. **Configure & run**
   ```bash
   openclaw --version              # verify install
   openclaw gateway run            # start the gateway
   ```

6. **SSH access** (on phone Termux, exit proot first)
   ```bash
   # Set password and start sshd
   passwd
   sshd

   # From your Mac (after Tailscale is installed on phone):
   ssh termux   # using Tailscale IP
   ```

**For the complete guide with troubleshooting, errors, and edge cases, see [INSTALL-GUIDE.md](INSTALL-GUIDE.md) (1,050+ lines).**

---

## Performance & Cost

### Benchmark Results (Pixel 10a, native Termux)

Measured on a live gateway:

- **Memory**: 184 MB RSS (2.4% of total RAM)
- **CPU (idle)**: 0.00% (zero measurable load when waiting)
- **HTTP latency**: 65ms average (131ms cold, 45-52ms warm)
- **Threads**: 11 (1 event loop + 4 libuv + 6 V8/GC)
- **Storage used**: 641 MB (node_modules + config)
- **Swap**: Fully utilized (zRAM compression, not disk — normal for Android)

All numbers are sustainable for 24/7 operation on a phone.

### Monthly Cost Breakdown

| Item | Cost |
|------|------|
| Hardware (one-time) | $349 |
| Electricity | ~$0.50/month |
| OpenRouter tokens (1M tokens/day moderate use) | $5-15/month |
| Tailscale (free tier) | $0 |
| **Total ongoing** | **~$5-16/month** |

Compare: Cloud VM (e.g., GCP e2-medium) is $25-35/month compute + $5-15 tokens + $200 UPS = $30-50/month ongoing, or $360-600/year. The phone breaks even after 12 months and costs $240/year after that (just tokens).

See [OPTIMIZATION-GUIDE.md](OPTIMIZATION-GUIDE.md) for deeper cost analysis and performance tuning.

---

## Repository Structure

```
openclaw-pixel10a-guide/
├── README.md                     # This file
├── INSTALL-GUIDE.md             # Full 1,050-line install walkthrough
├── OPTIMIZATION-GUIDE.md        # Performance tuning + cost analysis
├── CONTRIBUTING.md              # How to contribute
├── SECURITY.md                  # Security policy
├── ROADMAP.md                   # Project roadmap (6 phases)
├── CHANGELOG.md                 # Version history
├── LICENSE                      # MIT License
│
├── docs/
│   ├── architecture.md          # Deep system architecture (7 layers)
│   ├── use-cases.md             # Real-world use cases with examples
│   ├── device-strategy.md       # Device selection and compatibility
│   ├── threat-model.md          # Security analysis and trust boundaries
│   ├── faq.md                   # Frequently asked questions
│   └── social-launch-kit.md     # Pre-written social media posts
│
├── scripts/
│   └── benchmark.sh             # Automated metrics collection
│
├── assets/
│   └── hero-diagram.md          # Mermaid architecture diagrams
│
├── .github/
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── ISSUE_TEMPLATE/
│       ├── bug_report.md
│       └── device_report.md
│
├── issue-02/                     # Newsletter Issue #2
│   ├── the-persistent-ghost-issue-02.html
│   └── meta.json
│
├── logs/                         # Device properties, error logs
│
├── benchmarks/                   # Performance snapshots
│
└── screenshots/                  # Install process screenshots
```

---

## Learning Path

**New to the project?** Start here:

1. **This README** — Understand what you're building
2. **[INSTALL-GUIDE.md](INSTALL-GUIDE.md)** — Follow the 11-phase installation walkthrough (includes troubleshooting for all common errors)
3. **[OPTIMIZATION-GUIDE.md](OPTIMIZATION-GUIDE.md)** — Learn how to tune the gateway for reliability and cost
4. **[docs/architecture.md](docs/architecture.md)** — Deep dive into each layer of the system

**Already installed?** See:

- `scripts/benchmark.sh` — Measure your gateway's performance
- `docs/use-cases.md` — Real-world workflows with configuration examples
- `docs/faq.md` — Common questions and troubleshooting
- `docs/device-strategy.md` — Choosing a device for your use case

---

## Documentation

| Document | What It Covers |
|----------|---------------|
| [INSTALL-GUIDE.md](INSTALL-GUIDE.md) | 11-phase walkthrough: USB debugging, Termux, Android power management, proot-distro, OpenClaw install, SSH, Tailscale, workflows, troubleshooting |
| [OPTIMIZATION-GUIDE.md](OPTIMIZATION-GUIDE.md) | Performance tuning, cost analysis (phone vs cloud VM), model selection, benchmark methodology |
| [docs/architecture.md](docs/architecture.md) | 7-layer system architecture with Mermaid diagrams, trust boundaries, data flow |
| [docs/use-cases.md](docs/use-cases.md) | Real-world scenarios with configuration examples |
| [docs/device-strategy.md](docs/device-strategy.md) | Device selection, compatibility tiers, buying guide |
| [docs/threat-model.md](docs/threat-model.md) | Security analysis, threat matrix, data flow classification |
| [docs/faq.md](docs/faq.md) | Common questions, troubleshooting quick reference |
| [ROADMAP.md](ROADMAP.md) | 6-phase roadmap from foundation through ecosystem |

---

## Roadmap

See [ROADMAP.md](ROADMAP.md) for the full 6-phase plan. Highlights:

- **Done:** Install guide, gateway optimization, SSH/Tailscale, benchmarks, 10 workflows
- **In Progress:** Public launch, documentation, community setup
- **Next:** WhatsApp/Telegram channels, auto-start on boot, health monitoring
- **Future:** Multi-phone clusters, local inference on Tensor G4, sensor fusion

---

## Why This Matters

This project proves three things:

1. **AI infrastructure is democratized.** A $349 Pixel can run a production gateway. No GPU rig, no cloud credits, no DevOps team. Install Termux, run three commands, done.

2. **Inference doesn't have to run on your hardware.** By using OpenRouter, the phone becomes a smart relay instead of a compute bottleneck. Cheaper, faster, more model choice.

3. **Phones are underutilized edge computers.** They have cameras, sensors, LTE, batteries, and 7-year support lifecycles. Using them as always-on nodes unlocks capabilities cloud VMs will never have.

If a $349 phone with 8GB RAM can do this, the cloud VM market needs to reconsider its pricing.

---

## Related Projects

- **[SIGNAL](https://github.com/bgorzelic/SIGNAL)** — Network intelligence platform that transforms Android devices into wireless diagnostic sensors. Runs as an OpenClaw skill on the same Pixel 10a hardware.

---

## Built By

**Brian Gorzelic** — AI Aerial Solutions

This project is part of **SpookyJuice.AI**, a newsletter exploring the intersection of AI, infrastructure, and edge computing.

- **Website**: https://spookyjuice.ai
- **Newsletter**: "The Persistent Ghost" on Beehiiv (subscribe for Issue #3+)
- **X/Twitter**: [@SpookyJuiceAI](https://twitter.com/SpookyJuiceAI)
- **GitHub**: This repo

---

## Contributing

Found an error? A shortcut the guide missed? Have a workflow we should document?

Open an issue or submit a PR. This guide is a living document. Every install teaches us something new.

**Particularly interested in:**

- Different Android versions (tested on Android 16; does it work on Android 15 or 14?)
- Different Pixel models (we have a 10a; how does it scale to Pixel Fold or older Pixels?)
- Alternative AI backends (OpenRouter currently; what about local llama.cpp?)
- Channel integrations (Telegram, WhatsApp, Discord, Slack — which are hardest to set up?)
- Workflow documentation (what are you using this for?)

---

## License

MIT License. See [LICENSE](LICENSE).

---

## Stay Updated

This project is part of **[SpookyJuice.AI](https://spookyjuice.ai)** — a newsletter exploring AI infrastructure at the edge.

**[Subscribe to The Persistent Ghost](https://spookyjuice.ai)** for deep dives on running AI on unconventional hardware.

---

<sub>**Last updated:** March 8, 2026 — Tested live on Pixel 10a, gateway running in production. If this runs on a $349 phone, it runs on anything.</sub>
