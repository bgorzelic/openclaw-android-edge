# SIGNAL — Wireless Network Engineer's Companion

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a native Android app that turns a Pixel phone + OpenClaw into a professional wireless network diagnostic tool — the modern AirMagnet replacement that runs in your pocket, powered by edge AI.

**Architecture:** Native Kotlin/Jetpack Compose app communicating with OpenClaw via localhost REST API. Edge-first design: all core analysis runs on-device without internet. Optional SpookyJuice cloud backend for fleet management, trend analysis, and shared intelligence.

**Tech Stack:** Kotlin, Jetpack Compose, Android WiFi APIs, OpenClaw REST API, Room (local DB), Ktor (syslog server), SpookyJuice cloud (future)

---

## Table of Contents

1. [Market Context](#1-market-context)
2. [Product Vision](#2-product-vision)
3. [Target Users](#3-target-users)
4. [System Architecture](#4-system-architecture)
5. [Feature Set](#5-feature-set)
6. [Data Pipeline](#6-data-pipeline)
7. [OpenClaw Integration](#7-openclaw-integration)
8. [Edge vs Cloud Split](#8-edge-vs-cloud-split)
9. [Productization Strategy](#9-productization-strategy)
10. [Monetization](#10-monetization)
11. [Technical Constraints](#11-technical-constraints)
12. [MVP Scope](#12-mvp-scope)
13. [Future Roadmap](#13-future-roadmap)

---

## 1. Market Context

Full research: [WiFi Diagnostic Tools Market Research](../research/2026-03-09-wifi-diagnostic-tools-market-research.md)

### Key Findings

- **$1-2.5B market** for WiFi diagnostic tools (WLAN management subset)
- **NetAlly AirMagnet discontinued** — thousands of enterprise wireless engineers lost their primary roaming analyzer with no modern replacement
- **No mobile-first professional tool exists** — every serious tool is Windows/laptop-based
- **AI root cause analysis is primitive** — Ekahau added "AI" but it's pattern matching on surveys, not real-time analysis
- **Cross-vendor log intelligence doesn't exist** — engineers manually parse Cisco, Aruba, Meraki, Ruckus logs in different formats
- **Roaming analysis requires $15K+ hardware** — AirCheck G3 ($5K) + EtherScope ($10K) for what could be software

### 6 Market Gaps SIGNAL Fills

1. Mobile-first WiFi diagnostics (zero competition)
2. AirMagnet replacement (dead product, active demand)
3. Real-time AI root cause analysis (nobody does this)
4. Cross-vendor log intelligence (universal pain point)
5. Software-based roaming analysis (replaces $15K hardware)
6. Edge-to-cloud intelligence pipeline (7SIGNAL has cloud only, no edge)

### Pricing Sweet Spot

- Prosumer tools: $50-200/year (WiFi Explorer, WiFi Analyzer)
- **SIGNAL target: $399-599/year**
- Professional platforms: $1,000-3,000+/year (Ekahau, 7SIGNAL)
- Hardware tools: $5,000-15,000 (NetAlly AirCheck, EtherScope)

---

## 2. Product Vision

**One-liner:** SIGNAL is a pocket-sized wireless network engineer powered by edge AI.

**The pitch:** Point your WLC's syslog at your phone. SIGNAL's edge AI instantly analyzes roaming events, auth failures, and RF issues — no laptop, no internet, no $15K hardware. Works in the basement when everything else is broken.

**Core differentiators:**

1. **Mobile-first** — Professional WiFi diagnostics on Android, not ported from Windows
2. **Edge AI** — OpenClaw runs analysis on-device, works completely offline
3. **Cross-vendor** — Parses Cisco, Aruba, Meraki, Ruckus, Juniper log formats
4. **Real-time** — Syslog receiver turns the phone into a live network event monitor
5. **Affordable** — Software replaces $15K in dedicated hardware

**The moat:** Works when the network is down. Every cloud-dependent competitor fails precisely when you need diagnostics most.

---

## 3. Target Users

### Primary: Enterprise Wireless Network Engineers

- Manage 100-10,000+ APs across campus/warehouse/hospital environments
- Troubleshoot roaming issues, auth failures, RF interference daily
- Currently carry laptops + NetAlly hardware + multiple vendor dashboards
- Pain: too many tools, too slow to correlate events across systems

### Secondary: MSPs and Wireless Consultants

- Serve multiple clients with different vendors (Cisco shop A, Aruba shop B)
- Need portable diagnostics they can take site-to-site
- Bill by the hour — faster diagnosis = more profitable
- Pain: context-switching between vendor UIs, no unified workflow

### Future: Network Operations Centers (NOC)

- Fleet-wide monitoring across sites via SpookyJuice cloud
- Trend analysis and predictive maintenance
- This unlocks the Enterprise tier ($999/year)

---

## 4. System Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Android Device                     │
│                                                       │
│  ┌─────────────────┐    ┌──────────────────────────┐ │
│  │   SIGNAL App     │    │      OpenClaw Gateway     │ │
│  │  (Kotlin/Compose)│    │    (Termux, port 18789)   │ │
│  │                  │    │                            │ │
│  │  ┌────────────┐  │    │  ┌──────────────────────┐ │ │
│  │  │ WiFi Scanner│  │    │  │  AI Analysis Engine   │ │ │
│  │  │ (Android API)│ │    │  │  - Log parsing        │ │ │
│  │  ├────────────┤  │    │  │  - Root cause analysis │ │ │
│  │  │Syslog Rcvr │  │◄──►│  │  - Pattern detection  │ │ │
│  │  │ (UDP 1514) │  │REST│  │  - Vendor normalization│ │ │
│  │  ├────────────┤  │API │  │  - Roaming correlation │ │ │
│  │  │Log Importer│  │    │  └──────────────────────┘ │ │
│  │  │(.pcap/.log)│  │    │                            │ │
│  │  ├────────────┤  │    │  Model: Haiku (primary)    │ │
│  │  │ Room DB    │  │    │  Fallback: Flash-Lite      │ │
│  │  │(local store)│ │    │  Deep analysis: Sonnet     │ │
│  │  └────────────┘  │    └──────────────────────────┘ │
│  └─────────────────┘                                  │
│           │                                            │
└───────────┼────────────────────────────────────────────┘
            │ (optional, when online)
            ▼
┌──────────────────────────────────┐
│     SpookyJuice Cloud (v2)       │
│                                   │
│  - Fleet dashboard                │
│  - Trend analysis                 │
│  - Shared intelligence / hive mind│
│  - Report generation (PDF/email)  │
│  - Model updates                  │
│  - Multi-device aggregation       │
└──────────────────────────────────┘
```

### Communication Flow

1. **SIGNAL App → OpenClaw:** HTTP REST via `http://127.0.0.1:18789`
2. **WLC → SIGNAL:** UDP syslog on port 1514 (non-privileged)
3. **SIGNAL → SpookyJuice:** HTTPS sync when online (future)
4. **Engineer → SIGNAL:** Jetpack Compose UI + file import

---

## 5. Feature Set

### Tier 1: Free (WiFi Scanner)

| Feature | Description | Data Source |
|---|---|---|
| **WiFi Scanner** | SSID, BSSID, RSSI, channel, security, signal history | Android WifiManager API |
| **Connected AP Details** | Current connection info, link speed, frequency, IP | Android WifiInfo API |
| **Channel Utilization Map** | Visual channel congestion per band (2.4/5/6 GHz) | Scan results aggregation |
| **Basic Roaming Detection** | Detect BSSID changes, log roaming events passively | Android NetworkCallback |
| **Signal Strength Graph** | Real-time RSSI chart over time for connected AP | WifiInfo polling |
| **Network List Export** | Export scan results as CSV/JSON | Local data |

### Tier 2: Pro ($399/year)

| Feature | Description | Data Source |
|---|---|---|
| **Syslog Receiver** | Phone becomes a portable syslog server (UDP 1514) | Direct WLC/AP syslog |
| **Real-time Event Stream** | Live feed of roaming events, auth failures, deauths | Syslog parsing |
| **AI Root Cause Analysis** | OpenClaw analyzes event patterns, suggests root cause | OpenClaw + syslog data |
| **Cross-Vendor Log Parser** | Normalize Cisco/Aruba/Meraki/Ruckus/Juniper formats | Log upload or syslog |
| **Log File Import** | Paste or upload controller debug output for analysis | File I/O |
| **PCAP Import & Analysis** | Import .pcap files, inspect 802.11 frames | File I/O + local parser |
| **Roaming Timeline** | Visual timeline of client roaming path across APs | Syslog + WiFi events |
| **Client Journey Tracker** | Track a specific MAC address through the network | Syslog correlation |
| **AP Health Dashboard** | Per-AP client count, channel, power, utilization | Syslog + API (v2) |
| **Offline Analysis** | All Pro features work without internet | Edge-first design |
| **Session Recording** | Record diagnostic sessions for playback/sharing | Local storage |
| **Report Generation** | Generate PDF diagnostic reports | Local (basic) |

### Tier 3: Enterprise ($999/year, requires SpookyJuice cloud)

| Feature | Description | Data Source |
|---|---|---|
| **Fleet Dashboard** | Multi-site, multi-device monitoring | SpookyJuice cloud |
| **Trend Analysis** | Historical patterns across weeks/months | Cloud aggregation |
| **Shared Intelligence** | Hive mind: learnings from one site improve all | Cloud ML |
| **Advanced Reports** | Branded PDF/email reports with trend data | Cloud generation |
| **API Access** | REST API for integration with ITSM/ticketing | Cloud API |
| **SSO/SAML** | Enterprise authentication | Cloud auth |
| **Multi-user** | Team accounts with role-based access | Cloud IAM |

---

## 6. Data Pipeline

### Ingestion Priority (MVP)

```
Priority 1: Native WiFi Scanning
  └─ Android WifiManager.startScan() → ScanResult[]
  └─ Throttled: 4 scans/2min foreground, 1/30min background
  └─ Data: SSID, BSSID, RSSI, frequency, channel width, security

Priority 2: Syslog Receiver
  └─ UDP listener on port 1514 (non-privileged, no root needed)
  └─ WLC/AP configured to send syslog to phone's IP
  └─ Parse vendor-specific formats → normalized event stream
  └─ Events: roam, auth, deauth, assoc, disassoc, RF change

Priority 3: Log File Import
  └─ User pastes or uploads controller debug output
  └─ Supports: "show client detail", "show roam-history", debug logs
  └─ Vendor detection → appropriate parser → normalized events

Priority 4: PCAP Import
  └─ User imports .pcap/.pcapng files from laptop capture
  └─ Parse 802.11 management frames (beacon, probe, auth, assoc)
  └─ Extract roaming sequences, timing, reason codes
```

### Vendor Parser Architecture

```
Raw Input (syslog line / log block / pcap frame)
  │
  ▼
┌──────────────────┐
│ Vendor Detector   │ ← Regex patterns identify vendor format
└──────┬───────────┘
       │
       ├─► CiscoWLCParser (9800, AireOS)
       ├─► ArubaParser (AOS-CX, AOS-8, Central)
       ├─► MerakiParser (Dashboard syslog format)
       ├─► RuckusParser (SmartZone, Unleashed)
       ├─► JuniperParser (Mist)
       └─► GenericSyslogParser (RFC 5424 fallback)
       │
       ▼
┌──────────────────┐
│ Normalized Event  │
│ {                 │
│   timestamp,      │
│   event_type,     │ ← roam | auth | deauth | rf_change | ...
│   client_mac,     │
│   ap_name,        │
│   bssid,          │
│   channel,        │
│   rssi,           │
│   reason_code,    │
│   vendor,         │
│   raw_message     │
│ }                 │
└──────────────────┘
       │
       ▼
  Room DB (local) ──► OpenClaw AI analysis
                  ──► UI event stream
                  ──► SpookyJuice sync (when online)
```

---

## 7. OpenClaw Integration

### API Contract

The SIGNAL app communicates with OpenClaw via its REST API on localhost:

```
POST http://127.0.0.1:18789/api/v1/chat
Content-Type: application/json

{
  "messages": [
    {
      "role": "system",
      "content": "You are SIGNAL's wireless network analysis engine. Analyze the following network events and provide root cause analysis."
    },
    {
      "role": "user",
      "content": "<normalized events as structured JSON>"
    }
  ],
  "model": "haiku",
  "stream": true
}
```

### Analysis Modes

| Mode | Model | Use Case | Trigger |
|---|---|---|---|
| **Quick triage** | Haiku | Single event analysis, "what does this mean?" | User taps an event |
| **Pattern detection** | Haiku | Correlate recent events, find anomalies | Automatic on event batch |
| **Deep analysis** | Sonnet (on-demand) | Complex multi-client roaming failure investigation | User requests "deep dive" |
| **Log parsing** | Haiku | Vendor-specific log normalization | On log import |

### Prompt Templates

Stored in OpenClaw workspace as SIGNAL skill files:

- `skills/signal-triage/SKILL.md` — Quick event triage
- `skills/signal-roaming/SKILL.md` — Roaming analysis specialist
- `skills/signal-vendor-parser/SKILL.md` — Multi-vendor log normalization
- `skills/signal-rca/SKILL.md` — Root cause analysis framework

### OpenClaw Health Check

App startup sequence:
1. Ping `http://127.0.0.1:18789/health` (or check gateway canvas endpoint)
2. If healthy → show connected status
3. If unreachable → show "OpenClaw offline" banner, disable AI features, continue with local-only features (scanning, syslog, raw log view)

---

## 8. Edge vs Cloud Split

| Component | Location | Rationale |
|---|---|---|
| WiFi scanning | Phone | Real-time, native API required |
| Syslog receiver | Phone | Must be on same network as WLC |
| Log parsing & normalization | Phone (OpenClaw) | Fast, works offline, privacy |
| Root cause analysis | Phone (OpenClaw) | Edge AI, works without internet |
| PCAP inspection | Phone | Files stay local, large files |
| Event correlation | Phone | Real-time, low latency |
| Local storage (Room DB) | Phone | Session data, history |
| Cross-session trends | Cloud (SpookyJuice) | Needs historical data across days/weeks |
| Fleet dashboard | Cloud (SpookyJuice) | Multi-device aggregation |
| Shared intelligence | Cloud (SpookyJuice) | Hive mind learning across deployments |
| Report generation (advanced) | Cloud (SpookyJuice) | PDF templates, email delivery |
| Model updates | Cloud (SpookyJuice) | Updated prompt templates, parser rules |

**Design principle:** The app works fully offline. Cloud enhances but is never required for core functionality.

---

## 9. Productization Strategy

### The OpenClaw Installation Problem

Current state: Installing OpenClaw on Android is a multi-hour manual process (13+ phases documented in the install guide). This is the #1 barrier to productization.

### Phased Solution

**Phase 1 (MVP): Guided Setup Wizard**
- SIGNAL app includes a step-by-step setup flow
- Checks: Termux installed? → Links to F-Droid
- Checks: OpenClaw installed? → Provides copy-paste commands
- Checks: Gateway healthy? → Verifies connection
- Stores config in shared preferences
- Target: Reduce setup from hours to 30 minutes

**Phase 2: Termux:Tasker Automation**
- SIGNAL triggers Termux commands via Tasker plugin
- Automated OpenClaw installation script
- One-tap setup after Termux is installed
- Target: Reduce setup to 5 minutes

**Phase 3: Bundled Binary**
- Ship OpenClaw gateway as a native Android service
- No Termux dependency
- Single APK install from Play Store
- Target: Standard app install experience

### Distribution

- **Play Store** for the Android app (SIGNAL)
- **F-Droid** for Termux dependency (Phase 1-2)
- **Direct APK** for enterprise deployment (MDM-friendly)
- **OpenClaw Marketplace** for SIGNAL skill pack

---

## 10. Monetization

### Pricing Tiers

| Tier | Price | Target | Key Differentiator |
|---|---|---|---|
| **Free** | $0 | Everyone | WiFi scanner + basic roaming detection |
| **Pro** | $399/year ($33/mo) | Individual engineers | Syslog + AI analysis + PCAP + offline |
| **Enterprise** | $999/year/seat ($83/mo) | Teams/NOCs | Fleet + cloud + API + SSO |

### Free Tier Limits

- WiFi scanning: unlimited
- Roaming detection: basic (BSSID change only)
- Log import: 5 files/day
- Syslog receiver: disabled
- AI analysis: disabled
- Session recording: 1 active session
- Export: CSV only

### Revenue Model

- Year 1 target: 1,000 Pro subscribers = $399K ARR
- Year 2 target: 2,500 Pro + 100 Enterprise seats = $1.1M ARR
- Payment: Stripe via Play Store billing or direct (enterprise)

---

## 11. Technical Constraints

### Android Limitations (Non-rooted)

| Constraint | Impact | Workaround |
|---|---|---|
| WiFi scan throttling (4/2min) | Can't do rapid surveys | Use syslog for real-time data instead |
| No monitor mode | No raw 802.11 capture | PCAP import from laptop captures |
| No promiscuous mode | Can't sniff other clients' traffic | Syslog shows all client events |
| Background execution limits | Syslog receiver may be killed | Foreground service with notification |
| Battery drain | AI analysis is CPU-intensive | Batch analysis, configurable polling interval |

### Root-Enhanced Features (Optional)

| Feature | Requires | Benefit |
|---|---|---|
| Unlimited WiFi scanning | Root + custom driver | Rapid site surveys |
| Monitor mode capture | Root + compatible chipset | Live 802.11 frame capture |
| Packet injection | Root + compatible chipset | Deauth testing (authorized only) |

### OpenClaw Constraints

| Constraint | Impact | Mitigation |
|---|---|---|
| Memory (384MB NODE_OPTIONS) | Large log analysis may be slow | Chunk large files, batch processing |
| Single model at a time | Can't run parallel analyses | Queue system in app |
| API rate limits (OpenRouter) | Cost scales with usage | Cache responses, batch similar queries |
| Cold start latency | First analysis after idle is slow | Keep-alive heartbeat |

---

## 12. MVP Scope

### What's In (v0.1.0)

1. **WiFi Scanner** — Scan, display, signal graph, channel map
2. **Syslog Receiver** — UDP listener, raw event display, basic filtering
3. **Cisco WLC Parser** — Parse Cisco 9800/AireOS syslog format (most common)
4. **Roaming Timeline** — Visual timeline from syslog events
5. **OpenClaw Quick Triage** — Tap an event → AI explains it
6. **Log File Import** — Paste controller debug output
7. **Basic Reporting** — Export session as text/JSON
8. **Setup Wizard** — Guided OpenClaw connection setup

### What's Out (v0.1.0)

- Aruba/Meraki/Ruckus/Juniper parsers (v0.2)
- PCAP import (v0.2)
- Deep root cause analysis (v0.2)
- SpookyJuice cloud sync (v0.3)
- Fleet dashboard (v0.3)
- Play Store distribution (v0.3)
- Enterprise tier / SSO (v0.4)
- Root-enhanced features (v0.5)
- iOS port (v1.0+)

### MVP Success Criteria

1. Engineer can point Cisco WLC syslog at phone and see live events within 30 seconds
2. Tapping an event returns useful AI analysis within 5 seconds
3. Roaming timeline correctly visualizes a client's AP-to-AP path
4. App works fully offline (except AI features which need OpenClaw)
5. Setup wizard gets a new user from zero to working in under 45 minutes

---

## 13. Future Roadmap

| Version | Milestone | Key Features |
|---|---|---|
| **v0.1.0** | MVP | WiFi scanner, syslog receiver, Cisco parser, basic AI triage |
| **v0.2.0** | Multi-vendor | Aruba + Meraki parsers, PCAP import, deep RCA, client journey tracker |
| **v0.3.0** | Cloud | SpookyJuice sync, fleet dashboard, Play Store launch |
| **v0.4.0** | Enterprise | SSO, multi-user, API access, advanced reporting |
| **v0.5.0** | Power User | Root-enhanced features, site survey mode, heatmap overlay |
| **v1.0.0** | Platform | iOS port, third-party integrations, marketplace for custom parsers |

---

## References

- [WiFi Diagnostic Tools Market Research](../research/2026-03-09-wifi-diagnostic-tools-market-research.md)
- [Three-Repo Architecture Design](2026-03-08-three-repo-architecture-design.md)
- [OpenClaw Pixel 10a Install Guide](../../INSTALL-GUIDE.md)
- [OpenClaw Skills/Memory Research](../research/2026-03-08-openclaw-skills-memory-config-research.md)
