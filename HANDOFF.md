# HANDOFF.md — openclaw-pixel10a-guide

## What This Is

Guide and documentation repo for running OpenClaw (AI agent gateway) on a Google Pixel 10a via Termux. Includes 11-phase install guide, optimization guide, architecture docs, threat model, benchmarks, social launch kit, and all OSS essentials. Public repo at github.com/bgorzelic/openclaw-android-edge.

## Last Session — 2026-03-07

### Done
- Completed full public launch transformation of the repo (4,600+ lines of new content)
- Created 8 docs: architecture, use-cases, device-strategy, threat-model, faq, social-launch-kit, x-launch-posts, hero-diagram
- Added OSS essentials: LICENSE (MIT), CONTRIBUTING, SECURITY, ROADMAP, CHANGELOG
- Added GitHub issue/PR templates
- Fixed Tensor G5 → G4 across all files (14 occurrences)
- Fixed $499 → $349 price errors in device-strategy and faq
- Aligned README benchmarks with measured data (323 MB RSS, 0% CPU, 65ms)
- Polished README with shield badges, hero metrics table, newsletter CTA
- Pushed to GitHub: github.com/bgorzelic/openclaw-android-edge (public)
- Set repo description, homepage (spookyjuice.ai), 8 topics
- Created v0.2.0 release with detailed notes
- Created 3 starter issues (auto-start, device tracker, Telegram)
- Wrote X launch posts for @bgorzelic and @SpookyJuiceAI
- Brian posted X threads (both accounts, faster cadence)

### Decisions
- Repo under bgorzelic (not spookyjuiceai org — org doesn't exist yet)
- MIT license
- Tensor G4 confirmed as correct SoC (not G5) per /proc/cpuinfo on device

## Next Steps

1. Write and post Reddit (r/selfhosted, r/homelab) and HN submissions
2. Find X API keys on SpookyJuice VPS and set up automated posting
3. Publish Newsletter Issue #2 on Beehiiv
4. Create social preview image (spec in assets/hero-diagram.md)
5. Consider creating spookyjuiceai GitHub org and transferring repo
6. Begin Phase 3 work: Telegram channel connector (Issue #3)
7. Implement auto-start on boot via Termux:Boot (Issue #1)

## Open Questions

- X API keys are on the SpookyJuice VPS — Brian needs to retrieve them
- Should the repo move to a spookyjuiceai org later?
- Reddit/HN posts need different tone than X — not written yet

## Key Files

- `README.md` — Public-facing README with badges and metrics table
- `INSTALL-GUIDE.md` — 1,050+ line install walkthrough
- `OPTIMIZATION-GUIDE.md` — Performance tuning and cost analysis
- `docs/architecture.md` — 557-line system architecture
- `docs/threat-model.md` — 537-line security analysis
- `docs/use-cases.md` — 8 real-world deployment patterns
- `docs/x-launch-posts.md` — Copy-paste X posts for both accounts
- `docs/social-launch-kit.md` — Full multi-channel launch strategy
- `scripts/benchmark.sh` — Automated metrics collection

## Blockers

- None. Repo is live and launched.
