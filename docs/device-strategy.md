# Device Selection Guide: Android for OpenClaw

> **Author:** Brian Gorzelic / AI Aerial Solutions
> **Last Updated:** March 2026
> **Reference Device:** Google Pixel 10a — Tensor G4, 8GB RAM, Android 16, $349

This guide helps you choose the right Android device for running OpenClaw as an always-on AI gateway. It covers why Pixel is the recommended platform, what the actual hardware requirements are, what to prioritize in a device choice, and how different tiers compare in practice.

---

## Table of Contents

1. [Why Android at All](#why-android-at-all)
2. [Why Pixel Specifically](#why-pixel-specifically)
3. [Minimum Hardware Requirements](#minimum-hardware-requirements)
4. [What Matters vs What Does Not](#what-matters-vs-what-does-not)
5. [Device Comparison Table](#device-comparison-table)
6. [Budget vs Mid-Range vs Flagship Considerations](#budget-vs-mid-range-vs-flagship-considerations)
7. [Avoiding Common Mistakes](#avoiding-common-mistakes)
8. [Acquisition Tips](#acquisition-tips)

---

## Why Android at All

The alternatives — and why they fall short for this specific use case:

**Raspberry Pi / SBC:**
A Raspberry Pi 5 (8GB) costs $80 and runs Debian natively, which avoids the Termux layer entirely. But it requires a power supply, a case, active cooling, a microSD card, and a wired or USB WiFi adapter. It has no cellular radio and no battery backup. A power outage or router restart takes it offline until you physically intervene. Setup is significantly more involved.

For always-on operation without physical access, the Pi's lack of built-in battery and cellular are real weaknesses. If the power goes out at your house overnight, the Pi is down until you get home.

**Old iPhone:**
iOS has no equivalent of Termux. There is no way to run a persistent background Node.js process on iOS without jailbreaking. The iOS sandbox model is fundamentally incompatible with the gateway architecture.

**Mac mini / NUC:**
These work and are arguably superior for compute-heavy workloads. They cost $200-800+, require a UPS for power resilience, and have no cellular. For the relay-only use case where the phone does no inference, the Mac mini is overpowered and over-budget.

**Cloud VM:**
A cloud VM (GCP e2-medium, ~$25-35/month) eliminates the hardware concerns but has no battery backup, no cellular, no access to local network devices, and ongoing monthly cost. After two years, the cloud VM costs more than a Pixel 10a, with none of the physical sensor advantages. See [OPTIMIZATION-GUIDE.md](../OPTIMIZATION-GUIDE.md) for the cost comparison.

**Android wins for this use case** because it combines a cellular radio (independent network), a battery (independent power), local network presence, a usable Linux environment via Termux, and a purchase price that is competitive with or below the alternatives.

---

## Why Pixel Specifically

Among Android phones, Pixel is the recommended platform. The reasons are mostly non-obvious.

### Software Update Longevity

Google guarantees 7 years of Android OS and security updates for Pixel 8 and later. The Pixel 10a (March 2026) is supported until at least 2033.

This matters more than it might seem. An always-on server running Termux needs security patches applied regularly. A phone that falls off the update schedule is a security liability. Most non-Pixel Android phones receive 2-3 years of updates. Samsung has improved to 4 years for flagship devices, and select Samsung A-series receive 4 years as well. No other Android OEM matches Pixel's 7-year commitment.

A Samsung Galaxy A55 bought in 2025 is likely to fall off the update schedule around 2029. A Pixel 10a is supported until 2033. If you are building infrastructure you intend to use for several years, update longevity is a real planning constraint.

### Unlocked Bootloader and Carrier Independence

Pixel phones purchased unlocked have no carrier bloatware, no additional background processes from carrier-mandated apps, and no restrictions on VPN usage. Carrier-branded Android phones often have custom modifications that interfere with Tailscale's VPN profile and with backgrounded long-running processes.

The Pixel from Google's store or from Best Buy (unlocked SKU) runs stock Android with no additions. Fewer background processes means more RAM available to Termux.

### Stock Android Power Management

Pixel runs stock Android without OEM customizations to the power management stack. The ADB commands documented in [INSTALL-GUIDE.md](../INSTALL-GUIDE.md) Phase 3 work exactly as specified on Pixel. On Samsung, Xiaomi, OnePlus, and other OEMs, additional layers of proprietary battery optimization exist beyond the standard Android stack — Samsung's Device Care, MIUI's Auto-start restrictions, OnePlus's aggressive background process limits — and these require additional OEM-specific steps to disable.

The Pixel's power management is fully controllable via the standard ADB commands documented in this guide. No undocumented OEM-specific steps are required. This is a significant practical advantage for a headless deployment where you may not have physical access to the device regularly.

### Tensor Chip

The Tensor G4 uses a tri-cluster ARM big.LITTLE architecture (A520 efficiency cores, A725 mid cores, X4 prime core). The efficiency core cluster is where the gateway process lives at idle. At 0% CPU utilization between requests, the scheduler keeps the process on the A520 cores, which consume milliwatts. This is why the gateway can run 24/7 without meaningful battery impact.

The Tensor NPU (Neural Processing Unit) is not currently used by OpenClaw's relay architecture — inference happens in the cloud. However, Termux:API exposes Android's on-device speech recognition (which routes through the Tensor NPU) for voice interaction use cases. Local inference via llama.cpp on Tensor is a future capability that is in active development.

### Camera Quality (for Field Use Cases)

Pixel's computational photography is best-in-class at any price. For the [field data collector use case](./use-cases.md#4-field-data-collector), image quality directly affects AI interpretation accuracy. A photograph of a solar panel, inspection site, or document taken on a Pixel 10a will produce better AI analysis results than the same photo from a budget Android phone with a lesser camera pipeline.

This is not relevant if you are only using the phone as a relay for text-based messaging and never triggering the camera skills.

---

## Minimum Hardware Requirements

These are the floor requirements for running OpenClaw as a gateway. Below these, the gateway will not run reliably.

| Requirement | Minimum | Recommended | Notes |
|-------------|---------|-------------|-------|
| **RAM** | 6GB | 8GB | Gateway uses ~323MB RSS; Android OS and base apps consume 3-4GB. Under 6GB, the OOM killer targets Termux aggressively. |
| **Storage** | 64GB | 128GB | OpenClaw install is ~640MB. OS, Termux, proot Ubuntu, and logs need ~8-10GB total. 64GB is technically sufficient but leaves little headroom. |
| **CPU** | Any 64-bit ARM (aarch64) | Cortex-A55 or newer | OpenClaw and Node.js run on aarch64 only. All phones released since 2019 meet this. The workload is I/O-bound — peak CPU speed is not a bottleneck. |
| **Android version** | Android 12 | Android 14+ | Android 12 is the minimum supported by current Termux releases. Older Android versions have filesystem restrictions that break proot-distro. |
| **Security updates** | Active (within 6 months) | Updated within 3 months | A phone that has not received security patches recently should not be running a networked server process. |
| **Battery** | Any | 4,000+ mAh | For always-plugged-in use, capacity is irrelevant — the charger keeps it topped up. For portable or intermittent use, larger battery means longer autonomy without wall power. |
| **Connectivity** | WiFi | WiFi + LTE | WiFi-only is sufficient for home use. LTE provides cellular failover if home internet goes down. |

---

## What Matters vs What Does Not

Understanding which specifications matter prevents paying for the wrong things.

### What Actually Matters

**RAM** — The single most critical specification. The gateway uses 323 MB RSS, but Android's OS footprint means you need total RAM well above that threshold. On 8GB, approximately 910 MB is available after the OS and gateway. On 6GB, this margin is tighter and requires more aggressive battery optimization settings to prevent OOM kills. More RAM directly reduces operational friction.

**Software update longevity** — For a server you intend to run for years, this is a security and reliability requirement. A phone that falls off the update schedule in 18 months is a liability for a deployment intended to run for 3-5 years.

**ADB and power management controllability** — Stock Android is significantly easier to configure than OEM-customized Android. The more proprietary power management layers a phone has, the more undocumented steps are required to keep the gateway alive.

**Unlocked carrier status** — Carrier-locked phones may have restrictions on VPN profiles (affecting Tailscale) and may have carrier-mandated background apps consuming RAM.

**Cellular radio (for resilient deployments)** — If you need the phone to stay connected during home WiFi outages, it needs active cellular service and a data plan. If the phone will always be on your home WiFi with no failover requirement, cellular is optional.

### What Does Not Matter for This Use Case

**Display quality** — The phone runs headless. You never look at the screen after initial setup. A 60Hz 720p display and a 144Hz 2K AMOLED are identical from the gateway's perspective.

**Camera megapixel count** — For relay-only use cases, the camera is irrelevant. Even for field data collection, camera software matters more than raw megapixel count.

**Premium materials and design** — Glass backs, ceramic, aluminum frames, IP68 water resistance ratings — irrelevant for a phone sitting on a desk connected to a charger.

**Audio quality** — Speaker quality, headphone jack presence, DAC specifications — irrelevant.

**Gaming GPU benchmarks** — The gateway is I/O-bound. Antutu scores, GPU frame rates, and gaming benchmarks have zero correlation with gateway performance.

**5G vs LTE** — 5G vs LTE makes no meaningful difference for the gateway's traffic patterns. The gateway sends and receives small amounts of data (chat messages, API calls). LTE is sufficient. 5G adds cost without practical benefit.

**Brand prestige** — The phone sits on a desk running headless. No one sees it.

---

## Device Comparison Table

The following table covers devices relevant for this use case as of early 2026. Pricing reflects approximate market rates, not retail MSRP, as many phones are available below list price through sales, refurbished channels, or carrier promotions.

| Device | Est. Price | RAM | Android Support Until | Stock Android | Power Mgmt | Notes |
|--------|-----------|-----|----------------------|--------------|------------|-------|
| **Pixel 10a** | $349 new | 8GB | 2033 | Yes | Standard ADB | Reference device for this guide. Best overall. |
| **Pixel 9a** | ~$350-400 | 8GB | 2032 | Yes | Standard ADB | Same update policy. Excellent alternative. |
| **Pixel 8a** | ~$249-350 | 8GB | 2031 | Yes | Standard ADB | Tensor G3. Still well within support window. |
| **Pixel 7a** | ~$150-200 (used) | 8GB | 2030 | Yes | Standard ADB | Tensor G2. Older but 8GB and long support. |
| **Pixel 6a** | ~$100-150 (used) | 6GB | 2028 | Yes | Standard ADB | 6GB RAM is tight. Works but needs careful tuning. |
| **Samsung Galaxy S25** | ~$799 | 12GB | 2032 (7 years) | No (OneUI) | Extra steps | OneUI battery management adds configuration complexity. |
| **Samsung Galaxy A56** | ~$399 | 8GB | 2029 (4 years) | No (OneUI) | Extra steps | Shorter update window. OneUI adds friction. |
| **Samsung Galaxy A55** | ~$299 | 8GB | 2028 (4 years) | No (OneUI) | Extra steps | Works, but requires OEM-specific battery settings. |
| **Motorola Edge 50** | ~$249 | 8GB | ~2027 | Near-stock | Minimal | Close to stock Android. Shorter update window is the concern. |
| **OnePlus 12** | ~$499 | 12GB | ~2027-2028 | No (OxygenOS) | Extra steps | Aggressive background kill list. Requires extra tuning. |
| **Xiaomi 14T** | ~$399 (global) | 12GB | ~2027 | No (MIUI) | Difficult | MIUI auto-start restrictions are difficult to override via ADB. Not recommended. |
| **Pixel 5a and older** | ~$75-100 (used) | 6GB | End of life | Yes | Standard ADB | Out of security support. Not recommended for networked server. |
| **Any phone, <6GB RAM** | Varies | <6GB | Varies | Varies | Varies | Not recommended. Memory pressure will cause frequent OOM kills. |

**Recommendation summary:**
- Buying new: Pixel 10a or 9a
- Buying used on a budget: Pixel 8a or 7a
- Already own a non-Pixel: check [dontkillmyapp.com](https://dontkillmyapp.com) for your OEM's background process rating before committing
- Avoid: EOL devices, <6GB RAM, MIUI devices

---

## Budget vs Mid-Range vs Flagship Considerations

### Budget Tier (~$100-250)

**Options:** Used Pixel 7a, used Pixel 8a, Motorola Edge 40 Neo.

The used Pixel market is the highest-value option for this use case. A used Pixel 8a in good condition at $200-250 has:
- 8GB RAM (comfortable for the gateway)
- Support through 2031 (5+ years remaining)
- Stock Android with standard ADB power management
- A proven track record with Termux

The only relevant concern with used phones for this use case is battery health — but for a permanently-plugged-in deployment, battery degradation is largely irrelevant. A battery at 78% capacity is fine when the phone never needs to run off-battery.

**Avoid in this tier:** Budget phones from unknown brands, phones with less than 6GB RAM, any phone already past its security update end-of-life date.

### Mid-Range (~$300-500)

**Options:** Pixel 10a (new), Pixel 9a, Samsung Galaxy A56.

This is where the cost-benefit curve peaks for this use case. A new Pixel 10a at $349 gives you:
- 7-year support window from today (2033)
- Known hardware condition with full warranty
- Fresh battery at 100% capacity
- Confirmed compatibility with every step of this guide

The Pixel 9a, if found at a meaningful discount, is nearly identical in capability. The Tensor G4 vs G5 difference is not measurable in gateway workloads.

Samsung in this tier works but requires additional setup steps. Unless you already own a Samsung or have a specific reason to prefer it, the Pixel is the simpler choice.

### Flagship Tier (~$700+)

**Options:** Pixel 9 Pro, Pixel 9 Pro XL, Samsung Galaxy S25.

The flagship premium is hard to justify for a gateway-only deployment. The practical differences:
- 12-16GB RAM vs 8GB — genuinely useful; the OOM killer is less likely to ever touch Termux. But a properly-configured 8GB device is already stable.
- Better camera — only relevant for field data collection use cases.
- Faster charging — irrelevant for a device that is always plugged in and never discharges.

**Verdict:** If you already own a flagship phone, use it. If you are buying specifically for this project, the Pixel 10a is the better investment. The 40-60% price premium over the 10a does not translate to a 40-60% improvement in gateway reliability or capability.

---

## Avoiding Common Mistakes

**Buying a carrier-locked phone:**
Carrier-locked phones tie the device to a specific carrier for 12-24 months and often come with carrier-installed apps that run background processes. Some carriers restrict VPN profiles that do not match their own service — this can prevent Tailscale from creating a persistent VPN connection. Always verify the phone is sold as "unlocked" before purchasing.

**Buying an EOL phone because it is cheap:**
A Pixel 5a or 4a costs $75-100 used. But both are end-of-life for security updates. Running a networked server process on a phone that no longer receives security patches is a real risk. The $75 savings is not worth the security exposure over a multi-year deployment.

**Underestimating RAM:**
6GB is the floor, not the comfortable operating point. On 6GB devices, Android's low-memory killer is noticeably more aggressive. If you are simultaneously running Tailscale, the Termux wake lock service, and a proot session alongside the gateway, you are competing for memory with Android's system services. The gateway works on 6GB but requires careful tuning and still has a higher chance of unexpected termination.

**Paying for specifications that do not apply:**
A phone with an excellent gaming GPU, high-resolution camera system, and premium build materials will not run OpenClaw any better than a mid-range phone with the same RAM. Do not pay for specifications that are irrelevant to the gateway workload.

**Ignoring the update policy:**
A phone bought in 2026 with a 3-year update policy reaches end-of-life in 2029. If you intend to run this gateway for 4+ years (which is the whole point — amortizing hardware cost over time), buying a phone that stops receiving security updates mid-deployment is a planning failure.

**Choosing a phone with an OEM-modified power management stack without verifying it works:**
This is the most common source of "it's killing my process" frustration. If you choose a non-Pixel Android device, verify in advance what steps are required to permanently disable battery optimization for Termux. Check [dontkillmyapp.com](https://dontkillmyapp.com) — it documents per-OEM background process behavior and required workarounds.

---

## Acquisition Tips

### Where to Buy New

- Google Store (unlocked, full warranty, direct from manufacturer)
- Best Buy (unlocked SKU — confirm at purchase, not the carrier-associated models)
- Amazon (verify "unlocked" appears in the product title, not just the description)

### Where to Buy Used

- **Swappa** — buyer protection, seller-verified device condition, IMEI checks
- **Back Market** — refurbished with graded condition and warranty
- **eBay** — higher variance; check seller rating carefully, ask for photos of battery health screen

### Condition Assessment for Used Devices

For a permanently-plugged-in deployment:
- Battery health below 80%: acceptable (it sits on a charger)
- Screen cracks and cosmetic damage: irrelevant
- WiFi functionality: verify before buying
- Carrier lock status: ask the seller, or verify with IMEI lookup

### Verifying Before You Commit

Before setting up the deployment:

```bash
# From Termux: verify RAM
free -h

# Verify Android version
getprop ro.build.version.release

# Verify security patch level
getprop ro.build.version.security_patch

# Verify ABI
getprop ro.product.cpu.abi
# Should output: arm64-v8a
```

### SIM and Connectivity Considerations

For cellular failover (optional but recommended):
- Active data plan on the phone
- Enable "Always-on VPN" for Tailscale in Android Settings > Network > VPN
- The phone will automatically switch from WiFi to LTE when WiFi is unavailable, and Tailscale reconnects on the new interface within seconds

For WiFi-only (home-only deployment with no cellular failover):
- No SIM required
- No data plan cost
- The phone is unavailable if home internet is down

### Recommended Accessories

| Accessory | Purpose | Notes |
|-----------|---------|-------|
| USB-C PD charger (20W+) | Always-on power | Avoid no-name chargers; they can cause irregular charging behavior |
| Short USB-C cable (1-2 ft) | Reduced cable clutter | Silicon or braided cables hold up better over years of continuous use |
| Phone stand or desk mount | Airflow and stability | A simple adjustable stand works fine; keeps ports accessible |

You do not need a case (the phone is stationary), a screen protector (the screen is never touched), a keyboard, or a mouse. All administration happens over SSH after initial setup.

---

*For installation instructions on the Pixel 10a, see [INSTALL-GUIDE.md](../INSTALL-GUIDE.md).*
*For security considerations on any device, see [docs/threat-model.md](./threat-model.md).*
*For cost analysis and optimization, see [OPTIMIZATION-GUIDE.md](../OPTIMIZATION-GUIDE.md).*
