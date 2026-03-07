# Threat Model: OpenClaw on Pixel 10a via Termux

**Author:** Brian Gorzelic / AI Aerial Solutions
**Last Updated:** March 2026
**Scope:** Personal/small-team deployment of OpenClaw AI agent gateway on a Pixel 10a, accessed remotely via SSH over Tailscale.

---

## Architecture Security Summary

This deployment runs an AI agent gateway (OpenClaw) on a Pixel 10a phone inside Termux, with remote access provided by an SSH tunnel over Tailscale's WireGuard mesh network.

Key security properties:

- **Gateway binds to loopback only** (`127.0.0.1:18789`) — not reachable from LAN or internet
- **No ports exposed** on any network interface
- **Remote access via SSH** (port 8022) over Tailscale WireGuard mesh — not exposed to LAN
- **SSH uses key-based authentication** (password auth disabled after initial setup)
- **Gateway auth disabled** — safe because it only listens on loopback with no network exposure
- **API key stored in** `~/.openclaw/.env` (Termux app-private storage, not accessible to other Android apps without root)

The overall posture: minimize attack surface by keeping everything on loopback, limit remote access to authenticated Tailscale peers, and accept that conversation data leaves the device by design when calling cloud model APIs.

---

## Trust Boundaries

There are five distinct trust boundaries in this deployment, ordered from innermost to outermost:

```
+----------------------------------------------------------+
|  Internet (OpenRouter API, Tailscale coordination)       |
|  +----------------------------------------------------+  |
|  |  Tailscale Mesh (your devices only, WireGuard)     |  |
|  |  +----------------------------------------------+  |  |
|  |  |  Loopback Network (127.0.0.1 only)           |  |  |
|  |  |  +----------------------------------------+  |  |  |
|  |  |  |  Android App Sandbox (Termux, u0_a314) |  |  |  |
|  |  |  |  +----------------------------------+  |  |  |  |
|  |  |  |  |  Phone Hardware (physical device) |  |  |  |  |
|  |  |  |  +----------------------------------+  |  |  |  |
|  |  |  +----------------------------------------+  |  |  |
|  |  +----------------------------------------------+  |  |
|  +----------------------------------------------------+  |
+----------------------------------------------------------+
```

1. **Phone hardware boundary** — Physical access to the device is effectively game over, same as any device. This is not unique to this deployment.
2. **Android app sandbox** — Termux runs as an unprivileged Android app (`u0_a314`, no root). Other apps cannot read Termux's private storage. The Android kernel enforces this.
3. **Loopback network boundary** — The gateway listens on `127.0.0.1` only. No process outside the device can reach it over the network. Only local processes (within Termux or other apps on the same device) can connect.
4. **Tailscale mesh boundary** — SSH is only reachable via Tailscale. Only devices authenticated to your tailnet can connect. Traffic is encrypted end-to-end with WireGuard.
5. **Internet boundary** — HTTPS connections to OpenRouter carry conversation context out of the device. This is inherent to using cloud-hosted models.

---

## Threat Matrix

| # | Threat | Likelihood | Impact | Mitigation |
|---|--------|-----------|--------|------------|
| 1 | **Physical theft of phone** | Medium | High | Screen lock (PIN/biometric) + full-disk encryption (enabled by default on Pixel). Remote wipe via Find My Device. Tailscale device can be deauthorized remotely. Once locked, Termux data is encrypted at rest. |
| 2 | **WiFi network attack** | Low | Low | Gateway does not bind to any network interface — only loopback. SSH is on Tailscale, not on the WiFi interface. An attacker on the same WiFi network has no ports to reach. Standard WiFi attacks (ARP spoofing, MITM) are irrelevant to this setup. |
| 3 | **Tailscale account compromise** | Low | High | If an attacker gains access to your Tailscale account, they can add a device to your tailnet and SSH to the phone. Mitigate with 2FA on your Tailscale identity provider, review device list periodically, and deauthorize unknown devices immediately. Tailscale ACLs can further restrict which devices can reach the phone. |
| 4 | **OpenRouter API key leak** | Low | High | Key is stored in `~/.openclaw/.env` inside Termux's app-private storage. Not committed to git. Risk vectors: accidental `cat` in a shared terminal session, backup that includes the file, or a Termux vulnerability. Rotate the key periodically. Monitor OpenRouter usage for anomalies. |
| 5 | **Android killing the gateway process** | Medium | Low | Android aggressively manages background processes. Mitigated by adding Termux to the Doze whitelist and using `termux-wake-lock`. Impact is low — the gateway just needs restarting. No data loss, just temporary unavailability. |
| 6 | **Termux vulnerability** | Low | Medium | A vulnerability in Termux could allow another app or a local attacker to escape the sandbox. Keep Termux and its packages updated. Use SSH key-based auth (not passwords). Termux is open-source and actively maintained, but it is not hardened to the level of a production server OS. |
| 7 | **Conversation data sent to OpenRouter** | Certain | Medium | This is by design — cloud models require sending conversation context. All data in your prompts and tool results is visible to OpenRouter and the model provider. For sensitive work, use privacy-focused models or local models. Do not send PII, credentials, or proprietary data to cloud models unless you accept that risk. |
| 8 | **Man-in-the-middle on model API calls** | Very Low | High | OpenRouter uses TLS 1.3. Certificate pinning is handled by the system CA store. A MITM attack would require compromising a trusted CA or the device's trust store. This is a general internet risk, not specific to this deployment. |
| 9 | **Malicious AI tool execution** | Low | High | If the AI model is tricked (via prompt injection or adversarial input) into executing harmful tool calls, damage depends on what tools are enabled and their permissions. OpenClaw sandboxes tool execution. Review and restrict tool permissions to the minimum needed. Avoid granting tools write access to sensitive paths or system commands. |
| 10 | **Log data exposure** | Low | Low | Logs stay on the device in Termux storage. They may contain conversation fragments, tool outputs, or error details. Rotate logs regularly. Do not sync log directories to cloud storage. If the phone is compromised, logs are a secondary concern behind API keys and session data. |

