# Frequently Asked Questions

OpenClaw on Google Pixel 10a — practical answers to common questions.

---

## General

### What is OpenClaw?

OpenClaw is an AI agent gateway built on Node.js. It provides multi-channel messaging (WebSocket, HTTP, CLI), tool orchestration, and model routing. It acts as a self-hosted intermediary between you and cloud AI providers.

### Does the phone run AI models locally?

No. The phone performs zero inference. It runs the gateway process, which relays requests to [OpenRouter](https://openrouter.ai/) for cloud-based model inference. The Pixel 10a is a networking and orchestration node, not a GPU compute node.

### Why not just use a cloud VM?

Cost. A Pixel 10a costs $349 one-time and runs for years. A comparable cloud VM (2 vCPU, 4GB RAM) costs $40-80/month, or $960-1920 over two years. The phone also provides built-in battery backup (no UPS needed), onboard sensors, and LTE failover — all included in the hardware price. See [docs/device-strategy.md](device-strategy.md) for the full comparison.

### Is this a toy project or production-ready?

Honest answer: it is a documented proof-of-concept that runs in production for the author. It handles real workloads reliably, but it has not been hardened for enterprise deployment. Treat it as a solid starting point for personal or small-team use.

---

## Hardware

### Why Pixel 10a specifically?

The Pixel 10a hits a practical sweet spot: $349 price, 7 years of guaranteed OS and security updates, Tensor G4 with efficient cores for low idle power, and it has been tested and documented end-to-end. See [docs/device-strategy.md](device-strategy.md) for selection criteria.

### Does it work on other phones?

Expected to work on any Android phone with 8GB+ RAM and Termux support. The guide is written against the Pixel 10a, but the software stack is not device-specific. See [docs/device-strategy.md](device-strategy.md) for compatibility notes.

### Can I use an old phone I have lying around?

Maybe. Requirements:

- **Android 12+** for Termux compatibility
- **6GB RAM minimum**, 8GB+ recommended
- Functional USB-C charging (it will be plugged in 24/7)
- Working WiFi

Older phones with less RAM or outdated Android versions will likely hit issues with Termux or run out of memory under load.

### Does the phone need to be rooted?

No. Everything — Termux, proot-distro, Node.js, the gateway, SSH — runs without root.

---

## Installation

### How long does setup take?

About 30 minutes for someone comfortable with a terminal. The [INSTALL-GUIDE.md](../INSTALL-GUIDE.md) walks through each phase. Most of the time is spent on package installation and initial configuration, not troubleshooting.

### Why proot-distro for install but native Termux for runtime?

The `koffi` native dependency (used by OpenClaw for FFI) needs a standard glibc build environment to compile. proot-distro provides an Ubuntu environment with glibc for that build step. Once compiled, the gateway runs fine in native Termux with its Bionic libc. This avoids the proot performance overhead at runtime.

### Why not Docker on the phone?

Docker requires Linux kernel features (cgroups, namespaces at root level) that Android does not expose to userspace. You cannot run Docker on a non-rooted Android device. Termux is the practical alternative — it provides a real Linux environment without requiring root or kernel modifications.

---

## Performance

### How much RAM does it use?

The gateway process uses approximately 323 MB RSS. With Termux and system overhead, roughly 910 MB remains free on an 8GB device. This leaves comfortable headroom for the OS and background processes. See [OPTIMIZATION-GUIDE.md](../OPTIMIZATION-GUIDE.md) for memory tuning details.

### Does it drain battery?

No. The gateway shows 0% CPU at idle (no polling loops). With a USB-C charger providing ~5W, the phone stays at 100% battery. It is designed to run plugged in 24/7.

### What is the latency?

- **Gateway HTTP latency (loopback):** ~65ms for request processing
- **End-to-end response time:** 1-5 seconds, dominated entirely by OpenRouter/model provider latency

The phone adds negligible overhead. Response speed depends on which model you route to and current provider load.

### Can it handle multiple simultaneous users?

The gateway is a single-process Node.js application. It handles concurrent WebSocket connections without issue for personal or small-team use (a handful of simultaneous users). It is not designed for 100+ concurrent users — that would require a different architecture.

---

## Networking

### How do I access it remotely?

SSH tunnel over Tailscale (WireGuard-based mesh VPN). Tailscale gives the phone a stable IP address accessible from any of your devices, regardless of network changes. See [INSTALL-GUIDE.md](../INSTALL-GUIDE.md) Phases 8-9 for setup instructions.

### Is it secure?

The gateway binds to loopback (127.0.0.1) only — it is not exposed to the network directly. Remote access goes through SSH with key-based authentication over a WireGuard tunnel (Tailscale). No passwords, no open ports on the public network. See [docs/threat-model.md](threat-model.md) for the full security analysis.

### Can I use it without Tailscale?

Yes, but you need another way to reach the phone with a stable address. Options include a static IP, dynamic DNS service, or a reverse proxy/tunnel (Cloudflare Tunnel, ngrok). Tailscale is recommended because it is the simplest to set up and maintain.

### What if the phone loses WiFi?

If the phone has an active SIM card with a data plan, LTE provides automatic failover. Tailscale reconnects over the cellular connection. No configuration needed — Android handles the network switch transparently.

---

## Cost

### What does it cost to run?

- **Hardware:** $349 one-time (Pixel 10a)
- **Electricity:** negligible (~5W, under $1/month)
- **API tokens:** $5-15/month via OpenRouter, depending on usage volume and model choice
- **Tailscale:** free tier covers personal use

Total ongoing cost: $5-15/month. Total two-year cost: ~$589. Compare to a cloud VM at $960+ over the same period.

### Is there a free option?

OpenRouter offers free-tier access to some models (certain Llama variants and others). Quality and speed vary. You can start with free models and switch to paid ones as needed — the gateway routes to whatever model you configure.

### How does it compare to ChatGPT Plus?

ChatGPT Plus is $20/month fixed, regardless of usage. This setup is pay-per-token through OpenRouter: cheaper for moderate use, potentially more expensive for heavy use. The trade-off: you get multi-model access (Claude, GPT-4, Llama, Gemini, etc.), full API control, tool orchestration, and no vendor lock-in.

---

## Troubleshooting

### Gateway won't start

Check these in order:

1. **Model ID format:** Must use `openrouter/` prefix (e.g., `openrouter/anthropic/claude-3.5-haiku`)
2. **.env file:** Verify `OPENROUTER_API_KEY` is set and valid
3. **Port conflict:** Confirm port 18789 is not already in use (`lsof -i :18789`)

### "No API key found for provider anthropic"

Wrong model ID format. Use `openrouter/anthropic/claude-3.5-haiku`, not `anthropic/claude-3.5-haiku`. The `openrouter/` prefix tells the gateway to route through OpenRouter rather than trying to hit Anthropic's API directly.

### Gateway dies when screen is off

Android aggressively kills background processes. Fix all three:

1. **Doze whitelist:** Add Termux in Android Settings > Battery > Unrestricted
2. **Battery optimization:** Set Termux to "Unrestricted" (not "Optimized")
3. **Wake lock:** Run `termux-wake-lock` before starting the gateway

See [OPTIMIZATION-GUIDE.md](../OPTIMIZATION-GUIDE.md) for additional stability settings.

### mDNS/Bonjour spam in logs

Set `discovery.mdns.mode` to `"off"` in `openclaw.json`. This disables local network discovery, which is unnecessary for a headless server setup.

### SSH connection refused

Check in order:

1. **sshd running:** `pgrep sshd` on the phone (start with `sshd`)
2. **Correct port:** Termux uses port 8022 by default, not 22
3. **Tailscale connected:** Verify both devices show as connected in the Tailscale admin console
4. **Firewall:** Ensure no firewall rules blocking port 8022 on the Tailscale interface

---

## Further Reading

- [INSTALL-GUIDE.md](../INSTALL-GUIDE.md) — Step-by-step setup instructions
- [OPTIMIZATION-GUIDE.md](../OPTIMIZATION-GUIDE.md) — Performance tuning and stability
- [docs/architecture.md](architecture.md) — System architecture and design decisions
- [docs/threat-model.md](threat-model.md) — Security analysis and mitigations
- [docs/device-strategy.md](device-strategy.md) — Device selection and hardware comparison

---

*Author: Brian Gorzelic / AI Aerial Solutions*
*Last Updated: March 2026*
