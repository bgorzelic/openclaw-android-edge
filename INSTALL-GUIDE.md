# Installing OpenClaw on a Google Pixel 10a (128GB, Unlocked)

> **Author:** Brian Gorzelic / AI Aerial Solutions
> **Date:** March 6, 2026
> **Device:** Google Pixel 10a (128GB, Unlocked, Best Buy)
> **OpenClaw Version:** 2026.3.7
> **Status:** Install guide with full error log documentation

---

## Table of Contents

1. [Device Specifications](#device-specifications)
2. [Prerequisites](#prerequisites)
3. [Phase 1: Enable USB Debugging](#phase-1-enable-usb-debugging)
4. [Phase 2: Install Termux](#phase-2-install-termux)
5. [Phase 3: Android Optimization for Long-Running Processes](#phase-3-android-optimization-for-long-running-processes)
6. [Phase 4: Install Node.js (Termux Native — FAILS)](#phase-4-install-nodejs-termux-native--fails)
7. [Phase 5: proot-distro Ubuntu (Working Path)](#phase-5-proot-distro-ubuntu-working-path)
8. [Phase 6: Install OpenClaw Inside Ubuntu](#phase-6-install-openclaw-inside-ubuntu)
9. [Phase 7: Configure and Run OpenClaw](#phase-7-configure-and-run-openclaw)
10. [Phase 8: SSH Remote Access](#phase-8-ssh-remote-access)
11. [Phase 9: Tailscale Networking](#phase-9-tailscale-networking)
12. [Phase 10: Workflows & Use Cases](#phase-10-workflows--use-cases)
13. [Phase 11: Gateway Optimization](#phase-11-gateway-optimization)
14. [Errors Encountered & Solutions](#errors-encountered--solutions)
14. [Appendix: Raw Device Data](#appendix-raw-device-data)

---

## Device Specifications

| Spec | Value |
|------|-------|
| **Model** | Google Pixel 10a |
| **SKU** | 128GB, Unlocked (Best Buy) |
| **Release Date** | March 5, 2026 |
| **Retail Price** | $499 |
| **SoC** | Google Tensor G4 (Samsung Exynos-based, codename `zumapro`) |
| **CPU** | 4x Cortex-A520 (0xd80) + 3x Cortex-A725 (0xd81) + 1x Cortex-X4 (0xd82) |
| **RAM** | 8GB (7,737,544 kB reported by kernel) |
| **Storage** | 128GB UFS 3.1 (228GB formatted /data, 213GB available at start) |
| **OS** | Android 16 (Build BD6A.251031.001.A4) |
| **Kernel** | Linux 6.1.145-android14-11 (aarch64, SMP PREEMPT) |
| **ABI** | arm64-v8a |
| **Security Patch** | 2025-12-05 |
| **Display** | 6.3" FHD+ (2424x1080), 120Hz |
| **Battery** | 5,100 mAh Li-ion |
| **Colors Available** | Fog, Obsidian, Berry, Lavender |

### Why the Pixel 10a for an Edge Node?

- 8GB RAM is more than enough for Node.js + OpenClaw (measured ~2GB available during install)
- Tensor G4 has 8 cores with big.LITTLE architecture — efficient for always-on workloads
- 7 years of guaranteed OS + security updates from Google
- $499 is the cheapest way to get a 2026-spec ARM64 Linux-capable device with camera, mic, GPS, and cellular
- USB-C Power Delivery means you can keep it plugged in 24/7 as a headless node

---

## Prerequisites

### On your Mac (or PC)

- **ADB (Android Debug Bridge)** installed
  - macOS: `brew install android-platform-tools`
  - Linux: `sudo apt install adb`
  - Windows: Download from Android SDK Platform Tools
- USB-C cable (data-capable, not charge-only)

### On the Pixel 10a

- Completed initial Android setup (Google account, WiFi, etc.)
- Developer Options enabled:
  1. Go to **Settings > About phone**
  2. Tap **Build number** 7 times
  3. Go back to **Settings > System > Developer options**
  4. Enable **USB debugging**

---

## Phase 1: Enable USB Debugging

1. Connect Pixel 10a to Mac via USB-C
2. On the Mac, verify connection:

```bash
adb devices
```

**Expected output:**
```
* daemon not running; starting now at tcp:5037
* daemon started successfully
List of devices attached
XXXXXXXXXXXX	unauthorized
```

3. On the phone, tap **"Allow USB debugging"** when prompted
4. Verify authorization:

```bash
adb devices
```

**Expected output:**
```
List of devices attached
XXXXXXXXXXXX	device
```

> **Note:** If you don't see the prompt on the phone, unplug and replug the USB cable. Make sure USB debugging is enabled in Developer Options.

---

## Phase 2: Install Termux

**Do NOT install Termux from the Google Play Store** — the Play Store version is outdated and unmaintained.

### Download from GitHub Releases

```bash
# Find the latest arm64 APK URL
curl -sL https://api.github.com/repos/termux/termux-app/releases/latest | \
  python3 -c "import sys,json; r=json.load(sys.stdin); \
  [print(a['browser_download_url']) for a in r['assets'] \
  if 'arm64' in a['name'] and a['name'].endswith('.apk')]"
```

**Output (as of March 2026):**
```
https://github.com/termux/termux-app/releases/download/v0.118.3/termux-app_v0.118.3+github-debug_arm64-v8a.apk
```

### Install via ADB

```bash
# Download
curl -L -o /tmp/termux.apk \
  "https://github.com/termux/termux-app/releases/download/v0.118.3/termux-app_v0.118.3%2Bgithub-debug_arm64-v8a.apk"

# Install
adb install /tmp/termux.apk
```

**Expected output:**
```
Performing Streamed Install
Success
```

### Launch Termux

```bash
adb shell am start -n com.termux/.HomeActivity
```

You should see the Termux welcome screen on the phone:

```
Welcome to Termux!

Docs:       https://termux.dev/docs
Donate:     https://termux.dev/donate
Community:  https://termux.dev/community

Working with packages:
 - Search:  pkg search <query>
 - Install: pkg install <package>
 - Upgrade: pkg upgrade

~ $
```

> **Screenshot:** See `screenshots/01-termux-welcome.png`

---

## Phase 3: Android Optimization for Long-Running Processes

Android aggressively kills background processes to save battery. For OpenClaw to run reliably, you need to disable multiple layers of power management.

### Via ADB (run from your Mac)

```bash
# 1. Whitelist Termux from Doze battery optimization
adb shell dumpsys deviceidle whitelist +com.termux
# Expected: "Added: com.termux"

# 2. Allow unrestricted background execution
adb shell cmd appops set com.termux RUN_IN_BACKGROUND allow
adb shell cmd appops set com.termux RUN_ANY_IN_BACKGROUND allow

# 3. Keep screen on while USB connected
adb shell svc power stayon usb

# 4. Set screen timeout to 30 minutes (1800000ms)
adb shell settings put system screen_off_timeout 1800000

# 5. Keep WiFi alive during sleep
adb shell settings put global wifi_sleep_policy 2
```

### Verification

```bash
# Verify Doze whitelist
adb shell dumpsys deviceidle whitelist | grep termux
# Expected: "user,com.termux,XXXXX"  (your UID number)

# Verify background permissions
adb shell cmd appops get com.termux RUN_IN_BACKGROUND
# Expected: "RUN_IN_BACKGROUND: allow"

adb shell cmd appops get com.termux RUN_ANY_IN_BACKGROUND
# Expected: "RUN_ANY_IN_BACKGROUND: allow"

# Verify screen timeout
adb shell settings get system screen_off_timeout
# Expected: "1800000"

# Verify WiFi sleep policy
adb shell settings get global wifi_sleep_policy
# Expected: "2"
```

### Manual Steps (on the phone)

1. **Acquire Termux Wake Lock:**
   - Pull down notification shade
   - Find the Termux notification
   - Tap it and select **"Acquire wakelock"**
   - This holds a `PARTIAL_WAKE_LOCK` at the kernel level, preventing CPU freeze when screen is off

2. **Set Battery to Unrestricted:**
   - Go to **Settings > Apps > Termux > Battery**
   - Select **"Unrestricted"**
   - This fully disables Adaptive Battery throttling for Termux

### What failed (requires root)

```bash
# This DOES NOT WORK without root:
adb shell device_config put battery_saver lazy_mode_enabled false
# Result: SecurityException - permission denied
```

### Why all these layers?

Android's power management is a multi-layered system:

| Layer | What it does | Our fix |
|-------|-------------|---------|
| **Doze** | Defers network, jobs, alarms when screen off | `deviceidle whitelist` |
| **App Standby** | Restricts apps not recently used | `RUN_IN_BACKGROUND allow` |
| **Adaptive Battery** | ML-based prediction kills "unused" apps | Unrestricted battery setting |
| **CPU Freeze** | Kernel suspends CPU to save power | Termux Wake Lock |
| **WiFi Sleep** | Disconnects WiFi when screen off | `wifi_sleep_policy 2` |

All five layers must be addressed for reliable 24/7 operation.

---

## Phase 4: Install Node.js (Termux Native — FAILS)

> **This section documents the FAILED native Termux approach.** Skip to Phase 5 for the working path. Included for completeness and to help others avoid these pitfalls.

### Install Node.js LTS

On the phone in Termux:

```bash
pkg update -y && pkg install -y nodejs-lts
```

**Result:** Success. Installed Node.js 24.13.0 (LTS) and npm 11.11.0.

### Attempt 1: npm install -g openclaw

```bash
npm install -g openclaw
```

**Result: FAILED** — missing `git`

```
npm error code ENOENT
npm error syscall spawn git
npm error path git
npm error errno -2
npm error enoent An unknown git error occurred
```

> **Screenshot:** See `screenshots/02-npm-git-error.png`

**Fix:** Install git: `pkg install -y git`

### Attempt 2: npm install -g openclaw (with git)

```bash
pkg install -y git && npm install -g openclaw
```

**Result: FAILED** — `koffi` native module build fails, missing CMake

```
npm error Error: CMake does not seem to be available
npm error   at check_cmake (.../koffi/src/cnoke/src/builder.js:368:27)
npm error   at Builder.build (.../koffi/src/cnoke/src/builder.js:228:9)
```

> **Screenshot:** See `screenshots/03-koffi-cmake-error.png`

**Explanation:** `koffi` is an FFI (Foreign Function Interface) library that OpenClaw uses to call native C libraries. No prebuilt binary exists for Termux's Android environment, so it must compile from source.

### Attempt 3: Install build tools + retry

```bash
pkg install -y cmake make clang && npm install -g openclaw
```

**Result: FAILED** — `make` invocation broken on Termux

```
npm error This program built for aarch64-unknown-linux-android
npm error Report bugs to <bug-make@gnu.org>
npm error Error: Failed to run build step
npm error   at Builder.build (.../koffi/src/cnoke/src/builder.js:251:19)
```

> **Screenshot:** See `screenshots/04-koffi-make-error.png`

**Explanation:** Termux's `make` has hardcoded paths that differ from what `koffi`'s build system expects. The build system invokes `make` with flags that assume a standard GNU/Linux environment, but Termux uses Android's Bionic libc instead of glibc. The `make` command dumps its help text instead of building, indicating the command-line arguments are being parsed incorrectly.

### Why Native Termux Fails for koffi

The root cause is a mismatch between koffi's build expectations and Termux's environment:

1. **Bionic vs glibc** — Termux uses Android's Bionic libc, not GNU glibc
2. **Hardcoded paths** — Termux's `make`/`cmake` have paths like `/data/data/com.termux/files/usr/bin/sh` where koffi expects `/bin/sh`
3. **No prebuilt binaries** — koffi doesn't publish prebuilt `.node` files for `aarch64-unknown-linux-android`
4. **Syscall limitations** — Some build steps use syscalls not fully supported in Termux's environment

**Potential native fix (not tested):**
```bash
pkg install -y lld
CC=clang CXX=clang++ LDFLAGS="-fuse-ld=lld" npm install -g openclaw
```

**Recommended approach:** Use proot-distro (Phase 5).

---

## Phase 5: proot-distro Ubuntu (Working Path)

### What is proot-distro?

`proot-distro` runs a full Linux distribution (Ubuntu) inside Termux using `proot` — a user-space `chroot` implementation that requires NO root access. It intercepts syscalls via `ptrace` and translates file paths, giving you a standard glibc-based Ubuntu environment where native builds work normally.

**Tradeoffs:**
- ~500MB disk space for Ubuntu rootfs (negligible on 128GB)
- Slight performance overhead from syscall interception
- Full compatibility with standard Linux packages and build tools

### Install Ubuntu via proot-distro

On the phone in Termux:

```bash
pkg install -y proot-distro && proot-distro install ubuntu
```

**This takes 3-5 minutes** (downloads ~400MB Ubuntu rootfs).

**Expected final output:**
```
Generating locales (this might take a while)...
  en_US.UTF-8... done
Generation complete.
...
[*] Finished.

Log in with: proot-distro login ubuntu
```

> **Screenshot:** See `screenshots/05-proot-ubuntu-installed.png`

> **Note:** You may see a warning: "CPU doesn't support 32-bit instructions, some software may not work." This is harmless — the Pixel 10a's Tensor G4 is a pure 64-bit chip, and all the software we need is 64-bit.

### Login to Ubuntu

```bash
proot-distro login ubuntu
```

Your prompt changes to `root@localhost:~#` — you're now inside Ubuntu.

---

## Phase 6: Install OpenClaw Inside Ubuntu

### Install Node.js 22+ via NodeSource

Ubuntu's default repos ship old Node.js. OpenClaw requires Node.js >= 22.12.

```bash
apt update && apt install -y curl
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs
node --version
```

**Expected:** `v22.x.x` (must be >= 22.12)

### Install OpenClaw

```bash
npm install -g openclaw
```

#### If you get ENOENT rename errors:

> **Screenshot:** See `screenshots/06-npm-rename-error.png`

This is a known proot issue — the `rename` syscall doesn't translate properly across filesystems in proot's syscall interception layer. npm tries to atomically rename files from a temp directory into the cache, and proot can't emulate that.

**Fix:** Use `/tmp` for npm cache (same filesystem avoids cross-fs rename):

```bash
npm config set cache /tmp/npm-cache
npm install -g openclaw
```

**Alternative:**
```bash
npm install -g --cache /tmp/npm-cache --prefer-online openclaw
```

### Verify Installation

```bash
openclaw --version
```

**Expected:** `2026.3.2` (or latest)

---

## Phase 7: Configure and Run OpenClaw

### Start OpenClaw

```bash
openclaw
```

This launches the OpenClaw gateway with a web dashboard. Follow the on-screen prompts to:

1. Set your API key (Anthropic, OpenAI, etc.)
2. Configure channels (WhatsApp, Telegram, Slack, etc.)
3. Access the web dashboard at the displayed URL

### Run in tmux for Persistence

To keep OpenClaw running after you close Termux or the screen turns off:

```bash
# Install tmux inside Ubuntu proot
apt install -y tmux

# Create a named session
tmux new -s openclaw

# Inside tmux, start OpenClaw
openclaw

# Detach: press Ctrl+B, then D
# Reattach later: tmux attach -t openclaw
```

### Quick-Start Script

Create a startup script for easy re-launching:

```bash
cat > /root/start-openclaw.sh << 'EOF'
#!/bin/bash
echo "Starting OpenClaw on Pixel 10a..."
echo "Device: $(uname -m) | Node: $(node --version) | OpenClaw: $(openclaw --version 2>/dev/null)"
echo "Press Ctrl+C to stop"
openclaw
EOF
chmod +x /root/start-openclaw.sh
```

Then from Termux:
```bash
proot-distro login ubuntu -- bash /root/start-openclaw.sh
```

### Auto-Start on Boot (Optional)

Install Termux:Boot from F-Droid, then create:

```bash
mkdir -p ~/.termux/boot
cat > ~/.termux/boot/start-openclaw.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock
proot-distro login ubuntu -- tmux new -d -s openclaw 'openclaw'
EOF
chmod +x ~/.termux/boot/start-openclaw.sh
```

---

## Phase 8: SSH Remote Access

Once OpenClaw is running on the Pixel 10a, you'll want to manage it remotely from your Mac (or any machine) without physically touching the phone. Termux ships with OpenSSH.

### Install and Configure SSH in Termux

On the phone in Termux (outside proot):

```bash
pkg install -y openssh

# Set a password for SSH login
passwd
# Enter your password when prompted

# Start the SSH daemon
sshd
```

Termux's SSH server runs on **port 8022** (not 22 — Termux doesn't have root access to bind privileged ports).

### Find the Phone's IP Address

```bash
# In Termux
ifconfig wlan0 | grep 'inet '
# Example output: inet 192.168.1.42  netmask 255.255.255.0
```

### Connect from Your Mac

```bash
ssh -p 8022 u0_aXXX@<phone-ip>
```

> **Note:** Replace `u0_aXXX` with your actual Android user ID. Run `whoami` in Termux to find yours — it's typically `u0_a` followed by a number (e.g., `u0_a314`, `u0_a256`).

### Set Up Key-Based Auth (Recommended)

Password auth works but key-based auth is more reliable, especially from automated tools and non-TTY environments like Claude Code.

**On your Mac:**

```bash
# Copy your public key to the phone
ssh-copy-id -p 8022 u0_aXXX@<phone-ip>
```

Or manually — on the phone in Termux:

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo '<your-public-key-here>' >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Get your Mac's public key with `cat ~/.ssh/id_ed25519.pub` (or whichever key you use).

### SSH Config (Mac Side)

Add this to `~/.ssh/config` on your Mac for easy access:

```
Host termux
    HostName <phone-ip>
    Port 8022
    User u0_aXXX
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
    UseKeychain yes
    IdentitiesOnly yes
```

Now you can connect with just:

```bash
ssh termux
```

### Auto-Start SSH on Termux Boot

If you installed Termux:Boot (from Phase 7's auto-start section):

```bash
cat > ~/.termux/boot/start-sshd.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock
sshd
EOF
chmod +x ~/.termux/boot/start-sshd.sh
```

### Access proot Ubuntu via SSH

Once SSH'd into Termux, enter the Ubuntu environment:

```bash
proot-distro login ubuntu
```

Then you have full access to OpenClaw:

```bash
openclaw status --deep
openclaw health
tmux attach -t openclaw
```

### Troubleshooting SSH

| Problem | Cause | Fix |
|---------|-------|-----|
| `Too many authentication failures` | SSH tries all your keys before password | Use `IdentitiesOnly yes` in SSH config |
| Key passphrase prompt every time | Key not in macOS Keychain | `ssh-add --apple-use-keychain ~/.ssh/id_ed25519` |
| `Connection refused` | sshd not running on phone | Run `sshd` in Termux |
| `Permission denied` after key setup | Wrong permissions on authorized_keys | `chmod 600 ~/.ssh/authorized_keys` on phone |
| Can't connect after WiFi change | Phone got a new IP | Use Tailscale (Phase 9) for stable IP |

---

## Phase 9: Tailscale Networking

SSH over WiFi works on a local network, but the phone's IP changes when it moves between networks. **Tailscale** gives every device a stable IP on your private tailnet — accessible from anywhere, encrypted, no port forwarding needed.

### Install Tailscale on the Pixel 10a

1. Install Tailscale from the **Google Play Store** on the phone
2. Open Tailscale and sign in with your account
3. The phone gets a stable Tailscale IP (e.g., `100.x.y.z`)

### Update Your SSH Config

Replace the local IP with the Tailscale IP in `~/.ssh/config`:

```
Host termux
    HostName 100.x.y.z    # Tailscale IP — never changes
    Port 8022
    User u0_aXXX
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
    UseKeychain yes
    IdentitiesOnly yes
```

Now `ssh termux` works from anywhere — home, office, coffee shop, cellular — as long as both devices are on your tailnet.

### OpenClaw Gateway Access via Tailscale

With both your Mac and phone on the same tailnet, you have three options for accessing the OpenClaw gateway running on the phone:

#### Option A: SSH Tunnel (Simplest)

Forward the gateway port over SSH:

```bash
ssh -N -L 18789:127.0.0.1:18789 termux &
```

Then access the Control UI at `http://127.0.0.1:18789/` on your Mac.

#### Option B: Tailscale Serve (Recommended for Always-On)

Inside proot Ubuntu on the phone, configure OpenClaw to use Tailscale Serve:

```bash
openclaw config set gateway.tailscale.mode serve
openclaw config set gateway.bind loopback
```

The Control UI is then available at `https://<phone-magicdns>/` from any device on your tailnet.

#### Option C: Bind to Tailnet IP (Direct)

```bash
openclaw config set gateway.bind tailnet
openclaw config set gateway.auth.mode token
openclaw config set gateway.auth.token "your-secret-token"
```

Access directly at `http://100.x.y.z:18789/` from any tailnet device.

### Connect the OpenClaw Mac App to the Phone Gateway

If your Mac runs the OpenClaw macOS app, you can point it at the phone's gateway:

1. Open OpenClaw macOS app → Settings → General
2. Set "OpenClaw runs on" → **Remote over SSH**
3. Enter the SSH details (host: Tailscale IP, port: 8022, user: u0_aXXX)
4. The app manages the SSH tunnel automatically

### Tailscale Tips for Always-On Operation

| Setting | Where | Purpose |
|---------|-------|---------|
| **Always-on VPN** | Android Settings → Network → VPN → Tailscale → Always-on | Keeps Tailscale connected even after reboot |
| **Battery: Unrestricted** | Settings → Apps → Tailscale → Battery → Unrestricted | Prevents Android from killing the Tailscale daemon |
| **MagicDNS** | Tailscale admin console → DNS | Enables `<hostname>.tailnet-name.ts.net` names |

### Verification

From your Mac:

```bash
# Ping the phone via tailnet
ping 100.x.y.z

# SSH into Termux
ssh termux

# Check OpenClaw gateway from inside
proot-distro login ubuntu -- openclaw health
```

---

## Phase 10: Workflows & Use Cases

With OpenClaw running on a Pixel 10a with SSH and Tailscale, you have a portable, always-on AI edge node. Here are practical workflows.

### Mobile Command Center

Send tasks from any device via your messaging channels — the phone executes them:

```bash
# From Telegram, WhatsApp, Discord, Signal, Slack, etc:
"Summarize my unread emails"
"What meetings do I have tomorrow?"
"Draft a response to the last Slack message from Sarah"
```

The phone's gateway processes the request, calls tools, and replies on the same channel. You never touch the phone.

### Remote DevOps

Manage servers and infrastructure from a chat message:

```bash
# Via Telegram:
"Check if the staging server is healthy"
"Show me the last 50 lines of the production error log"
"Restart the API service on staging"
```

OpenClaw uses SSH tools and CLI skills to execute on remote hosts and return results to your phone.

### Scheduled Automation (Cron Jobs)

Set up recurring tasks that run automatically:

```bash
# Inside proot Ubuntu:
openclaw cron add --every "8:00 AM" --message "Give me a morning briefing: weather, calendar, top news, and pending tasks"
openclaw cron add --every "6:00 PM" --message "Summarize what happened today across all my channels"
openclaw cron add --every "Friday 5:00 PM" --message "Generate a weekly status report from my git commits and Slack activity"
```

### Field Photography + AI Analysis

The Pixel 10a's camera is accessible via the OpenClaw Android app:

- **Site Inspections** — photograph equipment, structures, or terrain; the agent analyzes and reports
- **Document Scanning** — snap a photo of a whiteboard, receipt, or document; get structured data back
- **Drone Integration** — pair with a drone controller app; use the phone as a vision + compute node

### Browser Automation

Automate web tasks via Playwright running headless on the gateway host:

```bash
# Via any channel:
"Book the 7pm padel court at the usual place"
"Order the weekly grocery list from Tesco"
"Check my bank balance and flag anything unusual"
```

### Portable Gateway for Travel

The phone replaces a laptop for AI assistant access while traveling:

- All channels work over cellular — no WiFi required
- Tailscale keeps your tailnet connected
- Battery lasts all day; USB-C PD keeps it charged indefinitely
- Fits in your pocket — 24/7 AI gateway wherever you go

### Multi-Node Architecture

Run the phone as a secondary node alongside your main Mac or VPS gateway:

```bash
# Phone provides: camera, GPS, microphone, cellular failover
# Mac/VPS provides: compute, storage, browser automation, always-on power
```

The gateway on one machine can call tools on the other via the OpenClaw WebSocket protocol.

### Webhook Receiver

Use the phone as a webhook endpoint for real-time event processing:

```bash
openclaw config set gateway.tailscale.mode funnel
openclaw config set gateway.auth.mode password
openclaw config set gateway.auth.password "your-webhook-secret"
```

Now external services (GitHub, Stripe, monitoring alerts) can POST to your phone's public HTTPS endpoint, and OpenClaw processes them.

### Memory & Knowledge Management

Build a personal knowledge base that grows over time:

```bash
# Via WhatsApp:
"Remember that the Q2 budget is $45k and Sarah approved it on March 3"
"What did I decide about the database migration last week?"
"Search my notes for anything about the client demo"
```

OpenClaw's 7-layer memory architecture (from Issue #1) persists across sessions — the phone never forgets.

### Home Automation Hub

Control IoT devices via natural language from any channel:

```bash
# Via Telegram:
"Turn off all the lights downstairs"
"Set the thermostat to 72"
"Start the robot vacuum in the kitchen"
"Is the garage door open?"
```

Requires Home Assistant integration or direct API skills for your devices.

---

## Phase 11: Gateway Optimization

The gateway works out of the box, but several optimizations make it reliable for always-on operation on budget hardware. See **[OPTIMIZATION-GUIDE.md](OPTIMIZATION-GUIDE.md)** for the full deep-dive with cost analysis and real-world use cases.

### Quick Optimization Checklist

1. **Run in native Termux** (not proot-distro) — proot blocks `os.networkInterfaces()`
2. **Use OpenRouter model prefix** — `openrouter/anthropic/claude-3.5-haiku` not `anthropic/...`
3. **Disable mDNS** — `openclaw config set discovery.mdns.mode off`
4. **Disable auth** (loopback-only) — `openclaw config set gateway.auth.mode none`
5. **Cap Node.js memory** — `export NODE_OPTIONS="--max-old-space-size=384"`
6. **Exempt Termux from battery optimization** — Settings > Apps > Termux > Battery > Unrestricted
7. **Acquire Termux wake lock** — prevents Android from killing the process
8. **Auto-start on shell login** — add gateway start to `~/.bashrc`
9. **Put API key in `~/.openclaw/.env`** — persists across sessions without shell export

### Optimized `.bashrc`

```bash
# Environment
export OPENROUTER_API_KEY="sk-or-v1-your-key-here"
export OPENCLAW_DISABLE_BONJOUR=1
export NODE_OPTIONS="--max-old-space-size=384"

# Auto-start sshd
if ! pgrep -f sshd > /dev/null 2>&1; then
  sshd
  echo "[sshd] Started on port 8022"
fi

# Auto-start OpenClaw gateway
if ! pgrep -f "openclaw-gateway" > /dev/null 2>&1; then
  echo "[openclaw] Starting gateway..."
  nohup openclaw gateway run > ~/openclaw-gateway.log 2>&1 &
  sleep 3
  if pgrep -f "openclaw-gateway" > /dev/null 2>&1; then
    echo "[openclaw] Gateway running (PID $(pgrep -f openclaw-gateway))"
  else
    echo "[openclaw] Failed — check ~/openclaw-gateway.log"
  fi
fi
```

---

## Phase 12: Developer Environment

The Pixel 10a can run a full development environment including Claude Code (AI coding agent) directly on the device.

### Install Dev Tools

```bash
# In native Termux (not proot)
pkg install -y python tmux jq sqlite
```

### Install Claude Code

```bash
npm install -g @anthropic-ai/claude-code
```

Claude Code requires authentication. Run `claude` on the phone's screen (not over SSH) and follow the OAuth flow to sign in.

### The /tmp Sandbox Fix

Claude Code creates its sandbox in `/tmp/claude-<uid>/`, but Termux's `/tmp` is owned by Android's `shell` user and isn't writable. The fix is a lightweight `proot` wrapper that remaps Termux's writable tmp directory:

```bash
# Create the wrapper (one-time setup)
cat > $PREFIX/bin/claude-dev << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Claude Code wrapper for Termux — fixes /tmp sandbox issue
exec proot -b $PREFIX/tmp:/tmp claude "$@"
EOF
chmod +x $PREFIX/bin/claude-dev
```

Now use `claude-dev` instead of `claude`:

```bash
# Interactive session
claude-dev

# Non-interactive (from scripts or SSH)
echo "your prompt" | claude-dev --print --dangerously-skip-permissions
```

### Sensor Access Note

Termux:API commands (`termux-camera-photo`, `termux-location`, `termux-wifi-scaninfo`, etc.) require Android foreground context. They work from the phone's Termux session but **hang when called over SSH**. For sensor-heavy development:

- Use the phone's screen directly, or
- Trigger sensor commands via OpenClaw (which has foreground context), or
- Queue sensor tasks and process results asynchronously

### Dev Environment Summary

| Tool | Version | Purpose |
|------|---------|---------|
| Node.js | v25.3.0 | OpenClaw runtime, skill dev |
| Python | 3.13.12 | App development, sensors |
| Claude Code | 2.1.71 | AI coding agent on device |
| git + gh | 2.53.0 / 2.87.3 | Version control, GitHub |
| tmux | 3.6a | Persistent dev sessions |
| jq | 1.8.1 | JSON processing |
| sqlite3 | 3.52.0 | Data persistence |
| Termux:API | 0.59.1 | 80+ Android sensor commands |

---

## Errors Encountered & Solutions

| # | Error | Root Cause | Solution |
|---|-------|-----------|----------|
| 1 | `adb devices` shows `unauthorized` | USB debugging not approved on phone | Tap "Allow USB debugging" on phone |
| 2 | `npm error syscall spawn git` | git not installed in Termux | `pkg install -y git` |
| 3 | `CMake does not seem to be available` | koffi needs build tools to compile from source | `pkg install -y cmake make clang` |
| 4 | `Failed to run build step` (make dumps help) | Termux make/cmake incompatible with koffi's build system | Use proot-distro Ubuntu instead |
| 5 | `ENOENT: rename` in npm cache | proot can't emulate cross-filesystem rename syscall | `npm config set cache /tmp/npm-cache` |
| 6 | `requires nodejs v22.12+` | Ubuntu default repos have old Node.js | Install via NodeSource `setup_22.x` |
| 7 | `device_config put` SecurityException | Adaptive battery config requires root | Set manually: Settings > Apps > Termux > Battery > Unrestricted |
| 8 | Phone screen goes black during install | Screen timeout too short | `adb shell svc power stayon usb` + 30min timeout |
| 9 | Claude Code `/tmp` sandbox fails | Termux `/tmp` owned by shell:shell, not writable by app | Use `claude-dev` wrapper: `proot -b $PREFIX/tmp:/tmp claude` |

---

## Appendix: Raw Device Data

### Full Device Properties

See `logs/device-properties.txt` (860 lines of `adb shell getprop` output).

### Key System Info

```
Model:           Pixel 10a
Android:         16
Build:           BD6A.251031.001.A4
Chipset:         zumapro (Tensor G4)
ABI:             arm64-v8a
Kernel:          Linux 6.1.145-android14-11 (aarch64, SMP PREEMPT)
Security Patch:  2025-12-05
RAM:             7,737,544 kB (~7.4 GB)
Storage Total:   228 GB
Storage Used:    16 GB (7%)
Storage Free:    213 GB
Battery:         5,100 mAh Li-ion
Battery Status:  100%, charging via AC
Temperature:     29.9°C
```

### CPU Core Layout (Tensor G4)

```
Core 0-3: Cortex-A520 (0xd80) — Efficiency cores
Core 4-6: Cortex-A725 (0xd81) — Performance cores
Core 7:   Cortex-X4  (0xd82) — Prime core
```

### Software Versions

```
Termux:          0.118.3 (GitHub release, installed 2026-03-06 16:42:05)
proot-distro:    Ubuntu (installed via pkg)
Node.js:         25.3.0 (native Termux, via NodeSource)
npm:             11.11.0
OpenClaw:        2026.3.7 (upgraded from 2026.3.2)
Python:          3.13.12 (native Termux)
Claude Code:     2.1.71 (via npm, uses claude-dev wrapper)
```

### ADB Optimization Commands (Copy-Paste Ready)

```bash
# Run all of these from your Mac/PC
adb shell dumpsys deviceidle whitelist +com.termux
adb shell cmd appops set com.termux RUN_IN_BACKGROUND allow
adb shell cmd appops set com.termux RUN_ANY_IN_BACKGROUND allow
adb shell svc power stayon usb
adb shell settings put system screen_off_timeout 1800000
adb shell settings put global wifi_sleep_policy 2
```

### File Structure

```
openclaw-pixel10a-guide/
├── INSTALL-GUIDE.md          # This file
├── logs/
│   ├── device-properties.txt  # Full adb shell getprop dump (860 lines)
│   ├── device-summary.txt     # Parsed device info, battery, storage, CPU
│   ├── adb-optimization-commands.txt  # All ADB commands with results
│   ├── npm-log-paths.txt      # Paths to npm debug logs on device
│   ├── termux-npm-debug.log   # npm debug logs (if retrieved)
│   └── termux-packages.txt    # Termux package info
└── screenshots/
    ├── 01-termux-welcome.png       # Fresh Termux install
    ├── 02-npm-git-error.png        # ENOENT spawn git
    ├── 03-koffi-cmake-error.png    # CMake not found
    ├── 04-koffi-make-error.png     # make build failure
    ├── 05-proot-ubuntu-installed.png # Ubuntu proot success
    └── 06-npm-rename-error.png     # npm cache rename error
```

---

## TL;DR — The Happy Path

If you just want the working commands without the troubleshooting journey:

```bash
# On your Mac — install Termux
adb install termux-v0.118.3-arm64.apk

# On your Mac — optimize Android
adb shell dumpsys deviceidle whitelist +com.termux
adb shell cmd appops set com.termux RUN_IN_BACKGROUND allow
adb shell cmd appops set com.termux RUN_ANY_IN_BACKGROUND allow
adb shell svc power stayon usb
adb shell settings put system screen_off_timeout 1800000
adb shell settings put global wifi_sleep_policy 2

# On the phone — in Termux
pkg update -y
pkg install -y proot-distro openssh
proot-distro install ubuntu

# Set up SSH (still in Termux, outside proot)
passwd                    # set a password
sshd                      # starts on port 8022

# Install Tailscale from Play Store on the phone
# Sign in → note the 100.x.y.z IP

# On your Mac — set up SSH key auth
ssh-copy-id -p 8022 u0_aXXX@100.x.y.z

# On your Mac — add to ~/.ssh/config
# Host termux
#     HostName 100.x.y.z
#     Port 8022
#     User u0_aXXX
#     IdentityFile ~/.ssh/id_ed25519
#     IdentitiesOnly yes
#     AddKeysToAgent yes
#     UseKeychain yes

# Now SSH in and set up OpenClaw
ssh termux
proot-distro login ubuntu

# Inside Ubuntu (proot)
apt update && apt install -y curl
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs
npm config set cache /tmp/npm-cache
npm install -g openclaw
openclaw --version

# On the phone manually:
# 1. Termux notification > Acquire wakelock
# 2. Settings > Apps > Termux > Battery > Unrestricted
# 3. Settings > Network > VPN > Tailscale > Always-on VPN
# 4. Settings > Apps > Tailscale > Battery > Unrestricted
```

Total time: ~20 minutes on WiFi.

---

*Guide produced from a live install session on March 6, 2026. All errors, screenshots, and logs are from the actual first-boot experience on a retail Pixel 10a purchased at Best Buy.*
