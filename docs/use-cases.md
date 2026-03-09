# Use Cases: OpenClaw on Pixel 10a

> **Author:** Brian Gorzelic / AI Aerial Solutions
> **Last Updated:** March 2026
> **Device:** Google Pixel 10a -- Tensor G4, 8GB RAM, $349

These are real-world deployment patterns for an always-on AI gateway running on a Pixel 10a. Each use case describes a real problem, explains how the architecture solves it, provides configuration or command examples where applicable, and is honest about current limitations.

The system described here is a Node.js WebSocket gateway running in Termux on the phone, relaying to cloud inference via OpenRouter. The phone performs no local inference. Gateway RSS is 323 MB, idle CPU is 0%, HTTP latency is 65ms on loopback. Remote access is via SSH tunnel over Tailscale. The gateway binds to loopback only on port 18789. Monthly operating cost is $5-15 in API tokens.

For architecture details, see [docs/architecture.md](./architecture.md). For installation, see [INSTALL-GUIDE.md](../INSTALL-GUIDE.md). For performance tuning, see [OPTIMIZATION-GUIDE.md](../OPTIMIZATION-GUIDE.md).

---

## Table of Contents

1. [24/7 Personal AI Assistant](#1-247-personal-ai-assistant)
2. [Mobile Command Center](#2-mobile-command-center)
3. [Field Data Collection](#3-field-data-collection)
4. [Home Automation Hub](#4-home-automation-hub)
5. [Scheduled Content Pipeline](#5-scheduled-content-pipeline)
6. [Multi-Node Relay](#6-multi-node-relay)
7. [Privacy-First Personal AI](#7-privacy-first-personal-ai)
8. [Development Companion](#8-development-companion)
9. [Network Intelligence Sensor](#9-network-intelligence-sensor)

---

## 1. 24/7 Personal AI Assistant

### Why It Matters

You want to message an AI assistant the same way you message a person -- through Telegram, WhatsApp, or Signal -- and get a response in seconds, any time of day or night. Browser-based AI tools (ChatGPT, Claude.ai) require opening a laptop, navigating to a URL, and managing sessions manually. They do not integrate with the communication channels you already have open on your phone and watch.

A phone-based gateway gives you AI access through the messaging apps you already use, with persistent session memory that survives across conversations and device switches.

### How It Works Architecturally

OpenClaw's channel connectors maintain persistent connections to messaging platforms. When a message arrives (via Telegram's long-polling API, WhatsApp Business webhook, etc.), the gateway routes it to the active agent session, appends it to the conversation context, sends the full context to the configured model via OpenRouter, and relays the response back through the same channel.

```
Telegram/WhatsApp message
  --> Channel connector (in-process)
    --> Agent session (context + memory)
      --> HTTPS POST to api.openrouter.ai
        --> Model response
          --> Reply via same channel
```

Session state is stored in `~/.openclaw/` on the phone and persists across gateway restarts. The default model is `openrouter/anthropic/claude-3.5-haiku`, which handles most conversational tasks at ~$0.25 per million input tokens.

### Example Configuration

Telegram bot setup (after creating a bot via @BotFather):

```bash
# Set the Telegram bot token
openclaw config set channels.telegram.token "YOUR_BOT_TOKEN"

# Enable the Telegram channel
openclaw config set channels.telegram.enabled true

# Restart the gateway
openclaw gateway restart
```

From any device, message your Telegram bot:

> "What's the weather forecast for San Francisco this week?"

The gateway processes the message, calls the configured weather tool (or asks the model to reason about it), and replies in the Telegram chat within 2-5 seconds.

### Limitations and Caveats

- **Channel connectors are planned, not shipped.** As of March 2026, Telegram and WhatsApp channel integration is on the roadmap (Issue #3). The gateway currently operates through the Canvas web UI and SSH. The architecture supports channels; the connectors are not yet wired up.
- **WhatsApp Business API requires a Meta developer account** and phone number verification. It is not as simple as Telegram's bot API.
- **Message latency is 1-5 seconds**, dominated by model inference time at the provider. The phone adds under 100ms.
- **No voice messages yet.** Audio transcription via Whisper or similar is possible but not integrated.
- **Context window limits apply.** Long conversations are managed by OpenClaw's safeguard compaction mode, but very long exchanges will lose early context.

---

## 2. Mobile Command Center

### Why It Matters

You are away from your desk -- at a conference, on a flight, at a client site -- and a production server starts throwing errors. You need to check logs, inspect service status, and possibly restart a process. Your laptop is in your bag or at the hotel. Your phone is in your pocket.

With the gateway running on the phone and accessible via SSH over Tailscale, you can connect from any device on your tailnet (including another phone or a borrowed laptop), ask the AI to inspect your infrastructure, and get actionable summaries without parsing raw log output yourself.

### How It Works Architecturally

You SSH into the phone from any device on your Tailscale mesh network. The gateway has access to a shell tool that can execute commands, including SSH commands to other servers also on the tailnet. The model interprets your natural-language request, constructs the appropriate commands, executes them via the shell tool, and summarizes the results.

```
Your device (any)
  --> SSH to Pixel 10a (via Tailscale, port 8022)
    --> OpenClaw Canvas UI (localhost:18789 via port forward)
      --> You: "Check if the API service is healthy on staging"
        --> Gateway shell tool: ssh staging "systemctl status api-service"
          --> Model summarizes the output
```

The phone acts as a jump host with AI augmentation. It can reach any server on your tailnet, and the model can interpret the output of system commands far faster than you can scan raw logs on a phone screen.

### Example Commands

SSH config on any client device:

```
Host termux
    HostName 100.x.y.z        # Tailscale stable IP
    Port 8022
    User u0_a314
    IdentityFile ~/.ssh/id_ed25519
    LocalForward 18789 127.0.0.1:18789
    IdentitiesOnly yes
```

Connect and query:

```bash
ssh termux
# Open browser to http://127.0.0.1:18789/__openclaw__/canvas/
```

In the Canvas:

> "SSH into the staging server and show me the last 50 lines of the API service log. Summarize any errors."

The gateway runs `ssh staging "journalctl -u api-service -n 50 --no-pager"`, feeds the output to the model, and returns a structured summary: error count, error types, timestamps, and suggested actions.

For deeper investigation:

> "Check the database connection pool on staging. Is it exhausted?"

The gateway runs the appropriate diagnostic commands (`pg_stat_activity` query, connection count check) and reports back.

### Limitations and Caveats

- **Shell tool access is powerful and dangerous.** The gateway can execute any command the Termux user can run. There are no built-in guardrails preventing destructive commands. Use with awareness.
- **SSH keys must be pre-configured.** The phone needs SSH key access to your infrastructure servers. Store keys in `~/.ssh/` on the Termux filesystem.
- **Latency stacks.** Phone-to-OpenRouter for inference (1-4s) plus phone-to-server for command execution (depends on network). Expect 3-10 seconds for a full inspect-and-summarize cycle.
- **Not a replacement for proper monitoring.** This is for ad-hoc investigation when you are away from your workstation. Use Datadog, Grafana, or PagerDuty for continuous monitoring and alerting.
- **Cellular bandwidth matters.** Large log dumps over a cellular connection can be slow. Ask the model to filter or summarize rather than dumping raw output.

---

## 3. Field Data Collection

### Why It Matters

Field workers -- site inspectors, surveyors, agricultural technicians, drone operators -- collect data using paper forms, disconnected apps, or manual spreadsheet entry after returning to the office. The gap between observation and structured data creates errors, delays, and lost context.

The Pixel 10a is already a sensor array: 50+ MP camera with OIS, GPS with meter-level accuracy, microphone, barometer, accelerometer. Pairing these sensors with AI interpretation via OpenClaw means you can photograph a piece of equipment, and the AI extracts structured data from the image -- condition, serial number, defect classification -- and writes it directly to a Google Sheet or local database. No manual transcription.

### How It Works Architecturally

OpenClaw skills wrap Termux:API commands (`termux-camera-photo`, `termux-location`, `termux-microphone-record`) to access the phone's hardware sensors. A capture workflow chains these together:

```
Trigger (Telegram message, voice command, or scheduled)
  --> termux-camera-photo (captures image)
  --> termux-location (reads GPS coordinates)
  --> Send image + coordinates + prompt to vision-capable model
      (e.g., openrouter/anthropic/claude-sonnet-4-5 or openrouter/google/gemini-2.5-pro)
  --> Model returns structured JSON
  --> Append to Google Sheets via Sheets API skill
  --> Confirm via Telegram with summary
```

The model does the heavy lifting: reading meter values, identifying equipment conditions, classifying defects, extracting text from documents. The phone provides the raw sensor data and handles the orchestration.

### Example Workflow

Solar panel inspection using Telegram as the interface:

```
You: "Start inspection: Array B, Section 3"
Bot: "Inspection started. GPS: 40.7128, -74.0060. Timestamp: 2026-03-07T14:23:11Z.
      Send photos with /photo or type observations."

You: /photo
[Camera captures image, sends to vision model]

Bot: {
  "panel_id": "B3-047",
  "condition": "soiling",
  "severity": "moderate",
  "estimated_efficiency_loss": "8-12%",
  "recommendation": "clean within 30 days",
  "gps": [40.7128, -74.0060]
}
Appended to Sheet: "Array-B Inspections" row 48.

You: "Generate summary for Section 3"
Bot: "Section 3 summary: 12 panels inspected. 2 moderate soiling, 1 minor crack,
      9 good condition. Estimated section efficiency: 94%. Full report attached."
```

### Limitations and Caveats

- **Termux:API must be installed separately** from the Termux app. It is a companion APK that provides the bridge between Termux and Android's sensor APIs. Without it, `termux-camera-photo` and `termux-location` do not exist.
- **Camera access from Termux is functional but limited.** The Termux camera interface does not support all camera modes (no Night Sight, no HDR+). Image quality is good but not what you get from the native camera app.
- **Vision model costs are higher.** Sending images to the model uses significantly more tokens than text-only queries. A single image analysis with Claude Sonnet might cost $0.01-0.05 depending on image size and prompt length. Budget accordingly for high-volume inspections.
- **GPS accuracy depends on conditions.** Indoors or in urban canyons, GPS accuracy degrades. The phone's location API uses WiFi and cell tower triangulation as fallbacks, but precision varies.
- **Offline operation is not supported.** The phone must have cellular or WiFi connectivity to reach OpenRouter for inference. Captured images can be queued locally and processed when connectivity returns, but this requires custom skill development.
- **This workflow is not yet packaged as a ready-to-use skill.** The individual components (camera, GPS, model, Sheets API) all work. Chaining them into a polished inspection workflow requires configuration. Expect to spend time on prompt engineering for your specific domain.

---

## 4. Home Automation Hub

### Why It Matters

Smart home control through dedicated apps (Hue, Nest, Ring) requires opening the right app for the right device. Voice assistants (Alexa, Google Home) work well for simple commands but struggle with conditional logic, multi-step sequences, and context ("do what I said yesterday"). Home Assistant provides power and flexibility but has a learning curve and a UI designed for dashboards, not conversation.

A natural-language gateway layered on top of Home Assistant (or direct device APIs) lets you control your home through any messaging app with commands like "set the house up for movie night" -- and the AI figures out which devices to adjust and how.

### How It Works Architecturally

OpenClaw skills wrap the Home Assistant REST API or direct device APIs (Philips Hue, LIFX, Nest, etc.). The phone sits on your home network and can reach local devices at `192.168.x.x` without NAT traversal or cloud routing.

```
Telegram/WhatsApp message: "Good night"
  --> Gateway interprets intent
    --> HTTPS POST to api.openrouter.ai (intent classification + action planning)
      --> Model returns tool calls:
        1. home_assistant.call_service("scene.turn_on", entity_id="scene.goodnight")
        2. home_assistant.call_service("lock.lock", entity_id="lock.front_door")
        3. home_assistant.call_service("climate.set_temperature", temperature=67)
    --> Gateway executes each tool call against Home Assistant API
      --> Confirms: "Good night mode activated. Front door locked. Thermostat set to 67F."
```

The only cloud hop is the inference call to determine intent and construct the API requests. The actual device control calls are local HTTP requests from the phone to Home Assistant on the same network.

### Example Configuration

Home Assistant skill configuration in `~/.openclaw/openclaw.json`:

```json
{
  "skills": {
    "home_assistant": {
      "url": "http://192.168.1.100:8123",
      "token": "YOUR_LONG_LIVED_ACCESS_TOKEN",
      "entities": ["light.*", "climate.*", "lock.*", "scene.*", "cover.*"]
    }
  }
}
```

Example commands via any messaging channel:

- "Turn on the living room lights at 40% warm white"
- "Is the garage door open?"
- "Set the thermostat to 72 when I get home" (requires presence detection integration)
- "Movie night" (triggers a scene: dim lights, close blinds, set TV input)

### Limitations and Caveats

- **Home Assistant integration is not built into OpenClaw.** You need to write or configure skills that wrap the HA REST API. This is straightforward but requires familiarity with both OpenClaw skills and Home Assistant's API.
- **The phone must be on the same network as Home Assistant** for local API access. If you are away from home and send a command via Telegram, the phone (on home WiFi) can still reach HA locally. But if the phone is also away from home (e.g., you took it with you), it cannot reach local devices without a VPN back to the home network.
- **Latency for device control is 2-5 seconds** because of the inference round trip. For time-critical commands (turning off an alarm), this is slower than a dedicated app or voice assistant.
- **The AI can misinterpret ambiguous commands.** "Turn off everything" might include devices you did not intend. Use explicit entity naming or define safe defaults in your skill configuration.
- **No built-in presence detection.** The phone does not automatically know when you arrive home. This requires integration with Home Assistant's presence detection or Tailscale's connectivity status as a proxy.

---

## 5. Scheduled Content Pipeline

### Why It Matters

Recurring information tasks consume time disproportionate to their value: checking email and calendar every morning, compiling weekly status reports from git commits, monitoring system alerts throughout the day. These tasks follow predictable patterns and can be automated with a cron-like scheduler that has access to AI for summarization and formatting.

An always-on phone gateway can execute these workflows on schedule without a laptop being open, delivering results to your preferred messaging channel.

### How It Works Architecturally

OpenClaw's cron system (planned) triggers skill sequences on a schedule. Each scheduled task is a message sent to the gateway's agent session at the specified time, which the model processes using available tools.

```
Cron trigger (e.g., 8:00 AM daily)
  --> Gateway receives scheduled message
    --> Agent calls tools: calendar API, email API, weather API
      --> Model composes morning briefing
        --> Sends via Telegram/WhatsApp/Slack
```

For content publishing workflows (the use case that drives this project), the pipeline is documented in [PUBLISH-PIPELINE.md](../PUBLISH-PIPELINE.md). The gateway reads source content, generates platform-specific versions (X thread, LinkedIn post, Reddit post, HN submission, Discord announcement), and can post to platforms with API access.

### Example Workflows

**Morning briefing (daily, 7:30 AM):**

```bash
openclaw cron add --at "7:30 AM" --channel telegram \
  --message "Morning briefing:
    1. Today's calendar events (flag conflicts)
    2. Unread emails from VIPs (Sarah, Apex client, engineering leads)
    3. Weather forecast for my location
    4. Any CI/CD failures on main branch since yesterday
    Format as a concise bullet list. Skip low-priority items."
```

**Weekly status report (Fridays, 4:00 PM):**

```bash
openclaw cron add --at "Friday 4:00 PM" --channel slack \
  --message "Generate weekly status report:
    1. Git commits on main this week (group by author)
    2. PRs merged (list with one-line summaries)
    3. Open issues created vs closed
    4. Deployment count
    Format for pasting into Slack #engineering channel."
```

**Monitoring alert triage (every 2 hours):**

```bash
openclaw cron add --every "2h" --channel telegram \
  --message "Check PagerDuty and Grafana for active alerts.
    Ignore: disk space warnings under 80%, known flaky test alerts.
    Report: anything new, anything escalated, anything unacknowledged.
    If nothing actionable, reply 'All clear' and skip the details."
```

### Limitations and Caveats

- **Cron scheduling is planned, not shipped.** As of March 2026, this is on the roadmap (Issue #3). You can simulate it with system-level cron in Termux (`crontab -e`) calling `curl` against the gateway, but native OpenClaw cron is not yet available.
- **API access to email, calendar, and monitoring services requires separate configuration.** Each service needs OAuth tokens or API keys stored in the gateway's environment. Google Calendar and Gmail require OAuth2 with refresh tokens, which adds setup complexity.
- **Scheduled tasks consume API tokens even when you don't read the output.** A morning briefing that costs $0.01 is negligible; a monitoring check every 2 hours that pulls large log volumes could add up. Tune prompts to minimize token usage.
- **Time zone handling is manual.** Termux uses the phone's system time zone. If you travel, scheduled tasks fire at the local time of the phone, not your current location.
- **Content publishing is partially manual.** Some platforms (Hacker News) have no posting API. Others (Beehiiv) require paid tiers for programmatic access. The pipeline generates the content; you may still need to paste and post manually for some channels.

---

## 6. Multi-Node Relay

### Why It Matters

A single phone is useful. A phone alongside your Mac or a VPS creates a distributed system where each node contributes what it does best: the phone provides always-on availability, cellular failover, and physical sensors; the Mac provides compute power for heavy tasks; the VPS provides a stable public IP and high-bandwidth connectivity.

This matters when you want redundancy (if one node goes down, others keep working) or when different tasks benefit from different hardware (the phone captures photos for AI analysis while the Mac runs compute-intensive local models).

### How It Works Architecturally

Each node runs its own OpenClaw gateway instance. Nodes discover each other via Tailscale's stable addressing and can forward tasks between themselves.

```
Phone (Pixel 10a)                    Mac (Apple Silicon)
  - Always-on availability            - Local inference (llama.cpp)
  - Cellular failover                  - Heavy compute tasks
  - Camera/GPS/sensors                 - Large context windows
  - Telegram/WhatsApp channels         - IDE integration
  - Gateway: 100.x.y.1:18789          - Gateway: 100.x.y.2:18789

                    VPS (Optional)
                      - Public IP for webhooks
                      - High-bandwidth API calls
                      - Gateway: 100.x.y.3:18789
```

Task routing between nodes can be configured so that:
- Simple queries stay on the phone (Haiku via OpenRouter)
- Code analysis gets forwarded to the Mac (local Sonnet or Opus)
- Webhook reception happens on the VPS (public IP, no Tailscale Funnel needed)
- Sensor tasks (photo capture, location) always go to the phone

### Example Configuration

On the phone, configure awareness of other nodes:

```json
{
  "discovery": {
    "mdns": { "mode": "off" },
    "peers": [
      {
        "name": "mac",
        "url": "http://100.x.y.2:18789",
        "capabilities": ["local-inference", "heavy-compute"]
      },
      {
        "name": "vps",
        "url": "http://100.x.y.3:18789",
        "capabilities": ["public-ip", "webhooks"]
      }
    ]
  }
}
```

From any device on the tailnet, the phone acts as the primary entry point. If it determines a task needs more compute than cloud inference provides, it can delegate to the Mac.

### Limitations and Caveats

- **Multi-node orchestration is exploratory.** OpenClaw supports the concept of peer discovery and task forwarding, but the routing logic for automatically dispatching tasks to the right node is not mature. Expect to configure this manually.
- **mDNS discovery does not work on Android.** Termux cannot send multicast packets (Android restricts multicast to privileged sockets). Peer discovery must use explicit configuration, not automatic network discovery. This is why the gateway config disables mDNS (`discovery.mdns.mode: off`).
- **Network partitions break the relay.** If the phone loses connectivity to the Mac (home internet goes down but cellular stays up), tasks that require the Mac will fail. Design workflows with graceful fallback.
- **State synchronization between nodes is not automatic.** Conversation history on the phone is not replicated to the Mac. Each node has its own session state. A conversation started on one node must continue on that node.
- **Cost and complexity increase linearly** with each node. Each node needs its own OpenRouter key (or shared key), Tailscale setup, and monitoring. For most users, a single phone node is sufficient.

---

## 7. Privacy-First Personal AI

### Why It Matters

When you use ChatGPT or Claude.ai through a browser, your conversation data passes through the provider's infrastructure, is subject to their data retention policies, and may be used for model training (depending on your plan and settings). For sensitive personal data -- health questions, financial planning, legal research, private journaling -- this data exposure is a legitimate concern.

With an OpenClaw gateway on your phone, the architecture is different: conversation history, session state, tool results, and API keys never leave the device. The only data that crosses the network boundary is the conversation context sent to the model provider for each inference call, and the model's response coming back.

### How It Works Architecturally

```
Data that stays on the phone (never leaves):
  - ~/.openclaw/          Session state, conversation history, memory index
  - ~/.openclaw/.env      API keys, tokens, credentials
  - Tool results          Files read, commands executed, API responses
  - Gateway config        Model selection, channel config, skill definitions

Data that leaves the phone (encrypted, per-request):
  - Conversation context  --> HTTPS to api.openrouter.ai --> Model provider
  - Model response        <-- HTTPS from api.openrouter.ai
```

The trust boundary diagram in [docs/architecture.md](./architecture.md) maps this precisely. The gateway binds to loopback only (`127.0.0.1:18789`), so nothing on the local network can reach it. All remote access goes through the SSH tunnel over Tailscale's WireGuard encryption.

For maximum privacy, you can select models with explicit no-data-retention policies:

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "openrouter/meta-llama/llama-3.1-70b"
      }
    }
  }
}
```

Meta's Llama models via OpenRouter carry no data retention by the provider. Anthropic and OpenAI have their own retention policies (typically 30 days for API usage, no training on API data).

### What This Architecture Protects Against

| Threat | Protection |
|--------|-----------|
| Provider reads your history | History stays on phone; provider sees only per-request context |
| Network eavesdropping | Tailscale (WireGuard) for SSH; TLS 1.3 for OpenRouter API |
| Local network attack | Gateway binds to loopback only; no exposed ports |
| Device theft | Android full-disk encryption (enabled by default on Pixel) |
| Provider data breach | Your history is not in their database; only transient request logs |

### What This Architecture Does NOT Protect Against

| Threat | Why Not |
|--------|---------|
| Model provider sees each request | Inference requires sending context to the cloud. This is inherent to the relay architecture. |
| OpenRouter sees your API traffic | OpenRouter routes your requests. They see request metadata and can log content per their privacy policy. |
| Compromised phone | If the phone is rooted or infected with malware, all local data is exposed. |
| Legal compulsion | A subpoena to OpenRouter or the model provider could yield request logs. |

### Limitations and Caveats

- **This is not air-gapped AI.** Every inference call sends your conversation context to a cloud provider. If your threat model requires that no data leave the device at all, you need local inference (llama.cpp on the Tensor G4), which is on the roadmap but not the default configuration.
- **OpenRouter is a man-in-the-middle by design.** It routes your requests to model providers. Their [privacy policy](https://openrouter.ai/privacy) governs what they log and retain. If this is unacceptable, use direct provider APIs instead.
- **Conversation context includes the full history** up to the compaction limit. If you discuss a sensitive topic in message 3 and ask about the weather in message 20, the sensitive topic is still in the context sent with message 20 (until compaction removes it).
- **Android itself is not privacy-maximizing.** Google services on the Pixel collect telemetry. This guide does not cover de-Googling the device. The privacy boundary described here is specifically about AI conversation data, not general phone telemetry.
- **Backups can leak data.** If the phone's data is backed up to Google (default behavior), `~/.openclaw/` contents may be included. Disable cloud backup for Termux data if this is a concern.

---

## 8. Development Companion

### Why It Matters

AI coding assistants in IDEs (Copilot, Cursor, Claude in VS Code) are powerful but ephemeral: they lose context when you close the IDE, switch projects, or move to a different machine. If you work across multiple computers (desktop at home, laptop at the office, tablet on the couch), each session starts fresh.

A gateway on the phone provides a neutral, always-available development companion. The session persists across days and device switches. You can start debugging a problem on your desktop, continue on your laptop at a coffee shop, and pick up where you left off from your phone on the train -- same context, same conversation history.

### How It Works Architecturally

You SSH into the Pixel 10a from any machine and open the Canvas UI via the port-forwarded connection. The assistant has access to shell tools (command execution), file tools (read/write files), and web search. It can read code, run tests, check git status, and explain error messages.

```
Any machine (home desktop, work laptop, borrowed computer)
  --> SSH to Pixel 10a via Tailscale (port 8022)
    --> Port forward 18789
      --> Canvas UI at localhost:18789
        --> Persistent session with full conversation history
```

For code-heavy work, you would typically switch the model from the default Haiku to a more capable model:

```bash
# In the Canvas UI or via config
openclaw config set agents.defaults.model.primary openrouter/anthropic/claude-sonnet-4-5
```

The phone's role is persistence and availability, not computation. It maintains the session state while the model provider does the reasoning.

### Example Workflow

**Debugging across devices:**

Morning, desktop at home:

> "I'm getting a KeyError in `/src/pipeline/transform.py` around line 80. The input data comes from the Salesforce API. Can you read the file and figure out what's happening?"

The assistant reads the file via the file tool, identifies that the Salesforce API sometimes omits `LastModifiedDate` for archived records, and suggests using `.get()` with a default value.

> "Run the tests in `/tests/test_transform.py` and tell me if the fix worked."

The assistant executes `python -m pytest tests/test_transform.py -v` via the shell tool and reports results.

Afternoon, laptop at the office:

> "Where did we leave off this morning?"

The assistant summarizes the debugging session and the applied fix, because the session history is on the phone, not on the desktop that was used earlier.

**Git operations from anywhere:**

> "What's the diff on the current branch? Summarize the changes and check if the commit messages follow conventional commits."

The assistant runs `git diff`, `git log`, inspects the output, and flags any commit messages that don't follow the `feat:/fix:/refactor:` convention.

**CI monitoring:**

> "Check the GitHub Actions status for the main branch. Are all workflows green?"

The assistant uses the GitHub API (via configured tool or shell `curl`) to check workflow status and reports back.

### Limitations and Caveats

- **File access is limited to the phone's filesystem** by default. The assistant can read and write files in the Termux environment. To work on files from your desktop or a remote server, you need to either clone repos to the phone or use SSH tools to access remote filesystems.
- **Test execution happens on the phone.** Python tests will run, but they use the phone's Termux environment, which may not match your development environment exactly (different Python version, missing system dependencies, no GPU). For anything beyond basic unit tests, delegate execution to the actual development machine via SSH.
- **The assistant does not have IDE integration.** It cannot place cursors, highlight code, or interact with your editor. It operates through text: reading files, suggesting changes, executing commands. You apply the changes yourself.
- **Model costs increase for development work.** Code analysis and debugging require Sonnet-class models ($3/M input tokens vs $0.25/M for Haiku). A heavy debugging session with multiple file reads and test runs might cost $0.50-2.00. This is still far cheaper than a Copilot Business subscription ($19/month) but is worth tracking.
- **Large codebases exceed context windows.** You cannot send an entire codebase to the model. The assistant works best when pointed at specific files and functions. For architectural questions spanning many files, break the query into targeted reads.
- **Latency is noticeable for rapid iteration.** Each round trip (your question --> inference --> response) takes 2-10 seconds depending on the model and response length. For rapid debugging, this is slower than a locally-running assistant. The tradeoff is persistence and availability.

---

## 9. Network Intelligence Sensor

### Why It Matters

Understanding wireless network environments -- signal strength, interference patterns, coverage gaps, cellular tower quality -- traditionally requires expensive specialized equipment or enterprise-grade diagnostic software. A phone already has WiFi, cellular, and Bluetooth radios with APIs exposed through Termux:API. Combined with AI for analysis and pattern recognition, the Pixel 10a becomes a portable network diagnostic sensor.

This is the foundation of the [SIGNAL project](https://github.com/bgorzelic/SIGNAL) -- a network intelligence platform that runs as an OpenClaw skill on the same hardware described in this guide.

### How It Works Architecturally

Termux:API exposes Android's wireless subsystems as CLI commands. SIGNAL wraps these into structured data collection workflows:

```
Trigger (scheduled scan, manual command, or event-based)
  --> termux-wifi-scaninfo (all visible SSIDs, signal strength, frequency, security)
  --> termux-telephony-cellinfo (cell towers, signal level, network type)
  --> termux-location (GPS for geo-tagged measurements)
  --> Send structured data to model for analysis
      (pattern recognition, anomaly detection, coverage mapping)
  --> Store results in SQLite for historical comparison
  --> Report via Telegram/Canvas with recommendations
```

The phone's radios do passive scanning -- no monitor mode or special hardware required. WiFi scan results include SSID, BSSID, frequency, signal level (dBm), channel width, and security protocol for every visible access point.

### Example Data Collection

WiFi environment scan:

```bash
# Raw scan (returns JSON array of all visible networks)
termux-wifi-scaninfo

# Example output (truncated):
# [
#   {
#     "bssid": "aa:bb:cc:dd:ee:ff",
#     "ssid": "HomeNetwork",
#     "frequency": 5180,
#     "level": -42,
#     "channelWidth": 80,
#     "capabilities": "[WPA2-PSK-CCMP][RSN-PSK-CCMP][ESS]"
#   },
#   ...
# ]
```

Cellular environment:

```bash
# Cell tower info (returns JSON with tower details)
termux-telephony-cellinfo

# Device network info
termux-telephony-deviceinfo
```

Combined with GPS coordinates from `termux-location`, each scan creates a geo-tagged snapshot of the wireless environment.

### Use Cases Within This Use Case

1. **Home WiFi optimization** -- Walk through your house with the phone running periodic scans. Map signal strength by room. Identify dead zones and interference from neighboring networks.

2. **Site survey for new deployments** -- Before installing access points at a client site, survey existing RF conditions. The AI analyzes scan data and recommends AP placement based on existing interference and building layout.

3. **Cellular coverage mapping** -- Drive or walk a route with continuous cell tower logging. Build a coverage map showing signal quality, handoff points, and dead zones. Useful for fleet management or remote site assessment.

4. **Network security audit** -- Scan for rogue access points, open networks, or unexpected devices. The AI flags anomalies compared to a known-good baseline.

5. **Ongoing monitoring** -- Schedule periodic scans via cron. The AI compares current results to historical baselines and alerts on changes -- new networks appearing, signal degradation, or interference patterns.

### Limitations and Caveats

- **Termux:API sensor commands require foreground context.** They hang when called over SSH. Scans must be triggered locally on the phone, via OpenClaw (which has foreground context), or via Termux:Boot scheduled scripts.
- **WiFi scanning is passive only.** No monitor mode, no packet capture, no deauthentication. Android restricts raw wireless frame access without root. This limits analysis to what the standard scan API provides.
- **Scan frequency is throttled by Android.** Since Android 9, background WiFi scan frequency is limited to prevent battery drain. Foreground scans are unrestricted, but rapid-fire scanning from a background service may be throttled.
- **SIGNAL is early-stage.** The project has scaffolding (README, requirements, skill.json, src/) but is not yet a polished, installable skill. Expect to write Python code to chain the termux-api commands into useful workflows.
- **Cellular info varies by carrier and region.** Some carriers restrict what `termux-telephony-cellinfo` reports. Coverage mapping accuracy depends on the data your carrier exposes.

---

## Combining Use Cases

These use cases run simultaneously on the same gateway. The OpenClaw process handles all of them as different skill configurations and routing rules within one Node.js process at 323 MB RSS and 0% idle CPU.

A fully-configured gateway might:

- Deliver a morning briefing at 7:30 AM via Telegram (use case 5)
- Answer development questions from the Canvas UI during work hours (use case 8)
- Receive and process field inspection photos via Telegram (use case 3)
- Control home devices via WhatsApp (use case 4)
- Serve as a fallback infrastructure access point over cellular (use case 2)
- Keep all conversation history on-device (use case 7)
- Route simple queries to Haiku and complex ones to Sonnet via OpenRouter (use case 6, phone as primary node)
- Continuously monitor the wireless environment and alert on anomalies (use case 9)

All from one $349 phone, at ~$5-15/month in API tokens.

---

*For architecture details, see [docs/architecture.md](./architecture.md).*
*For installation instructions, see [INSTALL-GUIDE.md](../INSTALL-GUIDE.md).*
*For performance tuning and cost analysis, see [OPTIMIZATION-GUIDE.md](../OPTIMIZATION-GUIDE.md).*
