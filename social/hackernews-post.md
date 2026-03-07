# Hacker News Submission

---

## Title (max 80 chars)

**Show HN: Running OpenClaw on a Pixel 10a – no root, Termux + proot Ubuntu**

## URL

[LINK TO GITHUB REPO]

---

## First comment (post immediately after submitting)

Author here. I bought a Pixel 10a yesterday ($499, Best Buy, day after launch) and spent the evening getting OpenClaw running on it as an always-on AI edge node.

The working path: Termux → proot-distro Ubuntu → NodeSource Node.js 22 → OpenClaw.

The interesting parts:

**Why native Termux doesn't work:** koffi (FFI library) needs to compile from source, but Termux uses Bionic libc. Termux's `make` binary parses arguments differently than GNU make — it literally dumps its help text instead of building. Even with cmake + clang installed, you can't get past this without a real glibc environment.

**proot-distro is surprisingly good:** It runs full Ubuntu in userspace via ptrace syscall interception. No root, no bootloader unlock. ~500MB disk overhead. The only issue I found was npm's cache doing cross-filesystem renames that proot can't intercept, fixed by pointing the cache at /tmp.

**Android power management is 5 layers deep:** Doze, App Standby, Adaptive Battery, CPU Freeze, WiFi Sleep — each one independently capable of killing your background process. The guide has ADB commands for all of them plus verification steps.

The guide includes all 8 errors I hit with root cause analysis, every ADB optimization command, 6 screenshots from the actual install, and 860 lines of raw device property dumps.

Use case is edge AI for drone operations — the Pixel gives you compute + camera + mic + GPS + cellular for $499 with 7 years of updates. Happy to answer questions about the setup or the broader architecture.

---