---

## Data Flow: What Leaves the Device

| Data | Destination | Transport | Notes |
|------|------------|-----------|-------|
| Conversation context (prompts + tool results) | OpenRouter | HTTPS (TLS 1.3) | Required for cloud model inference. Content visible to OpenRouter and upstream model provider. |
| SSH session data | Your devices on tailnet | WireGuard (encrypted) | Only your authenticated devices can initiate connections. |
| Tailscale coordination metadata | Tailscale servers | HTTPS + WireGuard | Public keys and connection metadata only. No traffic content passes through Tailscale servers (direct peer-to-peer via DERP relay if needed, still encrypted). |

## Data Flow: What Stays on Device

- Session state and conversation history
- API keys and credentials (`~/.openclaw/.env`)
- Gateway configuration
- Tool execution results and intermediate state
- Application logs

---

## Recommendations

These are practical steps, prioritized for a personal/small-team deployment:

### Do Now
- **Disable SSH password auth** — key-based only (`PasswordAuthentication no` in sshd_config)
- **Enable 2FA on your Tailscale identity provider** (Google, GitHub, etc.)
- **Verify gateway binds to loopback** — `ss -tlnp | grep 18789` should show `127.0.0.1`, not `0.0.0.0`
- **Review OpenClaw tool permissions** — disable tools you are not actively using

### Do Regularly
- **Rotate your OpenRouter API key** — quarterly at minimum, immediately if you suspect exposure
- **Update Termux packages** — `pkg update && pkg upgrade`
- **Review Tailscale device list** — deauthorize any devices you no longer use
- **Rotate logs** — delete or archive old logs to limit exposure window

### Be Mindful Of
- **Do not send PII to cloud models** unless you have reviewed the provider's data handling policy
- **Do not commit `.env` files** to git (ensure `.gitignore` covers this)
- **Do not grant tools more permissions than needed** — principle of least privilege applies to AI tool execution too
- **Do not assume the phone is more secure than it is** — it is a consumer device, not a hardened server

---

## Comparison: Phone vs. Cloud VM

How does running OpenClaw on a phone compare to running it on a cloud VM?

| Aspect | Pixel 10a (This Setup) | Cloud VM |
|--------|----------------------|----------|
| **Physical control** | You hold the device. No one else has physical access unless it is stolen. | The cloud provider has physical access to the hardware. You trust their physical security. |
| **Network isolation** | Gateway on loopback + Tailscale. No public IP. Very small attack surface. | Typically has a public IP. Firewall rules are your responsibility. Misconfiguration = exposure. |
| **Disk encryption** | Full-disk encryption by default (Pixel). Tied to your screen lock. | Depends on provider/config. Often not encrypted at rest by default. Provider can access disk. |
| **Uptime/reliability** | Android may kill processes. Battery dependent. WiFi dependent. Not designed as a server. | Designed for uptime. Reliable network. But you pay for it and depend on the provider. |
| **Performance** | Tensor G4 SoC. Fine for a gateway proxying to cloud models. Not suitable for local model inference at scale. | Scalable. Can run local models with GPU instances. |
| **Cost** | Free after phone purchase. No monthly compute bill. | Ongoing cost. Even a small VM adds up over time. |
| **Trust model** | You trust Google (Android OS, Pixel firmware) and Tailscale. | You trust the cloud provider (AWS/GCP/Azure), their employees, and their security practices. |
| **Auditability** | You can inspect the device, its processes, its network connections. | Limited visibility into the host. You audit your VM, not the hypervisor. |

**Bottom line:** The phone setup trades reliability and performance for physical control and zero network exposure. For a personal AI gateway that proxies to cloud models, the phone is a reasonable choice — you accept Android's quirks in exchange for a deployment that is genuinely hard to reach from the network. A cloud VM is better if you need uptime guarantees or heavier compute, but it introduces trust in the cloud provider and requires more careful network configuration.

Neither setup is inherently more secure. They have different threat profiles. Pick the one that matches your actual risks.

---

## Assumptions and Limitations

This threat model assumes:

- The phone is **not rooted**. Rooting breaks the Android sandbox model and invalidates several mitigations listed here.
- **Tailscale is functioning correctly** and WireGuard key exchange has not been compromised.
- **OpenRouter's TLS implementation is sound**. We trust the standard TLS ecosystem.
- **You are the only user** of this tailnet (or you trust all users on it). Shared tailnets change the trust model.
- **OpenClaw's tool sandboxing works as documented**. This has not been independently audited for this threat model.

This is a personal deployment. It is not designed to meet compliance requirements (SOC 2, HIPAA, etc.). If your use case requires those, use a proper enterprise deployment.

---

*This document should be reviewed when the deployment architecture changes, when new tools are enabled in OpenClaw, or at least every six months.*
