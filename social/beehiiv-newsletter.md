# Beehiiv Newsletter

> Subject line options (pick one):
> - "I turned a $499 phone into an AI edge node. Here's every error I hit."
> - "Pixel 10a + OpenClaw: The $499 always-on AI node (full build log)"
> - "Day-one Pixel 10a → OpenClaw edge node. 8 errors, 8 fixes, 15 minutes."

> Preview text: "No root. No bootloader unlock. Termux + proot Ubuntu + a lot of patience with Android's power management."

---

Hey —

I bought a Google Pixel 10a yesterday — the day after launch, $499 at Best Buy — and spent the evening turning it into an always-on AI edge node running OpenClaw.

No root access. No bootloader unlock. Just software.

This is the full build log: what worked, what didn't, and why phones might be the most underrated compute platform for edge AI.

## Why a phone?

I run AI Aerial Solutions. We do drone operations. For field deployment, I need a compute node with camera, microphone, GPS, and cellular connectivity. You can buy all of those as separate modules and wire them to a Raspberry Pi... or you can buy a phone.

The Pixel 10a has a Tensor G4 chip (8 cores, ARM64), 8GB RAM, 128GB storage, and 7 years of guaranteed security updates. It costs $499 and fits in your pocket. For an always-on node that needs sensors, it's the best dollar-per-capability device on the market right now.

## The install journey

The target was simple: get OpenClaw running so I can use the phone as an AI gateway — routing requests to Claude, GPT, local models, whatever — with persistent uptime.

### Android doesn't want you to do this

The first surprise was how aggressively Android fights background processes. There are five separate power management layers, and you have to defeat all of them:

**Doze** puts the phone in deep sleep when the screen is off. **App Standby** throttles apps it thinks you're not using. **Adaptive Battery** uses ML to predict which apps to kill. **CPU Freeze** suspends the processor entirely. **WiFi Sleep** disconnects your network.

Each one has a different fix — ADB commands, manual settings toggles, Termux wake locks. I documented all of them with verification commands so you can confirm each layer is actually disabled.

### Termux is the gateway, but not the destination

Termux is incredible — it gives you a real Linux terminal on Android without root. But it has a fundamental limitation: it uses Android's Bionic libc instead of GNU glibc. That means any npm package with native C modules (like koffi, which OpenClaw depends on) won't compile.

I tried three times with increasing levels of build tools (git, then cmake, then make + clang). Each time it failed differently. The final failure was surreal — running `make` just printed its help text instead of building anything, because Termux's make binary parses command-line arguments differently than GNU make.

### proot-distro is the answer

The solution is proot-distro, which runs a full Ubuntu installation inside Termux via userspace syscall interception. No root needed. It intercepts system calls via `ptrace` and translates file paths, giving you real glibc and a standard Linux environment.

Three commands:

```
pkg install -y proot-distro
proot-distro install ubuntu
proot-distro login ubuntu
```

Inside that Ubuntu shell, everything works normally. Install Node.js from NodeSource, install OpenClaw with npm, done.

Well, almost done. There's one more gotcha: npm's cache tries to atomically rename files across filesystem boundaries, and proot's syscall interception can't handle that. The fix is setting npm's cache to `/tmp` so everything stays on the same filesystem.

### The result

OpenClaw running on a Pixel 10a. About 15 minutes if you follow the happy path. Took me about 2 hours to find that path.

## The full guide

I wrote everything up as a proper reference document — 645 lines covering every phase, every error, every fix. It includes:

- Complete device specs and Tensor G4 core layout
- All 8 errors with root cause analysis and solutions
- Every ADB optimization command with expected output
- 6 annotated screenshots from the actual install
- 860 lines of raw device property dumps
- A copy-paste "happy path" you can run in 15 minutes

It's on GitHub: **[LINK TO REPO]**

## What's next

This is the first node. The plan is a fleet of these — phones as edge compute for drone swarms, each running OpenClaw as a local AI gateway with failover to cloud when cellular is available.

Next up: benchmarking inference performance on the Tensor G4, testing cellular failover, and figuring out headless camera access for CV workloads.

If you're doing anything with edge AI, phones as compute, or just like watching someone fight with Android's power management for two hours — the guide is worth a read.

— Brian

*AI Aerial Solutions / @spookyjuiceai*

---

> **Footer CTA:** If this was useful, forward it to someone building edge AI. And if you want the raw device dumps and screenshots, they're all in the GitHub repo.

---
