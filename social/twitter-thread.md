# Twitter/X Thread — @spookyjuiceai

> Post as a thread. Each `---` is a new tweet. Keep images where noted.

---

**TWEET 1** (hook)

I bought a Pixel 10a yesterday for $499 and turned it into an always-on AI edge node running OpenClaw.

No root. No bootloader unlock. Just Termux + Ubuntu in userspace.

Here's everything that broke and how I fixed it. Full guide + screenshots.

🧵👇

---

**TWEET 2** (the device)

The Pixel 10a is kind of perfect for this:

• Tensor G4 — 8 cores, big.LITTLE, efficient for always-on
• 8GB RAM — ~2GB still free during install
• 128GB storage — 213GB available after Android
• 7 years of security updates
• $499 with camera, mic, GPS, cellular

It's the cheapest 2026-spec ARM64 Linux box you can buy.

---

**TWEET 3** (first wall — Android power management)

First thing you learn: Android REALLY doesn't want you running background processes.

There are 5 separate layers trying to kill your app:
• Doze
• App Standby
• Adaptive Battery
• CPU Freeze
• WiFi Sleep

You have to defeat all 5. I documented every ADB command.

---

**TWEET 4** (Termux native fails)

Tried installing OpenClaw directly in Termux. Failed 3 times in a row.

1. npm can't find git → easy fix
2. koffi needs cmake to build from source → installed it
3. make straight up doesn't work → Termux uses Bionic libc, not glibc. koffi's build system expects /bin/sh, Termux has /data/data/com.termux/files/usr/bin/sh

Native Termux is a dead end for anything with native modules.

📸 [attach: 04-koffi-make-error.png]

---

**TWEET 5** (the pivot)

The fix: proot-distro.

It runs a full Ubuntu inside Termux via userspace syscall interception. No root needed. ~500MB disk. Slight overhead but full glibc compatibility.

```
pkg install -y proot-distro
proot-distro install ubuntu
proot-distro login ubuntu
```

3 commands and you're in a real Linux environment on your phone.

---

**TWEET 6** (one more gotcha)

Almost there but npm cache breaks inside proot — the `rename` syscall can't cross filesystems through proot's interception layer.

Fix is stupid simple:
```
npm config set cache /tmp/npm-cache
```

Same filesystem = no cross-fs rename = works.

---

**TWEET 7** (victory)

After that:
```
npm install -g openclaw
openclaw --version
```

Done. OpenClaw running on a phone. ~15 minutes total if you know the path. Took me about 2 hours to find it.

📸 [attach: 05-proot-ubuntu-installed.png]

---

**TWEET 8** (the happy path)

TL;DR the entire working install:

```
# Mac side
adb install termux.apk
adb shell dumpsys deviceidle whitelist +com.termux

# Phone side (Termux)
pkg install -y proot-distro
proot-distro install ubuntu
proot-distro login ubuntu

# Inside Ubuntu
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs
npm config set cache /tmp/npm-cache
npm install -g openclaw
```

---

**TWEET 9** (CTA)

Full guide with every error, fix, ADB command, and screenshot is on GitHub:

[LINK TO GITHUB REPO]

8 errors documented with solutions. 860 lines of device property dumps. 6 annotated screenshots.

If you're running AI workloads on phones, this is the reference doc.

---

**TWEET 10** (big picture)

Why phones as edge nodes?

A Pixel 10a gives you compute + camera + mic + GPS + cellular + battery backup in one $499 package.

For drone ops, field deployment, or just a node that fits in your pocket — this is the play.

More builds coming. Follow @spookyjuiceai.

---
