# Newsletter Publish Pipeline

> **Goal:** Automate Issue #N from draft to all channels with one command.
> **Status:** Manual for Issue #2. Automate incrementally starting Issue #3.

---

## Current Channels (Issue #2 — Manual)

| # | Channel | Account | Post Format | Source File |
|---|---------|---------|-------------|-------------|
| 1 | **Beehiiv** (email) | The Persistent Ghost | Full HTML newsletter | `issue-NN/the-persistent-ghost-issue-NN.html` |
| 2 | **X / Twitter** | @SpookyJuiceAI | Thread (4-5 tweets) | `social/twitter-thread.md` |
| 3 | **LinkedIn** | Brian Gorzelic (personal) | Single post + screenshots | `social/linkedin-post.md` |
| 4 | **Reddit** | Personal account | Long-form post | `social/reddit-post.md` |
| 5 | **Hacker News** | Personal account | Show HN link + comment | `social/hackernews-post.md` |
| 6 | **Discord** | SpookyJuice.AI server | Announcement post | `social/discord-post.md` |

## Future Channels (Not Yet Automated)

| # | Channel | Account | Post Format | Notes |
|---|---------|---------|-------------|-------|
| 7 | **Instagram** | @SpookyJuiceAI | Carousel (screenshots) or Reel | Needs 1080x1080 images or short video |
| 8 | **Facebook** | SpookyJuiceAI | Adapted LinkedIn post | Facebook API or manual |
| 9 | **TikTok** | @SpookyJuiceAI | Short video (30-60s) | Screen recording of install or talking head |
| 10 | **TikTok** | @SpookysShop | Storefront cross-promo | Link to ClawMart listing |
| 11 | **YouTube** | SpookyJuiceAI | Long-form walkthrough | Full install tutorial |
| 12 | **Snapchat** | @spookyjuiceai | Story highlights | Ephemeral — screenshots + captions |
| 13 | **Pinterest** | Printful storefront | Pin with guide link | Infographic format |

## Contact & Support

- **Email:** support@spookyjuice.ai
- **CTA:** https://spookyjuice.ai (customizable per campaign)

---

## Issue Directory Structure

```
issue-NN/
  the-persistent-ghost-issue-NN.html   # Full standalone HTML (web + email)
  meta.json                             # Title, subtitle, tags, X thread, Discord msg
social/
  twitter-thread.md                     # Per-issue X thread content
  linkedin-post.md                      # LinkedIn post
  reddit-post.md                        # Reddit post (r/selfhosted, r/android, etc.)
  hackernews-post.md                    # Show HN title + first comment
  discord-post.md                       # Discord announcement
  instagram-carousel.md                 # (future) Carousel slide text
  facebook-post.md                      # (future) Facebook adaptation
  tiktok-caption.md                     # (future) TikTok video caption
```

---

## Manual Publish Checklist (Current — Issue #2)

### Pre-flight

- [ ] All content reviewed and scrubbed (no PII, no real device serials, generic usernames)
- [ ] Logo URL is absolute (`https://spookyjuice.ai/images/spookyjuiceai.png`)
- [ ] `meta.json` has correct title, subtitle, preview_text, tags, X thread, Discord msg
- [ ] HTML tested in browser (open the `.html` file locally)

### Beehiiv (Email)

- [ ] Inline CSS: run the premailer script (see below)
- [ ] Create Post in Beehiiv dashboard
- [ ] Type `/` → HTML Snippet → paste inlined HTML
- [ ] Set title: `meta.json` → `subject_line`
- [ ] Set subtitle: `meta.json` → `subtitle`
- [ ] Set preview text: `meta.json` → `preview_text`
- [ ] Preview and verify logo renders
- [ ] Send (or schedule)

### X / Twitter

- [ ] Log in as @SpookyJuiceAI
- [ ] Post each tweet from `social/twitter-thread.md` as a thread
- [ ] Attach 1-2 screenshots from `screenshots/` to first tweet
- [ ] Include link to GitHub repo or spookyjuice.ai

### LinkedIn

- [ ] Post from personal profile (Brian Gorzelic)
- [ ] Copy from `social/linkedin-post.md`
- [ ] Attach 1-2 screenshots
- [ ] Tag relevant connections

### Reddit

- [ ] Post to r/selfhosted (primary)
- [ ] Cross-post to r/android, r/termux, r/homelab as appropriate
- [ ] Use `social/reddit-post.md` content
- [ ] Engage with comments for first 2 hours

### Hacker News

- [ ] Submit as "Show HN: [title]" with GitHub link
- [ ] Post first comment from `social/hackernews-post.md`
- [ ] Monitor and respond for first 2 hours

### Discord

- [ ] Post in SpookyJuice.AI #announcements
- [ ] Post in OpenClaw Discord #showcase
- [ ] Use `meta.json` → `discord_message`

---

## CSS Inlining Script

Run this to convert the standalone HTML into Beehiiv-compatible inlined HTML:

