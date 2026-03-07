# Hero Diagram Specification

> Render-ready Mermaid diagrams for README and docs.
> Can also be exported to SVG/PNG for social previews.

---

## 1. Architecture Overview (for README)

```mermaid
graph TB
    subgraph OPERATOR["Operator (You)"]
        MAC["Mac / Laptop"]
        BROWSER["Browser Canvas UI"]
    end

    subgraph NETWORK["Encrypted Network"]
        TAILSCALE["Tailscale Mesh VPN<br/>100.x.y.z stable IP"]
        SSH["SSH Tunnel<br/>Port 18789 forward"]
    end

    subgraph PIXEL["Pixel 10a ($349)"]
        TERMUX["Termux<br/>Linux userspace"]
        SSHD["sshd :8022"]
        GW["OpenClaw Gateway<br/>323 MB RSS | 0% idle CPU"]
        WS["WebSocket Server<br/>:18789 loopback"]
        CANVAS["Canvas Web UI"]
    end

    subgraph CLOUD["Cloud Inference (OpenRouter)"]
        HAIKU["Claude 3.5 Haiku<br/>$0.25/1M tokens"]
        SONNET["Claude Sonnet 4.5<br/>$3/1M tokens"]
        OPUS["Claude Opus 4.6<br/>$15/1M tokens"]
        GEMINI["Gemini 2.5 Pro<br/>$1.25/1M tokens"]
    end

    MAC -->|ssh -L 18789| SSH
    SSH --> SSHD
    SSHD --> TERMUX
    BROWSER -->|http://127.0.0.1:18789| WS
    TERMUX --> GW
    GW --> WS
    GW --> CANVAS
    GW -->|HTTPS API calls| HAIKU
    GW -->|HTTPS API calls| SONNET
    GW -->|HTTPS API calls| OPUS
    GW -->|HTTPS API calls| GEMINI
    MAC -.->|Tailscale| TAILSCALE
    PIXEL -.->|Tailscale| TAILSCALE

    style PIXEL fill:#1a1a2e,stroke:#39ff14,stroke-width:2px,color:#e2e8f0
    style CLOUD fill:#0e0e1a,stroke:#8b5cf6,stroke-width:2px,color:#e2e8f0
    style OPERATOR fill:#12121f,stroke:#22d3ee,stroke-width:2px,color:#e2e8f0
    style NETWORK fill:#111120,stroke:#f97316,stroke-width:1px,color:#94a3b8
```

---

## 2. Trust Boundaries (for docs/threat-model.md)

```mermaid
graph LR
    subgraph TRUST_LOCAL["Trust Boundary: Local Device"]
        GW["Gateway<br/>loopback only"]
        CONFIG["Config + Keys<br/>~/.openclaw/"]
        TERMUX["Termux sandbox"]
    end

    subgraph TRUST_ENCRYPTED["Trust Boundary: Encrypted Transit"]
        SSH["SSH Tunnel<br/>ed25519 key auth"]
        TS["Tailscale<br/>WireGuard mesh"]
    end

    subgraph TRUST_CLOUD["Trust Boundary: Third-Party Cloud"]
        OR["OpenRouter API<br/>HTTPS + API key"]
        AI["AI Model Inference<br/>Anthropic / Google / etc."]
    end

    subgraph UNTRUSTED["Untrusted"]
        INTERNET["Public Internet"]
        CARRIER["Cellular Carrier"]
    end

    GW -->|loopback| SSH
    SSH -->|encrypted| TS
    TS -->|encrypted| OR
    OR -->|HTTPS| AI
    TS -.->|traverses| INTERNET
    TS -.->|traverses| CARRIER

    style TRUST_LOCAL fill:#0a2e0a,stroke:#39ff14,stroke-width:2px,color:#e2e8f0
    style TRUST_ENCRYPTED fill:#1a1a3e,stroke:#22d3ee,stroke-width:2px,color:#e2e8f0
    style TRUST_CLOUD fill:#2e1a0a,stroke:#f97316,stroke-width:2px,color:#e2e8f0
    style UNTRUSTED fill:#2e0a0a,stroke:#ef4444,stroke-width:1px,color:#94a3b8
```

---

## 3. Progression Roadmap (for ROADMAP.md)

```mermaid
gantt
    title OpenClaw Android Edge — Roadmap
    dateFormat YYYY-MM
    axisFormat %b %Y

    section Phase 1 — Foundation
    Install Guide           :done, p1a, 2026-03, 2026-03
    SSH + Tailscale         :done, p1b, 2026-03, 2026-03
    Gateway Optimization    :done, p1c, 2026-03, 2026-03
    Benchmark Script        :done, p1d, 2026-03, 2026-03

    section Phase 2 — Public Launch
    README + Docs           :active, p2a, 2026-03, 2026-03
    Social Launch Kit       :active, p2b, 2026-03, 2026-03
    Newsletter Issue #2     :active, p2c, 2026-03, 2026-03
    GitHub Public Repo      :p2d, 2026-03, 2026-04

    section Phase 3 — Channels
    WhatsApp Integration    :p3a, 2026-04, 2026-05
    Telegram Integration    :p3b, 2026-04, 2026-05
    Discord Integration     :p3c, 2026-04, 2026-05

    section Phase 4 — Fleet
    Multi-device Support    :p4a, 2026-05, 2026-07
    Auto-start on Boot      :p4b, 2026-05, 2026-06
    Health Monitoring        :p4c, 2026-05, 2026-06

    section Phase 5 — Edge AI
    Local Inference         :p5a, 2026-07, 2026-09
    Sensor Integration      :p5b, 2026-07, 2026-09
    Multi-agent Relay       :p5c, 2026-08, 2026-10
```

---

## 4. Cost Comparison (for README / social)

```mermaid
xychart-beta
    title "2-Year Total Cost: Phone vs Cloud VM"
    x-axis ["6 months", "12 months", "18 months", "24 months"]
    y-axis "Total Cost ($)" 0 --> 1200
    bar [409, 469, 529, 589]
    bar [330, 600, 870, 1140]
    legend ["Pixel 10a Edge Node", "Cloud VM (GCP e2-medium)"]
```

---

## Social Preview Image Spec

For the GitHub social preview (1280x640):

**Layout:**
- Dark background (#08080f)
- Left side: Pixel 10a device outline with terminal text
- Right side: Architecture flow arrows to cloud
- Top: "OpenClaw on Android" in bold
- Bottom: "Always-on AI edge node | $349 | No root required"
- Brand: spookyjuice.ai watermark bottom-right

**Colors:**
- Green (#39ff14) for terminal/tech elements
- Purple (#8b5cf6) for AI/cloud elements
- Cyan (#22d3ee) for network elements
- Orange (#f97316) for cost/value callouts

**Tools to render:**
- Figma, Excalidraw, or Canva
- Export as PNG 1280x640 for GitHub social preview
- Export as 1200x628 for X/LinkedIn cards
