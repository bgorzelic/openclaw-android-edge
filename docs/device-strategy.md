# Device Selection and Compatibility Guide

Running OpenClaw on Android phones via Termux turns a $349 phone into a production AI agent gateway. This guide covers which devices work, which to avoid, and what actually matters for this workload.

**Author:** Brian Gorzelic / AI Aerial Solutions
**Last Updated:** March 2026

---

## Why Pixel 10a

The Pixel 10a is the device tested and documented throughout this guide. Here is why it was chosen:

- **$349** — the cheapest device that checks every box
- **Tensor G4 SoC** — ARM big.LITTLE architecture with A520 efficiency cores, A725 mid cores, and X4 prime core
- **8GB RAM** — enough for Android overhead plus the gateway workload
- **128GB storage** — more than sufficient (OpenClaw uses 641MB total)
- **5100mAh battery** — acts as a built-in UPS during power interruptions
- **7 years of OS and security updates** — supported through 2031
- **Android 16** — confirmed working with Termux from F-Droid/GitHub releases

The big.LITTLE architecture deserves special attention. An AI gateway spends most of its time idle, waiting for API calls. The A520 efficiency cores handle this idle/light workload at minimal power draw, while the larger cores are available when needed for bursts of processing. This is exactly the right CPU topology for an always-on I/O-bound service.

---

## What Matters for This Workload

Not every spec matters equally. An AI gateway is not a gaming workload or a video editing pipeline. Here is what actually affects performance and reliability:

### RAM: 8GB Minimum

Android itself consumes roughly 6GB of RAM under normal conditions. The OpenClaw gateway uses approximately 323MB. That leaves a thin but workable margin on an 8GB device. Devices with less than 8GB will experience memory pressure, OOM kills, and unreliable gateway operation.

More RAM (12GB, 16GB) provides headroom for running multiple agents or heavier workloads, but 8GB is the tested floor.

### Storage: 128GB Is Fine

The entire OpenClaw installation — runtime, dependencies, configuration, and logs — occupies about 641MB. Even with Termux packages, system apps, and generous log rotation, 128GB is far more than needed. Do not pay extra for storage unless you plan to use the phone for other purposes.

### CPU: Efficiency Cores Matter Most

The gateway idles at 0% CPU utilization when no requests are active. During request processing, CPU usage spikes briefly then drops back. This means:

- Efficiency core performance affects battery life and thermal behavior more than peak core speed
- A phone with great efficiency cores and mediocre peak cores will outperform the reverse for this use case
- Thermal throttling under sustained load is not a concern because the load is bursty, not sustained

### Battery: Larger Is Better

The battery serves double duty as a UPS. During power outages, a larger battery keeps the gateway running longer. The Pixel 10a's 5100mAh battery provides several hours of gateway operation without wall power, depending on request volume.

### Update Support: Longer Is More Secure

A gateway exposed to the internet (even behind a reverse proxy) needs security patches. Devices with longer update commitments reduce the frequency of forced hardware replacements. The Pixel 10a's 7-year commitment is currently best-in-class for Android.

### Termux Compatibility

Termux must be installed from F-Droid or GitHub releases — the Google Play Store version is outdated and broken. Not all Android devices work well with Termux. Known issues include:

- Aggressive battery optimization that kills background processes
- SELinux policies that block Termux operations
- OEM modifications that interfere with `proot` or native compilation

Pixel devices have the fewest compatibility issues because they run stock Android.

---

## Device Tiers

### Budget ($200-400) -- Tested

| Device | Price | RAM | Battery | Updates | Status |
|--------|-------|-----|---------|---------|--------|
| **Pixel 10a** | $349 | 8GB | 5100mAh | 7 years | **Tested -- this guide** |

This is the only device in this tier that has been validated end-to-end with this guide. If you want a guaranteed working setup, buy this phone.

### Mid-Range ($400-700) -- Expected Compatible

| Device | Price | RAM | Battery | Updates | Notes |
|--------|-------|-----|---------|---------|-------|
| Pixel 10 | ~$599 | 12GB | 4500mAh | 7 years | Stock Android, likely works identically |
| Samsung Galaxy A56 | ~$400 | 8-12GB | 5000mAh | 5 years | One UI may need extra battery optimization disabling |
| OnePlus Nord 4 | ~$400 | 8-16GB | 5500mAh | 4 years | OxygenOS is close to stock; large battery |

**These devices have not been tested with this guide.** They are expected to work based on hardware specs and known Termux compatibility, but your mileage may vary. If you use one of these, please submit a device report (see below).