```bash
python3 << 'PYEOF'
from premailer import transform
import re, sys

ISSUE = sys.argv[1] if len(sys.argv) > 1 else "02"
INPUT = f"issue-{ISSUE}/the-persistent-ghost-issue-{ISSUE}.html"

with open(INPUT, 'r') as f:
    html = f.read()

# Resolve CSS custom properties
var_map = {
    'var(--bg)': '#08080f', 'var(--bg2)': '#0e0e1a', 'var(--bg3)': '#12121f',
    'var(--card)': '#111120', 'var(--border)': '#1e1e35',
    'var(--green)': '#39ff14', 'var(--green-dim)': '#1a7a08',
    'var(--green-glow)': 'rgba(57,255,20,0.18)',
    'var(--purple)': '#8b5cf6', 'var(--purple-dim)': '#3b1d8a',
    'var(--purple-glow)': 'rgba(139,92,246,0.18)',
    'var(--cyan)': '#22d3ee', 'var(--text)': '#e2e8f0',
    'var(--text-muted)': '#94a3b8', 'var(--text-faint)': '#4a5568',
    'var(--orange)': '#f97316', 'var(--orange-glow)': 'rgba(249,115,22,0.18)',
    'var(--red)': '#ef4444', 'var(--red-glow)': 'rgba(239,68,68,0.15)',
}
for var, val in var_map.items():
    html = html.replace(var, val)

# Remove @keyframes (not supported in email)
html = re.sub(r'@keyframes\s+\w+\s*\{[^}]*\{[^}]*\}[^}]*\}', '', html)

# Inline styles
inlined = transform(html, remove_classes=False, strip_important=False,
                    keep_style_tags=False, disable_validation=True)

# Extract body, strip scripts
body_match = re.search(r'<body[^>]*>(.*?)</body>', inlined, re.DOTALL)
body = body_match.group(1).strip() if body_match else inlined
body = re.sub(r'<script.*?</script>', '', body, flags=re.DOTALL)

OUT = f"/tmp/beehiiv-issue-{ISSUE}.html"
with open(OUT, 'w') as f:
    f.write(body)

print(f"Written to {OUT} ({len(body):,} chars)")
print(f"Run: cat {OUT} | pbcopy")
PYEOF
```

Usage:

```bash
# From the openclaw-pixel10a-guide directory:
python3 inline.py 02          # produces /tmp/beehiiv-issue-02.html
cat /tmp/beehiiv-issue-02.html | pbcopy   # copy to clipboard
```

Requires: `pip3 install premailer`

---

## Future Automation Targets

### Phase 1: Script per channel (Issue #3)

| Script | API / Tool | Automates |
|--------|-----------|-----------|
| `scripts/inline-css.py` | premailer | CSS inlining for Beehiiv |
| `scripts/post-x-thread.py` | X API v2 | Thread posting from meta.json |
| `scripts/post-discord.py` | Discord webhook | Announcement from meta.json |
| `scripts/post-reddit.py` | Reddit API (PRAW) | Cross-post to multiple subs |

### Phase 2: Unified publish command (Issue #4+)

```bash
# The dream:
./publish.sh 03              # dry-run by default
./publish.sh 03 --send       # email + all social
./publish.sh 03 --skip-x --skip-reddit   # selective
```

This mirrors the existing `scripts/publish-newsletter.sh` in the spookyjuice.ai repo.

### Phase 3: OpenClaw-powered publish (Future)

Use OpenClaw itself as the publisher:

```bash
openclaw agent --message "Publish newsletter issue 3 to all channels"
```

OpenClaw skills for each platform, cron-scheduled drip posting, engagement monitoring via channel integrations. The agent reads meta.json, posts everywhere, and reports back.

### API Keys Needed for Automation

| Platform | API | Auth Method | Status |
|----------|-----|-------------|--------|
| Beehiiv | Content API | Bearer token | Requires Enterprise plan |
| X / Twitter | v2 API | OAuth 2.0 | Free tier: 1,500 tweets/mo |
| Discord | Webhook | Webhook URL | Free, create in server settings |
| Reddit | API (PRAW) | OAuth 2.0 | Free, register app at reddit.com/prefs/apps |
| LinkedIn | Marketing API | OAuth 2.0 | Requires approved app |
| Facebook | Graph API | Page token | Requires approved app |
| Instagram | Graph API | Via Facebook | Requires Facebook app |
| HN | None | Manual only | No public API for submissions |

### Beehiiv Workaround (No Enterprise)

Since the Posts API requires Enterprise, alternatives for email automation:

1. **Buttondown** — full API on all plans, Markdown-native, $9/mo
2. **Resend** — raw email API, own templates, $20/mo for 50k emails
3. **Keep Beehiiv for subscribers** + send via Resend using the Beehiiv subscriber export
4. **Manual paste** — the inline script + pbcopy makes this a 30-second task

---

## Content Reuse Strategy

Each issue produces content for multiple formats:

```
issue-NN.html (source of truth)
  ├── Beehiiv email (inlined CSS version)
  ├── Web page (hosted at spookyjuice.ai/newsletter/issue-NN/)
  ├── X thread (extracted key points, 4-5 tweets)
  ├── LinkedIn post (professional angle, 1 post)
  ├── Reddit post (technical deep-dive, long form)
  ├── HN submission (Show HN, link + first comment)
  ├── Discord announcement (short, community-focused)
  ├── Instagram carousel (visual slides from screenshots)
  ├── TikTok/Reels (30-60s screen recording or narration)
  └── YouTube (full walkthrough, 10-30min)
```

### Resend Cadence

- **Day 0:** Beehiiv email + X thread + Discord
- **Day 1:** LinkedIn + Reddit + HN
- **Day 2:** Instagram carousel + Facebook
- **Day 3-7:** Beehiiv "resend to unopens" with tweaked subject
- **Day 7+:** TikTok / YouTube (video content takes longer)
- **Monthly:** "Best of" roundup for new subscribers

---

*Pipeline doc created March 7, 2026. Update after each issue to capture what worked.*
