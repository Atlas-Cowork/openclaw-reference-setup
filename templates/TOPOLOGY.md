# TOPOLOGY.md — System Documentation Template

<!--
  INSTRUCTIONS: Document your entire system setup here.
  This is your single source of truth for "what runs where."
  Update this file EVERY TIME you change tools, crons, or architecture.
-->

## System Overview

- **Host:** [Hardware description, e.g., Mac Mini M4 24GB]
- **OS:** [e.g., macOS 15.x / Ubuntu 24.04]
- **Agent User:** [e.g., agent (UID 502)]
- **Admin User:** [e.g., yourusername (UID 501)]
- **OpenClaw Version:** [e.g., 2026.3.x]
- **Node.js:** [e.g., v22.x via Homebrew/nvm]
- **Primary Channel:** [e.g., Telegram DM]

## Changelog

<!-- 
  Add a line for every meaningful change. Format:
  YYYY-MM-DD — Brief description of what changed
-->

```
2026-03-25 — Initial setup documented
2026-03-24 — Added TTS tool (piper)
2026-03-20 — Set up egress control (safe_curl.sh)
2026-03-15 — Created dual-user setup
2026-03-10 — Initial OpenClaw installation
```

## Installed Tools

| Tool | Version | Purpose | Install Method | Notes |
|------|---------|---------|---------------|-------|
| ollama | x.x.x | Local LLM inference | Homebrew | MAX_LOADED_MODELS=1 |
| piper | x.x.x | Text-to-speech | Homebrew | German voice model |
| ffmpeg | x.x.x | Media conversion | Homebrew | |
| himalaya | x.x.x | Email CLI (IMAP/SMTP) | Homebrew | Needs --config flag |
| yt-dlp | x.x.x | Video/audio download | Homebrew | Only user-approved URLs |
| pandoc | x.x.x | Document conversion | Homebrew | |
| jq | x.x.x | JSON processing | Homebrew | |

## Custom Scripts

| Script | Purpose | Protected | Notes |
|--------|---------|-----------|-------|
| `scripts/safe_curl.sh` | Egress-controlled curl | uchg + SHA256 | Domain allowlist |
| `scripts/briefing_cache.sh` | Daily briefing data | uchg + SHA256 | Weather, calendar, email |
| `scripts/tts.sh` | TTS wrapper | — | Calls piper + lame |
| `scripts/whisper.py` | Speech-to-text | — | Faster-Whisper, local |
| `scripts/inbox_sync.sh` | iCloud → workspace | — | brctl + rsync |
| `scripts/outbox_sync.sh` | Workspace → iCloud | — | rsync |

## Cron Jobs / LaunchAgents

| Label | Schedule | Script | Purpose |
|-------|----------|--------|---------|
| `com.assistant.heartbeat` | Every 5 min | `heartbeat.sh` | Check pending tasks |
| `com.assistant.watchdog` | Every 5 min | `watchdog.sh` | Gateway health check |
| `com.assistant.briefing` | Daily 05:05 | `briefing_cache.sh` | Pre-fetch briefing data |
| `com.assistant.memory-cleanup` | Weekly Sun | `memory_cleanup.sh` | Distill old dailys |
| `com.assistant.integrity` | Every 30 min | `file_watchdog.sh` | SHA256 verification |
| `com.assistant.inbox-sync` | Every 10 min | `inbox_sync.sh` | iCloud inbound |
| `com.assistant.outbox-sync` | Every 10 min | `outbox_sync.sh` | iCloud outbound |

## Credentials (keys/values NEVER stored here)

| Service | Storage Method | Config Location | Last Rotated |
|---------|---------------|----------------|-------------|
| LLM API | Keychain | — | YYYY-MM-DD |
| Email (IMAP) | Keychain | `~/.config/himalaya/` | YYYY-MM-DD |
| Email (SMTP) | Keychain | `~/.config/himalaya/` | YYYY-MM-DD |
| Telegram Bot | File (chmod 600) | `~/.credentials/` | YYYY-MM-DD |
| Finance API | File (chmod 600) | `~/.credentials/` | N/A (free) |

## Network / Ports

| Service | Port | Bind | Protocol | Notes |
|---------|------|------|----------|-------|
| OpenClaw Gateway | 18789 | localhost | HTTP | Never expose externally |
| Ollama | 11434 | localhost | HTTP | LLM inference |
| Docker | — | — | — | RAM limit 4 GB |

## Security Status

| Component | Status | Last Verified |
|-----------|--------|--------------|
| Dual-user isolation | ✅ Active | YYYY-MM-DD |
| Exec approvals (on-miss) | ✅ Active | YYYY-MM-DD |
| Egress control | ✅ Active | YYYY-MM-DD |
| File integrity (uchg) | ✅ Active | YYYY-MM-DD |
| Credential chmod 600 | ✅ Active | YYYY-MM-DD |
| Security score | X.X/10 | YYYY-MM-DD |

## Architecture Decisions

<!--
  For major decisions, document them in a separate decisions.md file.
  Quick reference format:
-->

| Decision | Date | Why | Tradeoff |
|----------|------|-----|----------|
| Telegram over Discord | YYYY-MM-DD | Always available, rich media, free | Telegram cloud-encrypted by default |
| Piper over cloud TTS | YYYY-MM-DD | Privacy, no API cost, low latency | Quality slightly below cloud |
| File-first credentials | YYYY-MM-DD | Simple, portable, chmod 600 | No auto-rotation like Vault |
| Daily memory limit 200 | YYYY-MM-DD | Prevent token explosion | May lose detail on busy days |
