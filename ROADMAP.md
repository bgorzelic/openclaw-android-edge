# Roadmap

> Status: [x] Done | [~] In Progress | [ ] Planned | [?] Exploring

## Phase 1: Foundation -- DONE

- [x] Install guide (11 phases, 1050+ lines)
- [x] Native Termux gateway (not proot)
- [x] SSH remote access with key-based auth
- [x] Tailscale networking for stable remote IP
- [x] Gateway optimization for Android
- [x] Benchmark script for measurable metrics
- [x] Performance baseline (323 MB RSS, 0% idle CPU, 65ms latency)
- [x] Cost analysis (phone vs cloud VM)
- [x] 10 documented workflows and use cases

## Phase 2: Public Launch -- IN PROGRESS

- [~] World-class README
- [~] Architecture and threat model docs
- [~] Social launch kit (X, LinkedIn, Reddit, HN, Discord)
- [~] Newsletter Issue #2 on Beehiiv
- [ ] GitHub public repo creation
- [ ] Social media launch sequence
- [ ] Community feedback collection

## Phase 3: Channel Integrations -- PLANNED

- [ ] WhatsApp channel connection
- [ ] Telegram channel connection
- [ ] Discord channel connection
- [ ] iMessage bridge (macOS relay)
- [ ] Channel-specific documentation

## Phase 4: Fleet Operations -- PLANNED

- [ ] Multi-device support and documentation
- [ ] Auto-start on boot (Termux:Boot plugin)
- [ ] Health check cron with auto-restart
- [ ] Log rotation and disk management
- [ ] Remote fleet monitoring dashboard
- [ ] Device-to-device agent communication

## Phase 5: Edge Intelligence -- EXPLORING

- [ ] Local inference with llama.cpp on Tensor G4
- [ ] Sensor integration (camera, GPS, mic via Termux:API)
- [ ] Multi-agent routing (Haiku for triage, Sonnet for work)
- [ ] Scheduled intelligence (morning briefings, end-of-day summaries)
- [ ] Voice interaction via Termux:API microphone
- [ ] Phone-as-sensor for field data collection

## Phase 6: Ecosystem -- FUTURE

- [ ] Multi-phone cluster architecture
- [ ] Edge-to-cloud failover patterns
- [ ] Community device compatibility database
- [ ] Integration with home automation (Home Assistant, MQTT)
- [ ] OpenClaw skill development for Android-specific capabilities

---

## Contributing to the Roadmap

Have a use case or feature idea? Open an issue with the "Feature Request" label or submit a PR to this file.

Priorities are driven by:
1. What's practical on current hardware
2. What the community actually needs
3. What we can document well enough for others to reproduce
