# Contributing to OpenClaw on Pixel 10a Guide

First off -- thanks for being here. This project exists because someone tried
something weird (running an AI gateway on a phone) and it worked. If you want to
make it better, you're in the right place.

## Ways to Contribute

### Report a Bug or Issue

If something in the guide doesn't work, open an issue. Include the following so
we can actually help:

- **Device model** (e.g., Pixel 10a, Pixel 9 Pro)
- **Android version** (e.g., Android 16)
- **Termux version** (from `termux-info`)
- **OpenClaw version** (from `openclaw --version` or your install method)
- **What you tried** -- exact commands, copy-pasted
- **What happened** -- error output, unexpected behavior
- **What you expected** -- what should have happened

Use the **Bug Report** issue template if one fits. Screenshots of terminal
output are welcome.

### Submit a Guide for Another Device

Got OpenClaw running on a different phone? We want to hear about it.

1. Open an issue using the **Device Report** template.
2. Include device specs, what worked out of the box, and what needed tweaking.
3. If you want to write a full guide, open a PR adding a new file under `docs/`
   (e.g., `docs/samsung-s25-guide.md`).

Follow the structure of the existing Pixel 10a guide so readers can compare
across devices.

### Improve the Docs

Typos, unclear steps, missing context, better formatting -- all fair game. Open
a PR with your changes. No change is too small.

For larger rewrites or restructuring, open an issue first so we can discuss the
approach before you put in the work.

### Contribute Scripts or Tooling

If you've built a helper script (monitoring, auto-start, benchmarking) that
others would find useful:

1. Fork the repo and create a feature branch.
2. Add your script with a clear comment header explaining what it does.
3. Update the README or relevant docs if needed.
4. Open a PR describing what it does and how you tested it.

## Pull Request Process

1. Fork the repository and create a branch from `main`.
2. Make your changes. Keep commits focused -- one logical change per commit.
3. Test your changes on actual hardware if possible.
4. Fill out the PR template.
5. Submit and be patient -- this is a side project, not a VC-funded startup.

## Style Guide

- Write in plain English. Assume the reader is technical but hasn't done this
  before.
- Use code blocks for all commands. Specify the shell language when relevant.
- Avoid jargon without explanation.
- No emojis in docs or code.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).
Be decent to each other. We're all here to build things.

## Questions?

Open a discussion or issue. There are no dumb questions -- especially when the
project involves running AI agents on a phone.
