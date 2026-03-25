# Architecture

> How the system is built, and why.

## Table of Contents
- [Hardware](#hardware)
- [Dual-User Isolation](#dual-user-isolation)
- [Model Cascade](#model-cascade)
- [Channel Setup](#channel-setup)
- [Memory System](#memory-system)
- [iCloud Bridge](#icloud-bridge)
- [Cron Architecture](#cron-architecture)

---

## Hardware

### Recommendation: Dedicated Mac Mini (Apple Silicon)

| Aspect | Recommendation | Why |
|--------|---------------|-----|
| **Machine** | Mac Mini M4 (or M2+) | Always-on, low power (~10W idle), silent |
| **RAM** | 24 GB minimum | Local LLMs need 16+ GB, leave headroom for tools |
| **Storage** | 256 GB+ SSD | Models, logs, media files add up |
| **Network** | Wired Ethernet preferred | Stability for 24/7 operation |

### Why Dedicated Hardware?

**Don't run your AI assistant on your daily driver.** Reasons:

1. **Uptime** — Your assistant should be available when your laptop is closed or traveling
2. **Isolation** — Separate machine = separate attack surface
3. **Resources** — Local LLMs, TTS, and image generation are resource-hungry
4. **User separation** — Dedicated machine makes dual-user setup natural

A Raspberry Pi 5 works for lightweight setups (no local LLMs), but Apple Silicon's unified memory architecture makes it ideal for running 7B-27B models locally.

### Why macOS?

- Native iCloud integration (Calendar, Reminders, Notes bridge)
- `launchd` for reliable cron-like scheduling
- Keychain for credential management
- `chflags uchg` for file immutability (simpler than Linux alternatives)

Linux works fine too — just swap LaunchAgents for systemd timers and Keychain for `pass` or `secret-tool`.

---

## Dual-User Isolation

```
┌─────────────────────────────┐
│  Admin User (UID 501)       │  ← You. Has sudo. Manages the machine.
│  - Installs software        │
│  - Manages LaunchAgents     │
│  - Has Keychain access      │
└──────────┬──────────────────┘
           │ (no direct access)
┌──────────▼──────────────────┐
│  Agent User (UID 502)       │  ← OpenClaw runs here. No sudo.
│  - Owns workspace files     │
│  - Runs gateway + tools     │
│  - Limited file permissions │
│  - Sandboxed exec           │
└─────────────────────────────┘
```

### Why a Separate User?

1. **Blast radius** — If the agent is compromised, it can't `sudo`, can't read your personal files, can't modify system configs
2. **File permissions** — Agent's credential files are `chmod 600` under its own user — invisible to other processes
3. **Process isolation** — Agent's processes run under its own UID, visible and killable by admin
4. **Audit trail** — All file changes are attributable to the agent user

### Setup

```bash
# Create dedicated user (macOS)
sudo sysadminctl -addUser agent -password "<random>" -home /Users/agent

# On Linux
sudo useradd -m -s /bin/bash agent

# Grant agent user access to necessary groups (e.g., docker)
sudo usermod -aG docker agent
```

---

## Model Cascade

The system uses a tiered model strategy to balance cost, speed, and capability:

```
┌─────────────────────────────────────────────┐
│  Tier 1: Default Model (Cloud)              │
│  Fast, affordable, handles 90% of tasks     │
│  Examples: Claude Sonnet, GPT-4o-mini       │
├─────────────────────────────────────────────┤
│  Tier 2: Power Model (Cloud)                │
│  Complex reasoning, architecture decisions  │
│  Examples: Claude Opus, GPT-4o, o1          │
├─────────────────────────────────────────────┤
│  Tier 3: Local Fallback (On-Device)         │
│  Privacy-sensitive tasks, offline, cost=$0  │
│  Examples: Qwen 27B, Llama 3 8B via Ollama  │
└─────────────────────────────────────────────┘
```

### Routing Rules (Concept)

| Scenario | Model Tier |
|----------|-----------|
| Daily conversation, simple tasks | Tier 1 |
| Building tools, debugging, deep analysis | Tier 2 |
| Sensitive data processing, offline operation | Tier 3 |
| First attempt failed, need stronger reasoning | Escalate Tier 1 → 2 |

### Key Principles

- **Announce model switches** — The agent tells you when it escalates to a more powerful model
- **Step back down** — After completing a complex task, return to the default model
- **Local for privacy** — Anything involving personal documents should use Tier 3 when possible
- **Cost awareness** — Tier 2 models cost 5-20x more; use them deliberately

### Local Model Setup (Ollama)

```bash
# Install Ollama
brew install ollama  # macOS
# or: curl -fsSL https://ollama.com/install.sh | sh  # Linux

# Pull a model
ollama pull qwen2.5:27b

# Optimize for limited RAM (single model, short keep-alive)
export OLLAMA_MAX_LOADED_MODELS=1
export OLLAMA_KEEP_ALIVE=60s
```

---

## Channel Setup

### Telegram as Primary Channel

**Why Telegram DM (Direct Message)?**

1. **Always available** — Works on phone, tablet, desktop, web
2. **Rich media** — Send/receive images, audio, files, inline buttons
3. **Bot API** — Mature, well-documented, reliable
4. **End-to-end encryption** — Available via Secret Chats (standard chats are cloud-encrypted)
5. **No cost** — Free forever, no API fees for bots

### Why DM-Only?

- **Group chats are noisy** — The agent should only respond when directly addressed
- **Privacy** — Your conversations with your assistant shouldn't be in shared spaces
- **Context** — DM provides clean, unambiguous conversation context
- **Security** — Reduces injection surface (no other users can inject messages)

### Multi-Channel (Optional)

```
Primary:   Telegram DM     ← All interactions
Secondary: Discord Server  ← Optional, for specific use cases
Webhook:   HTTP endpoint   ← For programmatic triggers (cron results, alerts)
```

### Channel Security Rules

- Bot token stored in Keychain or `chmod 600` file — never in code
- Validate sender ID on every message
- Rate-limit responses to prevent abuse
- No auto-generated external URLs in responses (link preview exfiltration risk)

---

## Memory System

### 3-Layer Architecture

```
┌─────────────────────────────────────────────┐
│  Layer 1: Identity (Permanent)              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ SOUL.md  │  │ USER.md  │  │AGENTS.md │  │
│  │ Who am I │  │ Who are  │  │ Rules &  │  │
│  │          │  │   you    │  │ Workflow │  │
│  └──────────┘  └──────────┘  └──────────┘  │
├─────────────────────────────────────────────┤
│  Layer 2: Daily (Ephemeral, max 200 lines)  │
│  memory/2026-03-25.md                       │
│  memory/2026-03-24.md                       │
│  memory/2026-03-23.md                       │
│  → Raw logs of what happened each day       │
├─────────────────────────────────────────────┤
│  Layer 3: Archive (Curated, max 300 lines)  │
│  MEMORY.md                                  │
│  → Distilled long-term knowledge            │
│  → Weekly cleanup: dailys → archive         │
└─────────────────────────────────────────────┘
```

### Why Line Limits?

Without limits, memory files grow unbounded. This causes:
- **Token explosion** — Large context windows eat your API budget
- **Compaction artifacts** — When the context is compressed, important info gets lost
- **Slow session starts** — Agent reads all memory files at session start

Hard limits force discipline:
- **Daily files: 200 lines max** — If exceeded, distill into `MEMORY.md` immediately
- **MEMORY.md: 300 lines max** — Oldest entries get summarized or removed

### Distillation Process

```
Raw daily log → Extract key facts → Remove noise → Write to MEMORY.md
                                                    ↓
                                              Delete daily file
                                              (after 14 days)
```

Weekly cron job handles this automatically. The distillation prompt emphasizes:
- Keep facts, drop chatter
- Preserve decisions and their reasoning
- Note what worked and what didn't
- Never store credentials or sensitive data

### Session Start Sequence

```
1. Read SOUL.md       → "Who am I?"
2. Read USER.md       → "Who is my user?"
3. Read today's daily → "What happened today?"
4. Read yesterday's   → "What happened yesterday?"
5. (Main session) Read MEMORY.md → "What do I know long-term?"
```

---

## iCloud Bridge

### Concept: Bidirectional File Sync via iCloud Drive

If your assistant runs on macOS, you can bridge iCloud Drive to the agent's workspace. This enables:
- Sending files from your phone (drop in iCloud folder → agent picks it up)
- Receiving files from the agent (agent writes to iCloud folder → appears on phone)

### Architecture

```
┌──────────────┐     iCloud      ┌──────────────┐
│  Your Phone  │ ◄──────────────►│  iCloud Drive │
│  (Files app) │                 │  (on Mac)     │
└──────────────┘                 └───────┬───────┘
                                         │ rsync
                                  ┌──────▼───────┐
                                  │  Agent        │
                                  │  Workspace    │
                                  │  inbox/       │
                                  │  outbox/      │
                                  └──────────────┘
```

### Key Challenges

1. **iCloud lazy downloads** — Files aren't always on disk. Use `brctl download` to force download before syncing.
2. **Permission mismatch** — iCloud files are owned by admin user. Use `chmod` after `rsync` to fix.
3. **Conflict handling** — Two-way sync needs care. Use separate inbox/outbox directories.

See [scripts/inbox_sync.sh](../scripts/inbox_sync.sh) and [scripts/outbox_sync.sh](../scripts/outbox_sync.sh) for implementation.

---

## Cron Architecture

### LaunchAgents (macOS) / systemd Timers (Linux)

All scheduled tasks run as the agent user via LaunchAgents (macOS) or systemd user timers (Linux).

| Job | Frequency | Purpose |
|-----|-----------|---------|
| **Heartbeat** | Every 5 min | Check for pending tasks, important events |
| **Gateway Watchdog** | Every 5 min | Restart gateway if crashed |
| **Briefing Cache** | Daily 05:05 | Pre-fetch weather, calendar, email summaries |
| **Memory Cleanup** | Weekly (Sun) | Distill old dailys into MEMORY.md |
| **File Integrity** | Every 30 min | SHA256 check on critical files |
| **iCloud Inbox Sync** | Every 10 min | Pull files from iCloud Drive |
| **iCloud Outbox Sync** | Every 10 min | Push files to iCloud Drive |
| **Egress Log Rotation** | Daily | Rotate and compress egress logs |
| **Docker Cleanup** | Weekly | Prune dangling images and volumes |
| **Backup** | Daily 03:00 | Backup workspace to external drive |
| **Certificate Check** | Weekly | Verify TLS certs haven't expired |
| **Health Report** | Weekly (Mon) | Generate system health summary |

### Guardian Pattern

Critical jobs use a "guardian" pattern:

```bash
#!/bin/bash
# 1. Integrity check — verify the script hasn't been tampered with
EXPECTED_HASH="sha256:abc123..."
ACTUAL_HASH=$(shasum -a 256 "$SCRIPT_PATH" | cut -d' ' -f1)
if [ "$ACTUAL_HASH" != "$EXPECTED_HASH" ]; then
    echo "INTEGRITY VIOLATION" >> "$LOG_FILE"
    exit 1
fi

# 2. Run the actual job
/path/to/actual-script.sh

# 3. Log completion
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) OK" >> "$LOG_FILE"
```

This ensures that even if an attacker modifies a cron script, it won't execute — the guardian catches the hash mismatch.

### LaunchAgent Example (macOS)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.assistant.heartbeat</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/Users/agent/workspace/scripts/heartbeat.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>300</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/agent/.logs/heartbeat.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/agent/.logs/heartbeat-error.log</string>
</dict>
</plist>
```

### Quiet Hours

The agent observes quiet hours (configurable, default 23:00–08:00):
- Heartbeats still run but don't send notifications
- Only critical alerts (system down, security violation) break through
- Briefing is prepared during quiet hours, delivered after wake-up