The additional RAM in this tier (12-16GB) provides meaningful headroom for running multiple gateway instances or heavier agent configurations. Storage and CPU upgrades provide little practical benefit for this workload.

### Flagship ($700+) -- Overkill but Works

| Device | Price | RAM | Battery | Updates | Notes |
|--------|-------|-----|---------|---------|-------|
| Pixel 10 Pro | ~$999 | 16GB | 5000mAh | 7 years | Tensor G4, stock Android, extra RAM |
| Samsung Galaxy S25 | ~$800 | 12GB | 4000mAh | 7 years | Snapdragon 8 Elite, smaller battery |
| OnePlus 13 | ~$900 | 12-16GB | 6000mAh | 4 years | Massive battery, fast charging |

These devices work but cost 2-3x more than the Pixel 10a for marginal benefit in this use case. The extra RAM helps if you plan to run multi-agent scenarios or stack additional services alongside the gateway. The NPU/TPU hardware in flagship SoCs could eventually enable local inference for small models, but that is a future capability, not a current one.

If you already own a flagship phone, use it. If you are buying specifically for this project, the Pixel 10a is the better investment.

### Not Recommended

The following categories of devices will cause problems:

- **Phones with less than 6GB RAM** — Android alone will consume most of the available memory, leaving nothing for the gateway
- **Phones without an unlockable bootloader** — some carrier-locked Samsung devices fall into this category; while bootloader unlocking is not strictly required for Termux, it correlates with OEM restrictions that interfere with Termux operation
- **Phones with aggressive, non-disableable battery optimization** — some Huawei/Honor and Xiaomi devices kill background processes regardless of user settings (see [dontkillmyapp.com](https://dontkillmyapp.com/) for per-manufacturer ratings)
- **iOS devices** — there is no Termux equivalent on iOS; the sandboxing model prevents running a gateway stack
- **Phones running Android 9 or older** — Termux requires Android 10+ for current releases
- **Tablets** — they work technically but are harder to mount, lack cellular for failover connectivity, and cost more per unit of capability

---

## Community Device Reports

This guide is tested on a single device. The community can expand coverage by submitting device reports for hardware not listed above.

### How to Submit a Device Report

A GitHub issue template is available at `.github/ISSUE_TEMPLATE/device_report.md`. To submit a report:

1. Open a new issue using the **Device Compatibility Report** template
2. Fill in your device model, Android version, RAM, and Termux installation source
3. Document what worked and what required workarounds
4. Include the output of `uname -a` and `free -h` from within Termux
5. Note any battery optimization settings you had to change

Reports help other users choose hardware with confidence and help maintainers identify compatibility issues before they become blockers.

### What Makes a Good Report

- Specific Android version and security patch level
- Whether Termux was installed from F-Droid or GitHub releases
- Any OEM-specific settings that had to be changed (battery optimization, background process limits)
- Gateway uptime achieved (hours or days of continuous operation)
- Any crashes, OOM kills, or unexpected behavior

---

## Buying Guide

### New vs. Used

**New ($349 for Pixel 10a):**
- Full warranty and update support
- Known battery health (100% capacity)
- No risk of prior damage or water exposure
- Predictable remaining update window

**Used/Refurbished ($150-250 for previous-gen Pixels):**
- Significantly cheaper upfront
- Battery may be degraded (check battery health in settings)
- Shorter remaining update window
- Risk of undisclosed damage
- A Pixel 9a or Pixel 8a at $150-200 used is a reasonable choice if budget is the primary constraint

For a device that will run 24/7 as infrastructure, buying new is usually worth the premium. Battery degradation on a used device directly reduces your effective UPS capacity.

### What to Check Before Buying

1. **Carrier lock status** — buy unlocked if possible; carrier-locked devices sometimes have restricted bootloaders or extra bloatware
2. **RAM configuration** — some models ship in multiple RAM variants; confirm you are getting 8GB or more
3. **Android version** — ensure the device ships with or can be updated to Android 12+ (Android 16 preferred)
4. **Region/variant** — some regional variants have different SoCs or RAM configurations
5. **Return policy** — if Termux does not work as expected on a non-Pixel device, you want the option to return it

### Recommended Accessories

- **USB-C PD charger (20W+)** — for reliable always-on charging; avoid cheap no-name chargers that may degrade battery health faster
- **Phone stand or dock** — keeps the device upright for airflow and display visibility; a simple adjustable desk stand works fine
- **Short USB-C cable (1-2 ft)** — reduces cable clutter at the deployment location
- **Screen protector** — optional, but prevents accidental screen damage if the phone is in a high-traffic area

You do not need a case if the phone is stationary. You do not need a keyboard or mouse — all administration happens over SSH.
