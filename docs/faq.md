# Frequently Asked Questions

> **Author:** Brian Gorzelic / AI Aerial Solutions
> **Last Updated:** March 2026
> **Device:** Google Pixel 10a — OpenClaw 2026.3.2

Practical answers to questions about running OpenClaw on a Pixel 10a as an always-on AI gateway. Honest about limitations, including ones that are not yet solved.

---

## Table of Contents

- [Does this need root?](#does-this-need-root)
- [Can I use a different phone?](#can-i-use-a-different-phone)
- [How much battery does this use?](#how-much-battery-does-this-use)
- [What if Android kills the process?](#what-if-android-kills-the-process)
- [Is this secure?](#is-this-secure)
- [How much does it cost?](#how-much-does-it-cost)
- [Why not just use a cloud VM?](#why-not-just-use-a-cloud-vm)
- [Can I run local AI models on the phone?](#can-i-run-local-ai-models-on-the-phone)
- [Why does OpenClaw need to install inside proot-distro?](#why-does-openclaw-need-to-install-inside-proot-distro)
- [Why does the gateway run in native Termux if it installs in proot?](#why-does-the-gateway-run-in-native-termux-if-it-installs-in-proot)
- [Why does installation fail in native Termux?](#why-does-installation-fail-in-native-termux)
- [How do I access the Canvas UI from my laptop?](#how-do-i-access-the-canvas-ui-from-my-laptop)
- [Why does Termux SSH run on port 8022 instead of 22?](#why-does-termux-ssh-run-on-port-8022-instead-of-22)
- [What is Tailscale and do I need it?](#what-is-tailscale-and-do-i-need-it)
- [What does "mDNS/Bonjour" in the logs mean and should I care?](#what-does-mdnsbonjour-in-the-logs-mean-and-should-i-care)
- [The gateway shows high RAM usage. Is that a problem?](#the-gateway-shows-high-ram-usage-is-that-a-problem)
- [What is zRAM swap and why is it fully utilized?](#what-is-zram-swap-and-why-is-it-fully-utilized)
- [Can I connect WhatsApp and Telegram channels?](#can-i-connect-whatsapp-and-telegram-channels)
- [How do I update OpenClaw?](#how-do-i-update-openclaw)
- [What happens to my conversations if the gateway crashes?](#what-happens-to-my-conversations-if-the-gateway-crashes)
- [Can I run this on a tablet instead of a phone?](#can-i-run-this-on-a-tablet-instead-of-a-phone)
- [Can I run multiple OpenClaw instances on one phone?](#can-i-run-multiple-openclaw-instances-on-one-phone)
- [Is my conversation data sent to OpenRouter?](#is-my-conversation-data-sent-to-openrouter)
- [Does this work with OpenAI or other providers directly?](#does-this-work-with-openai-or-other-providers-directly)
- [How do I keep the gateway running after a reboot?](#how-do-i-keep-the-gateway-running-after-a-reboot)
- [The first HTTP request to the gateway is slow. Subsequent ones are fast. Why?](#the-first-http-request-to-the-gateway-is-slow-subsequent-ones-are-fast-why)

---

## Does this need root?

No. Everything in this guide — Termux, proot-distro, Node.js, OpenClaw, sshd, Tailscale — runs without root. Termux itself is a normal Android app. proot-distro implements a userspace chroot using ptrace, which does not require root access.

Rooting the phone is explicitly not recommended for this use case. Rooting breaks the Android app sandbox that keeps your API keys and session data isolated from other apps. See [docs/threat-model.md](./threat-model.md) for why the sandbox matters.

---

## Can I use a different phone?

Yes, with caveats. The guide is written and tested on a Pixel 10a running Android 16. The software stack — Termux, proot-distro Ubuntu, Node.js, OpenClaw — is not device-specific. It should work on any Android phone meeting these requirements:

- Android 12 or later (Termux requires Android 12+ for current releases)
- 6GB RAM minimum, 8GB recommended
- aarch64 (arm64-v8a) ABI — all phones made since 2019 qualify
- Termux installed from F-Droid or GitHub Releases, not the Play Store

**Where non-Pixel phones add friction:**

Samsung, Xiaomi, OnePlus, and other OEMs add proprietary battery optimization layers on top of standard Android. These often kill Termux's background process even after you apply the standard ADB optimization commands. [dontkillmyapp.com](https://dontkillmyapp.com) documents per-OEM requirements.

The standard ADB commands in [INSTALL-GUIDE.md](../INSTALL-GUIDE.md) Phase 3 are tested on stock Android (Pixel). On OEM-modified Android, additional manufacturer-specific steps are required and are not documented in this guide.

See [docs/device-strategy.md](./device-strategy.md) for device selection guidance, including a comparison table of Pixel and non-Pixel options.

---

## How much battery does this use?

At idle, the gateway uses 0% CPU (measured over a 5-second sample). The gateway is an I/O-bound process that spends most of its time waiting on network responses. The CPU usage spikes briefly when processing a request, then drops back to zero.

In practice, a USB-C PD charger providing 5W keeps the phone at 100% charge during continuous operation. The phone does not drain when plugged in.

If you are running the phone without a charger (portable use), expect battery consumption similar to having a messaging app running in the background — a few percent per hour at light load. This assumes the gateway is idle most of the time. Active, continuous inference requests would increase CPU usage and battery drain proportionally.

The Tensor G4's efficiency core cluster (Cortex-A520) handles idle gateway work. These cores are designed for exactly this pattern — always-on, low-utilization background tasks at minimal power draw.

---

## What if Android kills the process?

Android has five independent power management layers that can terminate Termux and the gateway. The [INSTALL-GUIDE.md](../INSTALL-GUIDE.md) Phase 3 documents all five and the mitigations for each.

**Summary of required mitigations:**

| Layer | Mitigation | How |
|-------|-----------|-----|
| Doze | Whitelist Termux | `adb shell dumpsys deviceidle whitelist +com.termux` |
| App Standby | Allow background | `adb shell cmd appops set com.termux RUN_IN_BACKGROUND allow` |
| Adaptive Battery | Unrestricted mode | Settings > Apps > Termux > Battery > Unrestricted |
| CPU Freeze | Wake lock | Termux notification > Acquire wakelock |
| WiFi Sleep | Keep WiFi alive | `adb shell settings put global wifi_sleep_policy 2` |

All five must be applied. Missing any one of them results in the gateway going dark after a period of inactivity.

**If the gateway is killed despite mitigations**, the auto-restart snippet in `.bashrc` will restart it on the next Termux shell open. For automatic restart without manual intervention, use Termux:Boot (see [INSTALL-GUIDE.md](../INSTALL-GUIDE.md) Phase 7).

**Impact of a kill:** The gateway process restarts cleanly. No conversation data is lost — session state is persisted to disk in `~/.openclaw/`. The gateway is unavailable during the brief restart period.

---

## Is this secure?

For a personal deployment, yes — the default configuration is well-designed for its threat model.

**What the architecture does well:**
- The gateway binds to `127.0.0.1` only. Nothing on your local network or the internet can reach port 18789 without being on the phone.
- SSH is the only remote access path, and it is accessible only via the Tailscale mesh (WireGuard encrypted).
- SSH uses key-only authentication. Password auth should be disabled after setup.
- API keys and session data are in Termux's app-private storage, inaccessible to other Android apps without a root exploit.
- Android full-disk encryption protects data at rest if the phone is seized locked.

**What the architecture does not protect:**
- Conversation context is sent to OpenRouter per inference request. OpenRouter and the model provider can see it. This is inherent to the relay architecture.
- If the phone is physically taken while unlocked, all local data is accessible.
- If your Tailscale identity account is compromised without 2FA, an attacker can join your tailnet.

**Most important steps you can take:**
1. Enable 2FA on your Tailscale identity provider (Google/GitHub/Microsoft)
2. Disable SSH password authentication
3. Set a screen lock with auto-lock after 30-60 seconds
4. Rotate the OpenRouter API key quarterly

For the full threat model, see [docs/threat-model.md](./threat-model.md).

---

## How much does it cost?

**One-time hardware:**
- Pixel 10a (128GB, unlocked): $349 at Best Buy or Google Store
- USB-C PD charger (if you don't have one): $10-20

**Monthly recurring:**
- Electricity: under $1/month (5W continuous)
- OpenRouter API tokens: $5-15/month at moderate use (varies by model and request volume)
- Tailscale: free tier covers personal use (up to 3 users, 100 devices)

**Total two-year cost: approximately $520-880**

For comparison, a minimal GCP e2-medium cloud VM with comparable RAM costs $25-35/month — $600-840 over two years, without the battery backup, cellular failover, or physical sensor access.

**Token cost breakdown:**
- `openrouter/anthropic/claude-3.5-haiku`: ~$0.25/1M input tokens. A typical conversational exchange with context is 2,000-10,000 tokens. At moderate use (50 exchanges/day), this is approximately $0.50-2.50/day or $15-75/month.
- For lighter use (10-20 exchanges/day), expect $3-15/month.
- For heavy use or more capable models (Sonnet, Opus), costs scale accordingly.

OpenRouter provides real-time cost visibility in the dashboard. Set a spending limit to prevent surprises.

---

## Why not just use a cloud VM?

A cloud VM is a valid choice with different tradeoffs. The phone is not objectively superior — it has specific advantages and limitations.

**Advantages of the phone:**
- No monthly compute cost (hardware paid upfront, then free)
- Built-in battery (no UPS needed; survives power outages)
- LTE/5G cellular radio (failover when home internet goes down)
- Physical sensors (camera, GPS, microphone, accelerometer) for edge computing use cases
- Local network presence (can reach `192.168.x.x` devices directly)
- Physical control (you have the hardware; no cloud provider has access)

**Advantages of a cloud VM:**
- Better uptime guarantees (data center power, redundant networking)
- More compute headroom for heavier workloads
- Can run GPU inference if needed
- No Android power management to fight
- Easier to scale or replace

**For the relay-only gateway use case** (no local inference, just routing to OpenRouter), the phone is the better choice for most personal deployments. The operational complexity is similar, the cost is lower, and the phone provides capabilities a VM cannot.

**For heavy compute, local inference, or SLA-constrained deployments**, a cloud VM is the better substrate.

See the cost comparison table in [OPTIMIZATION-GUIDE.md](../OPTIMIZATION-GUIDE.md) for a year-by-year breakdown.

---

## Can I run local AI models on the phone?

Not in the current default configuration, but it is architecturally possible and on the roadmap.

**Current state:** The gateway relays all inference to OpenRouter. The phone performs zero local model computation.

**What local inference on the Pixel 10a would look like:**
- `llama.cpp` compiled for aarch64, using the Tensor G4's CPU for inference
- Small to medium quantized models (4-bit quantized 7B models fit in available RAM)
- Performance estimate: 5-15 tokens/second on the X4 prime core at 4-bit quantization — usable but noticeably slower than cloud inference

**What does not work today:**
- The Tensor NPU (Neural Processing Unit) is not accessible from Termux without Android system privileges
- Qualcomm's GGML acceleration path (used on Snapdragon phones) does not apply to Tensor
- Local inference at useful speeds for larger models (70B+) is not feasible on 8GB RAM

**Why this matters:** Local inference would enable air-gapped operation (no internet required for inference) and eliminate the data privacy concern of sending conversation context to OpenRouter. For the relay gateway use case as currently deployed, local inference is not necessary.

If you want to experiment with local inference today, llama.cpp can be compiled inside proot-distro Ubuntu and run against quantized models downloaded via `wget`. Performance at 4-bit quantized 7B is usable for non-latency-sensitive tasks.

---

## Why does OpenClaw need to install inside proot-distro?

OpenClaw's `koffi` dependency (a native Foreign Function Interface library) must compile from source during `npm install`. It requires a standard POSIX build environment with `make`, `cmake`, and a C/C++ compiler.

In Termux's native environment, the `make` and `cmake` binaries are compiled against Android's Bionic libc with hardcoded paths under `/data/data/com.termux/files/usr/`. koffi's build system expects a standard GNU/Linux environment with `/bin/sh` and standard library paths. The mismatch causes the build to fail.

proot-distro Ubuntu provides a glibc-based Ubuntu environment where `make`, `cmake`, and `clang` work exactly as expected. `npm install` succeeds there.

See [INSTALL-GUIDE.md](../INSTALL-GUIDE.md) Phase 4 for the full error trace and explanation of why each attempt failed.

---

## Why does the gateway run in native Termux if it installs in proot?

The installation step (where `koffi` is compiled) needs a glibc environment. The runtime does not — once `koffi` is compiled, the resulting `.node` binary runs fine in native Termux.

More importantly, running inside proot-distro at runtime breaks the gateway. proot intercepts syscalls via ptrace and translates file paths, but it mishandles the `getifaddrs()` syscall that Node.js uses to enumerate network interfaces via `os.networkInterfaces()`. This returns EACCES (permission denied) inside proot. The gateway reads this at startup to determine its bind address and exits with an error.

Additionally, `tmux` dies silently inside proot due to ptrace limitations. The proot ptrace interception also adds overhead to every syscall, which affects I/O-intensive workloads.

The working architecture uses proot only for the install step, then runs the gateway binary in native Termux:

```bash
# Inside proot-distro Ubuntu — install step
npm install -g openclaw

# In native Termux — runtime
openclaw gateway run
```

See [OPTIMIZATION-GUIDE.md](../OPTIMIZATION-GUIDE.md) for the Native Termux vs proot-distro comparison table.

---

## Why does installation fail in native Termux?

Three separate failure modes, documented in order in [INSTALL-GUIDE.md](../INSTALL-GUIDE.md) Phase 4:

1. **Missing git** — npm needs git to install packages with git dependencies. Fix: `pkg install -y git`

2. **Missing CMake** — koffi's build system calls CMake during its native compilation step. Fix: `pkg install -y cmake make clang`

3. **make build failure** — Even with cmake and make installed, Termux's make binary has hardcoded paths incompatible with koffi's build system invocation. The make binary prints its help output instead of building, indicating it is not parsing the arguments correctly in this context.

The third failure is not fixable by installing additional packages. The workaround is proot-distro Ubuntu, where the standard glibc-based build tools work normally.

---

## How do I access the Canvas UI from my laptop?

The Canvas is served from the gateway on the phone at `http://127.0.0.1:18789/__openclaw__/canvas/`. Since the gateway binds to loopback, you cannot reach it directly from your laptop. You need an SSH port forward.

**One-time setup** — add `LocalForward` to your SSH config on the laptop:

```
Host termux
    HostName 100.x.y.z        # your phone's Tailscale IP
    Port 8022
    User u0_a314               # your Termux user (run 'whoami' in Termux)
    IdentityFile ~/.ssh/id_ed25519
    LocalForward 18789 127.0.0.1:18789
    IdentitiesOnly yes
```

**To access the Canvas:**

```bash
# 1. Connect with port forward (keep this session open)
ssh termux

# 2. In your browser, navigate to:
open http://127.0.0.1:18789/__openclaw__/canvas/
```

The browser connects to port 18789 locally, the SSH tunnel carries the traffic over the Tailscale-secured SSH connection to the phone, and the gateway responds as if you were browsing on the phone itself.

**Quick one-liner (background tunnel + open browser):**

```bash
ssh -f -N -L 18789:127.0.0.1:18789 termux && \
  open http://127.0.0.1:18789/__openclaw__/canvas/
```

---

## Why does Termux SSH run on port 8022 instead of 22?

Port 22 is a privileged port (below 1024). On Linux and Android, binding to a privileged port requires root. Since Termux runs as an unprivileged Android app without root, it cannot bind to port 22.

Port 8022 is a convention for Termux — it is functionally identical to port 22. The SSH protocol works the same way on both ports. The only difference is that your SSH client config needs `Port 8022` explicitly, since SSH clients default to port 22.

This is why the SSH config in [INSTALL-GUIDE.md](../INSTALL-GUIDE.md) Phase 8 includes `Port 8022`.

---

## What is Tailscale and do I need it?

Tailscale is a VPN service that creates a WireGuard-based encrypted mesh network (a "tailnet") across your devices. Every device on your tailnet gets a stable IP address in the `100.x.y.z` range that works regardless of what physical network the device is on.

**Do you need Tailscale?** For remote access from outside your home network, you need some way to reach the phone with a stable address. Tailscale is the recommended option because:

- It gives the phone a stable IP that does not change when you switch networks
- It handles NAT traversal automatically (no port forwarding in your router)
- WireGuard provides encryption for all traffic
- It works on iOS, macOS, Windows, Linux, and Android
- The free tier covers personal use indefinitely

**Alternatives to Tailscale:**
- Static IP from your ISP + router port forwarding (uncommon, often costs extra)
- Dynamic DNS (DDNS) + router port forwarding (exposes SSH to the internet)
- Cloudflare Tunnel (for HTTP only, not SSH tunneling)
- ZeroTier (similar to Tailscale, open source)
- WireGuard self-hosted (more setup, same underlying technology)

If you only access the phone from your home network and never need remote access, you can use the phone's local IP (`192.168.x.x`) directly without Tailscale.

---

## What does "mDNS/Bonjour" in the logs mean and should I care?

mDNS (multicast DNS) is a local network discovery protocol. OpenClaw uses it to advertise the gateway's presence on the local network so other OpenClaw clients can find it automatically.

On Termux, multicast socket operations are restricted by Android's networking stack. The gateway cannot send multicast packets. Without the configuration change below, OpenClaw retries the mDNS broadcast every 60 seconds and logs a failure each time — roughly 1,440 log lines per day that indicate nothing actionable.

**Fix (already included in the recommended configuration):**

```bash
openclaw config set discovery.mdns.mode off
```

And in `~/.openclaw/.env`:

```bash
OPENCLAW_DISABLE_BONJOUR=1
```

After applying this, the log spam stops. The gateway still works normally — mDNS discovery is not needed for a headless server setup where you know the address explicitly.

If you see this in logs before applying the fix, it is harmless but noisy. After the fix, you should see zero Bonjour-related entries in the log.

---

## The gateway shows high RAM usage. Is that a problem?

The gateway's measured RSS (Resident Set Size) is 323 MB. This is the amount of physical RAM pages the process is actively using.

This is not a problem for the following reasons:

**Node.js reports RSS this way.** V8 (the JavaScript engine) pre-allocates memory for its heap and holds onto it after use. RSS does not drop when objects are garbage-collected; it represents the high-water mark of physical memory used. The working set of objects in use at any moment is smaller.

**323 MB is 4.1% of the phone's RAM.** The phone has 7.56 GB. The gateway uses a small fraction of it. After the OS, Android services, Termux, and the gateway, approximately 910 MB remains available for new allocations.

**The heap is capped at 256 MB.** Setting `NODE_OPTIONS="--max-old-space-size=256"` tells V8 not to grow the heap beyond 256 MB. This prevents the gateway from growing unbounded during long sessions with large context windows.

**zRAM compresses the rest.** Android's zRAM swap compresses cold memory pages into RAM-backed swap. Swap appearing "fully utilized" is normal Android behavior — it means zRAM is working correctly, not that the system is under memory pressure.

If the gateway's RSS is growing over time without a corresponding increase in activity, that could indicate a memory leak. Check `ps -o rss= -p $(pgrep openclaw-gateway)` periodically to observe the trend.

---

## What is zRAM swap and why is it fully utilized?

zRAM is Android's swap implementation. Unlike traditional swap (which writes memory pages to a disk partition), zRAM compresses memory pages and stores them in a reserved portion of RAM. It is RAM-backed, not disk-backed.

When Android's memory management determines a page has not been accessed recently, it compresses that page and stores it in the zRAM partition, freeing up RAM for active processes. When the page is needed again, it is decompressed.

The benchmark shows zRAM swap as fully utilized (3.76 GB used of 3.76 GB total). This means Android has compressed many inactive pages. This is **normal and expected behavior on Android** — it is not an indicator of memory exhaustion or performance problems. Android deliberately fills zRAM to maximize the effective memory available to running processes.

The distinction that matters: if the system runs out of both RAM and zRAM, Android starts killing processes via the OOM killer. The measured configuration (323 MB gateway, ~910 MB available RAM after all processes) provides sufficient headroom that OOM kills are unlikely under normal gateway workloads.

---

## Can I connect WhatsApp and Telegram channels?

**Current status (March 2026):** This is planned for Issue #3 (the next development phase) but not yet implemented. The gateway currently operates through the Canvas web UI and direct API/SSH access.

**Telegram:** Creating a Telegram bot via @BotFather and connecting it to OpenClaw is technically straightforward. The Telegram Bot API has long-polling support that works well for always-on gateway deployments. Once the channel connector is available, connecting a Telegram bot will require only a bot token.

**WhatsApp:** WhatsApp Business API access requires a Meta developer account, a verified phone number, and approval from Meta. The WhatsApp integration is more complex than Telegram. The gateway architecture supports it, but it requires business-level API access rather than a simple bot token.

**Alternative messaging channels:** Discord (webhook-based), Slack (bot API), and Signal (via signal-cli) are all on the channel connector roadmap and have varying levels of API accessibility.

For updates on channel connector availability, follow the [PUBLISH-PIPELINE.md](../PUBLISH-PIPELINE.md) issue tracker and the project's GitHub releases.

---

## How do I update OpenClaw?

In native Termux (not proot):

```bash
npm update -g openclaw
```

If npm cache issues occur (the proot rename problem does not apply in native Termux, but occasionally npm cache can be stale):

```bash
npm install -g openclaw@latest --prefer-online
```

After updating, restart the gateway:

```bash
# Kill the running process
kill -9 $(pgrep -f openclaw-gateway)

# Start fresh
openclaw gateway run
```

Check the new version:

```bash
openclaw --version
```

**Before updating in production:** Read the OpenClaw changelog for breaking configuration changes. Occasionally model ID formats or config schema changes between releases.

---

## What happens to my conversations if the gateway crashes?

Session state is written to disk in `~/.openclaw/` continuously. If the gateway crashes or is killed by Android, no conversation data is lost. When the gateway restarts, it reads the existing session state from disk and resumes from where it left off.

The conversation history is present in the session file. Any in-flight request (a message you sent that had not yet received a response) will not complete — you would need to resend that message after the gateway restarts. The history before the crash is intact.

**Log files are not session state.** The gateway log (`~/openclaw-gateway.log`) records operational events, not conversation content. Deleting or rotating logs does not affect your conversation history.

---

## Can I run this on a tablet instead of a phone?

Technically yes. The software stack (Termux, proot-distro, Node.js, OpenClaw) does not distinguish between a phone and a tablet. Both run Android. The setup steps in [INSTALL-GUIDE.md](../INSTALL-GUIDE.md) apply identically.

**Why tablets are not recommended for this use case:**

- **No cellular radio** — Most Android tablets do not have LTE/5G. The cellular failover capability is one of the strongest arguments for a phone over a cloud VM. Without cellular, a tablet is just a less capable alternative to a Raspberry Pi.
- **Larger form factor** — Tablets are harder to mount and store as headless servers. Phones fit in a drawer, on a small stand, or in a server rack bracket.
- **Worse battery backup** — Tablets have larger batteries, but they also draw more power. The effective backup time is often similar to a phone.
- **Higher cost per capability** — A tablet costs more than a Pixel 10a while providing fewer relevant capabilities (no cellular, no compact form factor).

If you already have an Android tablet you want to repurpose, it will work. If you are buying specifically for this use case, buy a phone.

---

## Can I run multiple OpenClaw instances on one phone?

You can run multiple instances by configuring them on different ports:

```bash
# First instance
openclaw gateway run --port 18789 &

# Second instance (different port, different config directory)
OPENCLAW_CONFIG_DIR=~/.openclaw2 openclaw gateway run --port 18790 &
```

**Practical considerations:**

- Each instance consumes ~323 MB RSS. Two instances require ~650 MB. On an 8GB phone with ~910 MB available after OS and services, two instances are feasible. Three would be tight.
- Each instance needs its own config directory (session state, API keys, etc.)
- Each instance gets its own port forward in your SSH config
- Both instances compete for the same OpenRouter API rate limits under the same key

The more common multi-instance use case is running a phone gateway alongside a Mac or cloud gateway in a multi-node configuration, rather than two gateways on the same phone. See the Multi-Node Relay section of [docs/use-cases.md](./use-cases.md) for that pattern.

---

## Is my conversation data sent to OpenRouter?

Yes. Every inference request sends the full conversation context to OpenRouter, which routes it to the configured model provider (Anthropic, OpenAI, Google, etc.).

**What specifically is sent:**
- All messages in the current session up to the compaction limit (configurable)
- Any tool results included in the conversation history
- The model selection and any system prompts
- Your OpenRouter API key in the HTTP Authorization header

**What stays on the device:**
- The conversation history stored in `~/.openclaw/` (the local copy)
- API keys (not the API key sent per-request, but the stored key file)
- Gateway configuration
- Tool execution state

**OpenRouter's data retention:** OpenRouter's privacy policy governs how long they retain request data. As of early 2026, they do not use API request data for model training. Verify their current policy at openrouter.ai/privacy.

**For maximum privacy:** Use a model provider with a published no-data-retention policy for API requests. Some Llama deployments via OpenRouter specify no retention. Alternatively, use OpenClaw with a direct provider API key (bypassing OpenRouter) where the provider's policy governs.

See [docs/threat-model.md](./threat-model.md) for the full data flow analysis.

---

## Does this work with OpenAI or other providers directly?

Yes. OpenClaw supports multiple model providers, not just OpenRouter. To use a provider directly:

```bash
# Example: direct Anthropic API
openclaw config set agents.defaults.model.primary "anthropic/claude-3-5-haiku-20241022"
```

And in `~/.openclaw/.env`:

```bash
ANTHROPIC_API_KEY=sk-ant-...
```

**Why OpenRouter is recommended:** A single API key provides access to all providers. Switching models (Anthropic → OpenAI → Google) is a config change, not a credential management change. OpenRouter also provides unified cost visibility across providers.

**When to use direct provider APIs:**
- If you have negotiated pricing with a specific provider
- If you require a specific provider's data processing terms for compliance reasons
- If OpenRouter's pricing for your usage pattern exceeds direct provider pricing
- If you want to eliminate OpenRouter as a visibility layer for your requests

---

## How do I keep the gateway running after a reboot?

Two options, depending on how automated you want the restart to be:

**Option 1: Auto-start on Termux launch (via `.bashrc`)**

Add to `~/.bashrc` in Termux:

```bash
# Auto-start sshd
if ! pgrep -f sshd > /dev/null 2>&1; then
  sshd
fi

# Auto-start OpenClaw gateway
if ! pgrep -f "openclaw-gateway" > /dev/null 2>&1; then
  nohup openclaw gateway run > ~/openclaw-gateway.log 2>&1 &
  sleep 3
fi
```

With this, the gateway starts whenever you open a Termux shell. After a phone reboot, you need to open the Termux app to trigger the `.bashrc` auto-start.

**Option 2: Auto-start on device boot (via Termux:Boot)**

Install Termux:Boot from F-Droid (it is a separate APK from the main Termux app). Then create:

```bash
mkdir -p ~/.termux/boot

cat > ~/.termux/boot/start-openclaw.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock
if ! pgrep -f sshd > /dev/null 2>&1; then
  sshd
fi
nohup openclaw gateway run > ~/openclaw-gateway.log 2>&1 &
EOF

chmod +x ~/.termux/boot/start-openclaw.sh
```

With Termux:Boot installed and this script in place, the gateway starts automatically after every device reboot without any manual intervention.

**Important:** Even with auto-start, you must have previously applied the Android power management mitigations (Doze whitelist, battery unrestricted, wake lock). The auto-start script acquires the wake lock, but the other mitigations are set at the Android system level and persist across reboots once applied.

---

## The first HTTP request to the gateway is slow. Subsequent ones are fast. Why?

This is V8's JIT (Just-In-Time) compiler at work. When the gateway first receives a request, the JavaScript code handling that request is interpreted. The V8 JIT compiler then compiles the hot code paths to native machine code. Subsequent requests use the compiled code and are significantly faster.

The measured cold-start latency is 131ms for the first request. Warm requests drop to 45-52ms average. This is a one-time cost per gateway startup — once the first request has warmed the JIT, all subsequent requests benefit from compiled code.

This is expected behavior for Node.js applications and is not specific to this deployment. If you observe consistently slow requests (not just the first one), check the gateway log for error patterns that might indicate it is failing and falling back to slower code paths.

---

*For installation instructions, see [INSTALL-GUIDE.md](../INSTALL-GUIDE.md).*
*For performance tuning and configuration, see [OPTIMIZATION-GUIDE.md](../OPTIMIZATION-GUIDE.md).*
*For system architecture, see [docs/architecture.md](./architecture.md).*
*For device selection, see [docs/device-strategy.md](./device-strategy.md).*
*For security analysis, see [docs/threat-model.md](./threat-model.md).*
