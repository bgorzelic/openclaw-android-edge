# Reddit Post

> Best subreddits: r/selfhosted, r/homelab, r/AndroidDev, r/termux
> Crosspost to: r/pixel_phones, r/degoogle, r/linux

---

## Title

**I turned a $499 Pixel 10a into an always-on AI edge node with OpenClaw — no root, no bootloader unlock. Full guide with every error I hit.**

---

## Body

I picked up a Pixel 10a (128GB, unlocked) from Best Buy yesterday — day after launch — and spent the evening getting OpenClaw running on it as an always-on edge compute node.

**The goal:** A pocket-sized AI gateway with camera, mic, GPS, and cellular for field deployment (drone operations, specifically).

**The short version:** Termux → proot-distro Ubuntu → Node.js via NodeSource → OpenClaw. About 15 minutes once you know the path. Took me ~2 hours to find it because I hit 8 different errors along the way.

### What worked

- **proot-distro** gives you a full Ubuntu environment inside Termux with no root required. It intercepts syscalls in userspace and translates paths so you get real glibc instead of Android's Bionic. This is the key — without it, any npm package with native modules (like koffi) won't compile.
- **NodeSource** for Node.js 22+ inside the proot Ubuntu — Ubuntu's default repos ship ancient Node.
- **npm cache on /tmp** to avoid proot's broken cross-filesystem rename syscall.
- **5 layers of Android power management** that all need to be disabled independently (Doze, App Standby, Adaptive Battery, CPU Freeze, WiFi Sleep). I documented every ADB command.

### What didn't work

- **Native Termux + Node.js** — installs fine, but koffi's native build system assumes /bin/sh and glibc. Termux uses Bionic libc with paths like `/data/data/com.termux/files/usr/bin/sh`. Even with cmake + make + clang installed, make just dumps its help text instead of building. Dead end.
- **`adb shell device_config put battery_saver`** — requires root, throws SecurityException. Have to set Adaptive Battery to Unrestricted manually in Settings.

### Device specs

| | |
|-|-|
| SoC | Tensor G4 (4x A520 + 3x A725 + 1x X4) |
| RAM | 8GB (~2GB free during install) |
| Storage | 128GB (213GB available after Android) |
| OS | Android 16 |
| Price | $499 |

### Why a phone?

For my use case (AI Aerial Solutions — drone operations), a phone gives you compute + camera + mic + GPS + cellular + battery backup in a single package for $499. No separate modem, no separate GPS module, no separate camera. And Google guarantees 7 years of security updates.

### Full guide

The complete guide is on GitHub with:
- Step-by-step instructions for the working path
- All 8 errors documented with root causes and fixes
- Every ADB optimization command with verification steps
- 860 lines of raw device property dumps
- 6 annotated screenshots from the actual install session
- A TL;DR "happy path" section you can copy-paste in 15 minutes

**[LINK TO GITHUB REPO]**

Happy to answer questions. This was a day-one install on a retail device so the errors are real and reproducible.

---

## Suggested flair

- r/selfhosted: `Guide`
- r/homelab: `Labporn` or `Guide/How-To`
- r/termux: `Discussion`
- r/AndroidDev: `Article`
