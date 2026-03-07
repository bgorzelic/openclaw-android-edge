# LinkedIn Post

> Post from personal profile (Brian Gorzelic). Attach 1-2 screenshots.

---

Yesterday I bought a Pixel 10a for $499 and turned it into an always-on AI edge node.

No root access. No bootloader unlock. Just Termux, proot Ubuntu, and Node.js.

Here's why this matters for edge AI:

A Pixel 10a gives you an 8-core Tensor G4 processor, 8GB RAM, 128GB storage, plus camera, microphone, GPS, and cellular — all in one package for under $500.

For field deployment (we're building this for drone operations at AI Aerial Solutions), that's compute + sensors + connectivity in your pocket. No separate modem, no GPS module, no camera board. Google guarantees 7 years of security updates.

The install wasn't straightforward. Android has 5 separate layers of power management that each try to kill background processes. Termux's native environment can't compile npm packages with C modules because it uses Bionic libc instead of glibc. I hit 8 different errors before finding the working path:

Termux → proot-distro Ubuntu → NodeSource Node.js → OpenClaw

About 15 minutes once you know the route. ~2 hours to figure it out.

I documented everything — every error, every fix, every ADB command — in a full install guide with screenshots. It's on GitHub for anyone building on this platform.

[LINK TO GITHUB REPO]

Phones are the most underrated edge compute platform. Change my mind.

#EdgeAI #Android #OpenClaw #Drones #EdgeComputing

---
