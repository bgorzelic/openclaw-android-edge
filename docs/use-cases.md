# Use Cases: OpenClaw on Pixel 10a

> **Author:** Brian Gorzelic / AI Aerial Solutions
> **Last Updated:** March 2026

These are real-world deployment patterns for an always-on AI gateway running on a Pixel 10a. They are organized from simplest to most sophisticated. Each entry explains what the use case is, how the system actually executes it, why a phone is a better substrate than a cloud VM for this particular pattern, and a concrete example workflow.

These are not speculative capabilities. They reflect the actual architecture described in [docs/architecture.md](./architecture.md): a Node.js WebSocket gateway running in Termux, relaying to OpenRouter cloud inference, accessible via SSH over Tailscale from anywhere.

---

## Table of Contents

1. [24/7 Personal Assistant](#1-247-personal-assistant)
2. [Home Automation Hub](#2-home-automation-hub)
3. [Development Companion](#3-development-companion)
4. [Field Data Collector](#4-field-data-collector)
5. [Notification Triage](#5-notification-triage)
6. [Content Pipeline](#6-content-pipeline)
7. [Personal API Gateway](#7-personal-api-gateway)
8. [Emergency Infrastructure Fallback](#8-emergency-infrastructure-fallback)
9. [Multi-Agent Relay](#9-multi-agent-relay)
10. [Learning Tutor with Persistent Context](#10-learning-tutor-with-persistent-context)

---

## 1. 24/7 Personal Assistant

### What It Is

A single AI assistant reachable from any messaging platform you already use — WhatsApp, Telegram, Slack, Discord, Signal — that maintains memory of past conversations, can take actions on your behalf, and is never asleep. Unlike ChatGPT or Claude.ai accessed through a browser, this assistant lives on hardware you own, persists session state locally, and is reachable through your existing communication apps.

### How It Works

OpenClaw maintains persistent connections to your messaging channels. When you send a message to the WhatsApp number or Telegram bot linked to your gateway, the message arrives at the gateway over the platform's webhook or long-polling connection. The gateway routes it to the appropriate agent session, sends the conversation context to the configured model via OpenRouter, receives the response, and replies on the same channel within seconds.

Session state — conversation history, active skills, configured context — is stored in `~/.openclaw/` on the device. It survives reboots. Memory across sessions is provided by OpenClaw's layered memory architecture, which extracts and stores important facts, decisions, and preferences in a retrieval index.

### Why a Phone

A phone is already permanently on, permanently connected, and already has accounts on every messaging platform. A cloud VM has none of these properties without additional configuration. The phone's cellular radio provides connectivity even when home WiFi is unavailable.

More practically: you are already using your phone as the endpoint for all your messaging apps. Running the assistant on the same device as the accounts it manages eliminates one network hop and keeps message data on hardware you control.

### Example Workflow

You are at a meeting. Your laptop is closed. You open WhatsApp and type:

> "What's on my calendar this afternoon and do I have anything conflicting with the 3pm?"

The gateway, running on the Pixel 10a on your desk at home, receives this via the WhatsApp channel connector. It calls a calendar tool (Google Calendar API, with credentials stored locally), retrieves your afternoon schedule, checks for conflicts, and replies in WhatsApp within 3-4 seconds — formatted as a simple list, no markdown syntax, because you configured the WhatsApp channel to use plain text output.

You reply:

> "Move the 3pm to tomorrow morning, first available slot after 9"

The assistant calls the calendar tool with write permissions, finds the next available slot, creates the new event, deletes the old one, and confirms the change in WhatsApp.

You did not open a laptop. You did not open a browser. You used the messaging app you already had open.

---

## 2. Home Automation Hub

### What It Is

Natural-language control of smart home devices via any messaging channel, with context-aware behavior based on time, presence, and recent conversation history. Not a replacement for Home Assistant — a natural-language interface layered on top of it.

### How It Works

OpenClaw skills (tool definitions) wrap the Home Assistant REST API or directly call device APIs (Philips Hue, Nest, LIFX, etc.). When you send a command through any channel, the model interprets intent, selects the appropriate tool, and calls the API. The response confirms the action.

Because the gateway runs on a phone on your home network, it has direct local network access to devices. No cloud routing is required for local API calls. A command like "turn off the kitchen lights" resolves to a direct HTTP call to your Home Assistant instance on the local network — the only cloud hop is the OpenRouter inference call to interpret the command and construct the API request.

Conditional and contextual commands work because the model has conversation history and can call multiple tools in sequence:

- "Turn on the living room lights but make it dim, we're watching a movie" — calls Hue API with brightness 20%, warm color temperature
- "Good night" — calls a Home Assistant scene that locks doors, dims hallway lights to 5%, sets thermostat to sleep mode, and confirms any open windows
- "Did I leave the garage door open?" — calls the garage API, checks state, responds yes/no

### Why a Phone

The phone sits on your home network permanently. It can reach local devices without traversing NAT or requiring port forwarding. A cloud VM cannot reach `192.168.1.x` addresses at all without a VPN tunnel back to your home network, adding latency and complexity.

The phone's presence on the local network is a genuine architectural advantage, not just cost savings.

### Example Workflow

You wake up at 6:30am. Before getting out of bed, you open Telegram:

> "Morning routine"

The gateway executes a configured skill sequence:
1. Calls Home Assistant to set bedroom lights to 40% warm white
2. Calls thermostat API to raise heat to 70°F
3. Calls Google Calendar to retrieve today's schedule
4. Calls weather API for the local forecast
5. Composes a brief briefing: current temperature, today's events, any calendar conflicts

You respond:

> "Skip the lights today, I want to sleep another 20 minutes"

The assistant calls the Home Assistant API to reset the lights, sets a timer, and sends a message in 20 minutes:

> "20 minutes up. Lights coming on now."

Then executes the original light-on command. This kind of stateful, deferred action works because the session is persistent and running on always-on hardware.

---

## 3. Development Companion

### What It Is

An AI coding assistant that is always available over SSH, persists project context across sessions, and can access your actual development environment through tools — not just chat about code in the abstract.

### How It Works

You SSH into the Pixel 10a and enter the OpenClaw CLI, or you open the Canvas UI via SSH tunnel in your browser. The assistant has access to a shell tool (can execute commands), a file tool (can read and write files), and a web search tool. When you ask about a library, it can look up the documentation. When you ask it to check a function, it can read the file. When you ask it to run tests, it can execute them.

This differs from a local AI assistant (like Claude in your IDE) in one important way: the context persists. When you close your laptop and come back the next day, the session history is still there. The assistant remembers what you were working on, what decisions you made, and what you tried that did not work.

The development companion use case does not require the phone to do significant computation. The phone relays your questions to a capable model (typically Claude Sonnet via OpenRouter, not Haiku) and returns responses. The phone's job is to be there and maintain state.

### Why a Phone

Persistence and availability. A local AI assistant in your IDE stops when you close your IDE. A cloud VM-based assistant could work, but you have to pay for it to be running continuously, and it does not have access to your local files without additional configuration.

The phone is a different kind of always-on server: one that has already been paired with your identity (it is your phone), is already on your network, and costs nothing beyond its base hardware cost to keep running.

For developers working across multiple machines (desktop at home, laptop at the office or in the field), the phone provides a neutral common ground: every machine can SSH to the same gateway and resume the same context.

### Example Workflow

You are working on a data pipeline. You have a Python script that is throwing an intermittent `KeyError`. You open the Canvas UI via SSH tunnel:

> "I'm getting a KeyError in `/src/pipeline/transform.py` around line 80. The input data is from the Salesforce API — can you look at the file and the error pattern and tell me what's happening?"

The assistant uses the file tool to read `transform.py`, inspects the logic, notices that the Salesforce API sometimes omits the `LastModifiedDate` field for archived records, and explains the root cause. It suggests a fix using `.get()` with a default value and shows the exact code change.

You apply the fix and run the tests:

> "Run the tests in `/tests/test_transform.py` and tell me if the fix worked"

The assistant uses the shell tool to execute `python -m pytest tests/test_transform.py -v` and returns the output. All tests pass.

The next morning, you SSH into the same gateway:

> "Where did we leave off yesterday?"

The assistant summarizes the debugging session and the fix that was applied.

---

## 4. Field Data Collector

### What It Is

An intelligent data capture system that uses the phone's camera, GPS, and microphone to collect, label, and structure field observations — replacing paper forms, manual spreadsheets, and after-the-fact transcription.

### How It Works

The Pixel 10a is a phone. It has a 50+ megapixel camera with optical image stabilization, GPS with meter-level accuracy, a MEMS microphone, barometric pressure sensor, and accelerometer. These sensors are accessible from Termux via the Termux:API plugin.

OpenClaw skills wrap `termux-camera-photo`, `termux-location`, `termux-microphone-record`, and `termux-tts-speak`. When you trigger a capture workflow (by voice, by tapping a shortcut, or by sending a Telegram message), the skill chain:

1. Captures a photo or starts audio recording
2. Reads the current GPS coordinates
3. Sends the image and/or audio to the model with a structured extraction prompt
4. Returns structured data (JSON, CSV row, or natural-language summary depending on configuration)
5. Appends the result to a local file or pushes it to Google Sheets via the Sheets API

This is particularly useful for inspection workflows, site surveys, agriculture monitoring, and any field operation where structured data needs to be captured rapidly without a laptop.

### Why a Phone

The phone is already a sensor array. A cloud VM cannot take a photo. A Raspberry Pi can, but it requires a separate camera module, does not have cellular connectivity, and cannot send voice messages back to you through Telegram.

The integration of sensors with AI interpretation is what makes this valuable. Taking a photo is easy. Having the AI automatically extract structured data from that photo — reading a meter value, identifying a plant disease, detecting a construction defect — and recording it to your database without any manual transcription is the actual value proposition.

### Example Workflow

You are inspecting solar panel installations at a remote site. You open Telegram and start the inspection workflow:

> "Start site inspection: Array B, Section 3"

The gateway records the GPS coordinates and timestamps the session. For each panel, you photograph it from your phone camera:

> /photo

The skill captures a photo, sends it to Claude (a vision-capable model via OpenRouter), and receives a structured response:

```json
{
  "panel_id": "B3-047",
  "condition": "soiling",
  "severity": "moderate",
  "estimated_efficiency_loss": "8-12%",
  "recommendation": "clean within 30 days",
  "gps": [40.7128, -74.0060],
  "timestamp": "2026-03-07T14:23:11Z"
}
```

The gateway appends this to a Google Sheet automatically. You continue for each panel.

At the end of the inspection:

> "Generate summary report for Section 3"

The assistant reads the session's captured data, counts defects by severity, calculates total estimated efficiency loss, and generates a PDF-ready Markdown report with recommendations. You send it to your client before you leave the site.

---

## 5. Notification Triage

### What It Is

Automated filtering, prioritization, and summarization of high-volume notifications — transforming the flood of messages, alerts, and updates into a structured digest of what actually requires your attention.

### How It Works

OpenClaw's channel connectors maintain read access to your messaging platforms. On a configurable schedule (or triggered by volume thresholds), the assistant reads unread messages across channels and produces a prioritized summary.

The triage logic is defined by natural-language instruction in the system prompt rather than rigid rules. You can tell the assistant what matters: "anything from my manager or client is high priority, GitHub CI failures for main branch are high priority, marketing newsletters are low priority, LinkedIn notifications can be discarded." The model applies this intent flexibly.

Triage output can be delivered to any channel — a dedicated Telegram bot message, a Slack DM, an email via SendGrid — on whatever schedule you configure. The assistant can also take actions: marking emails as read, archiving low-priority Slack messages, or sending an acknowledgment reply.

### Why a Phone

Notification triage requires 24/7 connectivity to multiple services simultaneously. The phone maintains persistent WebSocket or long-polling connections to each messaging platform — the same connections that deliver your personal messages. A cloud VM can replicate this, but it requires you to grant API access to every platform and manage separate OAuth tokens for each. The phone already has active sessions.

The phone is also the device that receives notifications. Running triage on the device that receives the notifications eliminates network latency and avoids routing data through an additional cloud hop.

### Example Workflow

You configure a morning triage at 8:00am via OpenClaw's cron system:

```bash
openclaw cron add --every "8:00 AM" \
  --message "Triage all unread messages since yesterday 6pm.
  High priority: anything from Sarah or the Apex client, any CI failures on main.
  Medium: code review requests, calendar invites.
  Low: newsletters, LinkedIn, non-urgent Slack threads.
  Format: bullet list by priority. Flag anything requiring response today."
```

At 8:00am, the gateway reads unread messages across your Gmail, Slack, and Telegram accounts (using the respective API skills), runs the triage, and sends you a structured digest:

```
HIGH PRIORITY (requires action today):
- Sarah (Slack, 11:32pm): Asks if you can move the Wednesday demo to 2pm. Reply needed.
- Apex client (email, 8:45am): Requested updated proposal by EOD.
- CI failure (GitHub, 12:15am): main branch — payment service build failing.

MEDIUM PRIORITY:
- 3 code review requests (GitHub): can review this afternoon.
- 2 calendar invites: accepted automatically per your default rules.

LOW PRIORITY (14 items): Skipped. Flag 'triage low' to see these.
```

You spend 30 seconds on a digest that would have taken 15 minutes to manually process.

---

## 6. Content Pipeline

### What It Is

A structured workflow that takes a single piece of content — an article, a guide, a project update — and produces appropriately formatted versions for each publication channel: email newsletter, X/Twitter thread, LinkedIn post, Reddit post, Hacker News submission, Discord announcement.

### How It Works

This use case exists in this project. The [PUBLISH-PIPELINE.md](../PUBLISH-PIPELINE.md) documents the current manual process and planned automation. The gateway can partially automate this today and fully automate it with the planned skill set.

The source content is an HTML file (or Markdown). The assistant reads the source, understands the platform constraints for each channel (X character limits and thread format, LinkedIn's algorithm preferences, Reddit's community norms, HN's terse submission style), and produces a draft for each. It then posts to each channel via the respective API skills.

The pipeline is not fully automated yet — some platforms (Hacker News) have no API, and others (Beehiiv email) require an Enterprise subscription for programmatic posting. The current hybrid approach uses the assistant to generate all the per-channel content and human action to paste and post where APIs are unavailable.

### Why a Phone

The phone is the always-on orchestrator. Publishing does not happen all at once — it follows a cadence (email day 0, LinkedIn day 1, etc.). The phone can be told the cadence and execute it without a laptop being open. It also monitors for engagement signals (replies, comments) and can draft responses.

This is a case where the always-on, always-connected nature of a phone is a direct operational advantage over a laptop or a cloud VM that only runs when actively managed.

### Example Workflow

You finish a technical write-up and push it to the guide repository. From Telegram:

> "The new architecture doc is done. Generate publish content for issue 3."

The gateway uses the file tool to read `docs/architecture.md`, then generates:
- An X thread (5 tweets, hook-driven, code examples in screenshots)
- A LinkedIn post (professional framing, no markdown, call to action)
- A Reddit post for r/selfhosted (technical depth, honest about limitations)
- A Hacker News submission title and first comment
- A Discord announcement (shorter, community-focused)

Each draft is sent to you as a Telegram message for review. You reply with edits or just "looks good, post it."

The gateway posts the approved content to the channels with available APIs immediately. It schedules the remaining channels using OpenClaw's cron system to follow the publish cadence.

---

## 7. Personal API Gateway

### What It Is

A stable, authenticated HTTP endpoint that other systems can call to trigger AI-powered actions, accepting webhooks from external services and routing them to appropriate handlers.

### How It Works

When configured with Tailscale Funnel or Tailscale Serve, the gateway gets a stable public HTTPS URL. External services can POST to this URL to trigger actions. The gateway authenticates requests (token-based) and dispatches them to the appropriate skill.

Common webhook sources:
- **GitHub** — push events, CI status, PR reviews
- **Stripe** — payment events, subscription changes
- **Monitoring systems** — PagerDuty, Datadog, Grafana alerts
- **Custom scripts** — anything that can make an HTTP POST

When a webhook arrives, the gateway can:
- Parse the event payload
- Decide what action to take (using the model or with a fixed rule)
- Execute the action (send a Slack message, create a GitHub issue, call an API)
- Reply to the webhook with a structured response

The gateway can also serve as the endpoint for other AI systems or automation tools (n8n, Make, Zapier) that need a reliable AI backend without a per-seat SaaS subscription.

### Why a Phone

A phone's Tailscale node can use Tailscale Funnel to expose a port to the public internet without port forwarding or a static IP from your ISP. This is the only option for users on dynamic IP addresses (which is most residential internet customers) who want to receive webhooks without a cloud VM.

The phone provides this without an additional $25-35/month cloud VM cost.

### Example Workflow

You configure GitHub to send push webhooks to your gateway's Tailscale Funnel URL:

```
https://pixel.tailnet-name.ts.net/webhooks/github
```

When your main branch receives a push, the gateway:
1. Receives the webhook payload (commit list, author, diff stats)
2. Calls the CI API to check if tests are passing
3. If tests fail, sends a Slack message to the engineering channel with the failing test summary
4. If tests pass, checks the commit messages for `fix:` or `feat:` prefixes and updates the changelog draft

This replaces a GitHub Actions workflow that would cost compute minutes, or a cloud function that would add operational complexity. The phone does it as a persistent webhook receiver at no marginal cost.

---

## 8. Emergency Infrastructure Fallback

### What It Is

A backup AI access path that remains operational when your primary infrastructure fails. When your laptop is unavailable, your home internet is down, your cloud services are having an incident, or you need to work from a location without your usual tools — the phone gateway on cellular keeps you operational.

### How It Works

The Pixel 10a has an LTE/5G radio independent of your home WiFi. When home internet fails, Tailscale reroutes through cellular — the SSH tunnel and gateway remain accessible from any device on your tailnet that also has internet connectivity. The phone becomes the only working AI endpoint in your environment.

This use case is deliberately passive — it requires no additional configuration beyond the base setup. The redundancy is a property of the architecture, not a separate system.

For more active fallback scenarios: the phone can receive alerts from monitoring systems (via the webhook gateway use case) and take autonomous actions even when you are not actively managing it. If your primary server goes down at 3am, the phone can detect the alert, diagnose the issue using SSH tools, and notify you with a summary before you wake up.

### Why a Phone

A phone is the canonical always-on device. It has its own battery, its own cellular connection, and its own independent failure domain from your home network and cloud services. No other category of personal device shares all these properties.

A cloud VM fails if the cloud provider has an outage (or if you forget to pay the bill). A laptop fails when the power goes out or the WiFi dies. A phone survives both scenarios.

### Example Workflow

It is Saturday morning. Your home internet is down. A client emails asking for an urgent status update on a project.

You have cellular on your phone and on your laptop via hotspot. You open the Canvas UI via SSH tunnel to the phone gateway — which routes over cellular, not home WiFi. From the Canvas:

> "Pull the current status of the API service from the staging server and draft an update email for the client."

The gateway uses SSH tools to connect to the staging server (also on your tailnet), runs `systemctl status api-service` and `journalctl -u api-service --since "1 hour ago"`, processes the output, and drafts a professional status update email. You review and send it.

Your internet is still down. The client's situation is handled. The phone's cellular connection is the only thing that kept you operational.

---

## 9. Multi-Agent Relay

### What It Is

A routing layer that dispatches tasks to different AI models based on the nature of the request, enabling a mixed-model workflow where cheap fast models handle simple tasks and more capable models handle complex ones — without the user managing model selection manually.

### How It Works

OpenRouter provides access to 100+ models behind a single API. OpenClaw supports configuring routing rules that direct certain task types to specific models. The gateway evaluates incoming requests (by keyword, by channel, by a fast classifier model) and selects the appropriate model for each.

A simple tiered approach:
- **Triage and quick Q&A** → Claude 3.5 Haiku (~$0.25/1M tokens)
- **Code and analysis** → Claude Sonnet 4.5 (~$3/1M tokens)
- **Deep reasoning or long documents** → Claude Opus (~$15/1M tokens)
- **Open source, no data retention** → Llama 3.1 70B via OpenRouter (~$0.35/1M tokens)

A more sophisticated approach uses the gateway as an orchestrator: it receives a complex task, breaks it into subtasks, dispatches each subtask to the most appropriate model, collects results, and synthesizes a final response. This is the core pattern behind multi-agent frameworks like AutoGen and CrewAI — the phone gateway can serve as the coordinator for this kind of multi-step reasoning.

### Why a Phone

Model routing is a compute-light task. The phone does not need to do the thinking — it needs to be the stable orchestrator that maintains the task state, manages the API calls, and collects results. An always-on $349 phone is a better orchestrator than a $25/month VM for this pattern because it is cheaper, simpler to manage, and more redundant.

As an added benefit, having all model routing go through one device means all API costs flow through one OpenRouter account, making cost analysis straightforward.

### Example Workflow

You configure a routing rule: any message containing code or programming keywords routes to Sonnet; any message starting with "quick" or "tldr" routes to Haiku; all others route to Haiku with automatic escalation to Sonnet if the response is unsatisfactory.

You send a complex request:

> "Analyze this SQL query for performance issues, suggest indexes, and explain why the query planner might be choosing a full table scan."

The gateway classifies this as a code/analysis task, routes it to Claude Sonnet via OpenRouter, receives the detailed analysis, and returns it to you. The cost for this exchange is the Sonnet rate, not the Opus rate, because the routing rules correctly identified it as within Sonnet's capability.

You then ask:

> "Quick — what's the capital of France?"

The gateway classifies this as a simple Q&A, routes to Haiku, and returns "Paris" in under a second for 1/12th the cost of the previous query.

Over a month, the routing rules reduce your OpenRouter bill by 40-60% compared to using Sonnet for every request, with no degradation in quality for the tasks that Haiku handles well.

---

## 10. Learning Tutor with Persistent Context

### What It Is

A personalized tutor that maintains a model of your current knowledge state, tracks what you have learned, identifies gaps, and adapts explanations to your level — persisting this model across sessions on your own hardware rather than resetting each time.

### How It Works

OpenClaw's memory architecture stores extracted facts from conversations. In a tutoring context, this means:
- Concepts you have demonstrated understanding of
- Topics where you struggled or asked for clarification
- Your preferred explanation style (more analogies, more math, more code examples)
- Your stated goals and the curriculum you are working through
- Questions you have asked before (to avoid repetition)

When you start a new session, the gateway retrieves this context and the tutor is immediately calibrated to your current state. You do not start over. The tutor knows where you left off.

Sessions can happen across any device — phone keyboard during a commute, laptop Canvas UI at home, voice note via Telegram. The session history and memory are on the phone, not in the client.

### Why a Phone

Learning happens throughout the day in small moments — commute, lunch break, waiting in line. The phone is always in your pocket. Having the tutor on the phone means those moments are accessible without opening a laptop and navigating to a website.

More importantly: persistent context on your own hardware means the tutor's knowledge of your learning history is not subject to a SaaS company's context window limits, data retention policies, or pricing tier. A conversation you had six months ago is still in the memory index, and the tutor can reference it.

### Example Workflow

You are learning Rust. You have been working through ownership and borrowing for two weeks. You open Telegram on your lunch break:

> "I still don't fully get why the borrow checker rejects this pattern. Can you show me a concrete example where it matters?"

The tutor, with memory of your previous sessions, knows you understand heap allocation and that you find code examples more helpful than analogies. It produces a targeted example around a bug that would occur in C++ but is caught at compile time in Rust, specifically focused on the pattern you have been struggling with.

You ask three follow-up questions. The exchange takes 12 minutes on your lunch break.

That evening, you open the Canvas UI on your laptop and continue:

> "Let's do some exercises on what we covered today."

The tutor knows what you covered at lunch, generates appropriate exercises, evaluates your responses, and updates its model of your understanding. The lesson continues seamlessly despite the device change and the 6-hour gap.

The next session starts:

> "What should I work on today?"

The tutor consults the knowledge model, identifies that your borrow checker understanding has improved but lifetime annotations are the next gap, and proposes a 30-minute lesson plan.

---

## Combining Use Cases

These use cases are not mutually exclusive. The same gateway handles all of them simultaneously because each is a set of skills and routing rules layered on the same persistent WebSocket server.

A fully-configured gateway might:
- Triage notifications at 8am and 5pm via Telegram (use case 5)
- Answer development questions from the Canvas UI during work hours (use case 3)
- Post newsletter content on a schedule (use case 6)
- Receive GitHub webhooks and alert on CI failures (use case 7)
- Control home devices via WhatsApp (use case 2)
- Continue language-learning sessions during commutes (use case 10)

All of this from one $349 phone, at ~$5-15/month in inference costs.

---

*For architecture details, see [docs/architecture.md](./architecture.md).*
*For cost analysis and optimization, see [OPTIMIZATION-GUIDE.md](../OPTIMIZATION-GUIDE.md).*
*For device selection, see [docs/device-strategy.md](./device-strategy.md).*
