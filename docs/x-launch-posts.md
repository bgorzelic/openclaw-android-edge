# X Launch Posts

> Copy-paste ready. Two accounts, two angles.
> Repo: github.com/bgorzelic/openclaw-android-edge

---

## @bgorzelic (Personal — Builder Angle)

### Post 1 (Launch tweet — pin this)

```
I bought a $349 Pixel 10a and turned it into an always-on AI gateway.

323 MB RAM. 0% idle CPU. 65ms latency. Accessible from anywhere via Tailscale.

No root. No cloud VM. No monthly compute bill.

Full guide with every error I hit and how I fixed them:
github.com/bgorzelic/openclaw-android-edge
```

### Post 2 (Reply thread — technical meat)

```
What the phone actually runs:

• OpenClaw gateway in native Termux (not proot)
• SSH on port 8022 with key auth
• Tailscale for stable IP from any network
• Routes to Claude, GPT, Gemini via OpenRouter

The phone does zero inference. It's a relay. All the AI compute happens in the cloud at pay-per-token rates.
```

### Post 3 (Reply — cost argument)

```
Cost comparison over 2 years:

Phone: $349 hardware + $180 tokens = $529
Cloud VM: $0 hardware + $720 compute + $180 tokens = $900

The phone also has a battery (built-in UPS), LTE failover, camera, GPS, and mic.

A cloud VM has none of that.
```

### Post 4 (Reply — the hard part)

```
The hardest part wasn't installing OpenClaw.

It was fighting Android's 5 layers of battery optimization that kept killing the process:

• Doze
• App Standby
• Adaptive Battery
• CPU Freeze
• WiFi Sleep

Each one needs a separate ADB command to disable. All documented in the guide.
```

### Post 5 (Reply — CTA)

```
Everything is open source:

• 1,050-line install guide
• Optimization guide with benchmarks
• Threat model and security analysis
• Device compatibility guide
• Benchmark script you can run on your phone

github.com/bgorzelic/openclaw-android-edge

Built as part of @SpookyJuiceAI — subscribe at spookyjuice.ai for the deep dives.
```

---

## @SpookyJuiceAI (Brand — Product Angle)

### Post 1 (Launch tweet — pin this)

```
NEW: Run an AI gateway on a $349 phone.

We put OpenClaw on a Google Pixel 10a and documented everything — the failures, the fixes, the performance numbers.

323 MB RAM. Zero idle CPU. 65ms latency. $5-15/mo to run.

The complete guide is live:
github.com/bgorzelic/openclaw-android-edge
```

### Post 2 (Reply — why this matters)

```
Why does this matter?

A cloud VM costs $25-35/month just for compute. Over 2 years that's $960+.

A Pixel 10a costs $349 once. It has a battery, LTE, camera, GPS. It sits on your desk plugged into USB-C drawing 5 watts.

Edge AI doesn't need to be expensive. It needs to be documented.
```

### Post 3 (Reply — what's in the repo)

```
What's in the repo:

📋 11-phase install guide (1,050+ lines)
⚡ Performance optimization guide
🏗️ 7-layer architecture breakdown
🔒 537-line threat model with breach scenarios
📱 Device compatibility guide
📊 Automated benchmark script
🗺️ 6-phase roadmap

All open source. MIT licensed.
```

### Post 4 (Reply — the numbers)

```
Measured on a live Pixel 10a gateway:

┌──────────────┬──────────┐
│ Gateway RAM  │ 323 MB   │
│ CPU (idle)   │ 0.00%    │
│ HTTP latency │ 65ms avg │
│ Threads      │ 11       │
│ Storage      │ 641 MB   │
│ Monthly cost │ $5-15    │
└──────────────┴──────────┘

Not estimates. Not benchmarks from a dev machine.
Numbers from the actual phone running in production.
```

### Post 5 (Reply — newsletter CTA)

```
This is Issue #2 of The Persistent Ghost — our newsletter on AI infrastructure at the edge.

If a $349 phone can run a production AI gateway, what else is possible?

Subscribe for the deep dives: spookyjuice.ai

Star the repo: github.com/bgorzelic/openclaw-android-edge
```

---

## Timing Strategy

1. **@SpookyJuiceAI posts first** (brand account launches the content)
2. **@bgorzelic quote-tweets Post 1** with personal context ("I built this...")
3. **@bgorzelic posts the full personal thread** 30-60 min later
4. **@SpookyJuiceAI retweets** the personal thread
5. Post the Reddit/HN submissions 2-4 hours after X to let engagement build

## Hashtags (use sparingly, 1-2 per post max)

- #EdgeAI
- #SelfHosted
- #OpenSource
- #Android
- #AI
