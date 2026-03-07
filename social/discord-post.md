# Discord Post

> Adapt for: OpenClaw Discord, self-hosted Discord communities, Termux Discord, homelab Discords
> Use the short version for announcements, long version for #guides or #builds channels

---

## Short version (for #general or announcement channels)

**Pixel 10a → OpenClaw Edge Node (no root)**

Got OpenClaw running on a brand new Pixel 10a. $499 phone, day one.

The trick: don't try native Termux — koffi's native modules won't build against Bionic libc. Instead:

```
Termux → proot-distro Ubuntu → NodeSource Node.js 22 → OpenClaw
```

Also had to fix npm cache (proot can't do cross-fs rename) and defeat 5 layers of Android power management.

Full guide with every error + fix: **[GITHUB LINK]**

---

## Long version (for #guides or #builds channels)

### Running OpenClaw on a Pixel 10a — Full Walkthrough

**Device:** Pixel 10a (128GB, unlocked, $499)
**OS:** Android 16
**SoC:** Tensor G4 (8-core ARM64)
**RAM:** 8GB
**Time:** ~15 min (happy path) / ~2 hrs (figuring it out)

#### The working path

```bash
# 1. Install Termux via ADB (NOT from Play Store)
adb install termux-v0.118.3-arm64.apk

# 2. Disable Android's 5 layers of process killing
adb shell dumpsys deviceidle whitelist +com.termux
adb shell cmd appops set com.termux RUN_IN_BACKGROUND allow
adb shell cmd appops set com.termux RUN_ANY_IN_BACKGROUND allow
adb shell svc power stayon usb
adb shell settings put system screen_off_timeout 1800000
adb shell settings put global wifi_sleep_policy 2

# 3. In Termux: install proot Ubuntu
pkg install -y proot-distro
proot-distro install ubuntu
proot-distro login ubuntu

# 4. Inside Ubuntu: Node.js + OpenClaw
apt update && apt install -y curl
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs
npm config set cache /tmp/npm-cache
npm install -g openclaw
```

#### What doesn't work (save yourself the time)

- **Native Termux npm install** — koffi won't compile. Bionic libc ≠ glibc, Termux make is broken for koffi's build system.
- **Play Store Termux** — outdated, unmaintained, don't use it.
- **`adb shell device_config put`** for adaptive battery — needs root, throws SecurityException.

#### Errors I hit (8 total)

1. `spawn git` ENOENT → install git
2. CMake not found → install cmake
3. make dumps help instead of building → give up on native, use proot
4. npm `rename` ENOENT in proot → `npm config set cache /tmp/npm-cache`
5. Node.js too old → use NodeSource not Ubuntu default
6. Screen goes black mid-install → `svc power stayon usb`
7. Processes killed in background → whitelist + wakelock + unrestricted battery
8. device_config SecurityException → manual Settings toggle

Full guide with screenshots: **[GITHUB LINK]**

---
