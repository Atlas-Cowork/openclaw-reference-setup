# Atlas Reference Setup

**A Production-Grade OpenClaw Configuration**

[![Security Score](https://img.shields.io/badge/Security_Score-7.5%2F10-green)](#security)
[![Custom Tools](https://img.shields.io/badge/Custom_Tools-15%2B-blue)](#tools)
[![Cron Jobs](https://img.shields.io/badge/Cron_Jobs-12-orange)](#cron-architecture)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> A battle-tested, security-hardened OpenClaw personal assistant configuration — open-sourced as a reference for the community. No personal data, no credentials, just architecture and patterns.

---

## What Is This?

This repository documents the architecture, security model, and operational patterns behind a production OpenClaw setup that has been running 24/7 for months. It's not a plug-and-play installer — it's a **reference architecture** showing how to build a personal AI assistant you can actually trust.

**This is for you if:**
- You're setting up OpenClaw and want to see what a mature config looks like
- You care about security and want patterns for hardening your assistant
- You want ideas for memory management, tool integration, or cron automation
- You're curious how far you can push a personal AI setup

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Your Phone / Desktop                   │
│                   (Telegram DM Channel)                   │
└──────────────────────┬──────────────────────────────────┘
                       │ TLS
                       ▼
┌─────────────────────────────────────────────────────────┐
│               OpenClaw Gateway (localhost)                │
│            Port 18789 · Loopback Only · systemd          │
├─────────────────────────────────────────────────────────┤
│  ┌─────────┐  ┌──────────┐  ┌─────────────────────┐    │
│  │  Agent   │  │  Sandbox │  │   Exec Approvals    │    │
│  │ Runtime  │  │ (Docker) │  │ (Allowlist + ask)   │    │
│  └────┬─────┘  └────┬─────┘  └──────────┬──────────┘    │
│       │              │                   │               │
│  ┌────▼──────────────▼───────────────────▼──────────┐   │
│  │              Tool Ecosystem                       │   │
│  │  TTS · STT · Email · Scraping · Image Gen · CLI  │   │
│  └──────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│  Memory Layer          │  Cron / LaunchAgents           │
│  ┌───────────────┐     │  ┌───────────────────────┐    │
│  │ SOUL.md       │     │  │ Heartbeat (5 min)     │    │
│  │ MEMORY.md     │     │  │ Briefing Cache (daily)│    │
│  │ daily/*.md    │     │  │ Memory Cleanup (weekly)│   │
│  │ USER.md       │     │  │ Watchdog (5 min)      │    │
│  └───────────────┘     │  └───────────────────────┘    │
├─────────────────────────────────────────────────────────┤
│  Security Layer                                          │
│  Egress Control · File Integrity · Injection Detection   │
│  Credential Isolation · Dual-User · Immutable Configs    │
└─────────────────────────────────────────────────────────┘
```

## Key Features

### 🔒 Security-First Design
- **Dual-user isolation** — agent runs under its own OS user, separated from admin
- **Exec approvals** — allowlist of ~50 safe binaries, everything else requires approval
- **Egress control** — HTTP requests only to allowlisted domains via wrapper script
- **File integrity** — critical configs protected with `uchg` flags + SHA256 checksums
- **Injection detection** — monitors for prompt injection in external inputs
- **Memory validation** — pre-write checks prevent memory poisoning

### 🧠 3-Layer Memory System
- **Identity Layer** — `SOUL.md` (who the agent is) + `USER.md` (who you are)
- **Daily Layer** — per-day logs with 200-line hard limit
- **Archive Layer** — `MEMORY.md` curated long-term memory with weekly distillation

### 🛠 15+ Integrated Tools
- Text-to-Speech (local, no cloud API)
- Speech-to-Text (Whisper, local)
- Email (IMAP/SMTP via CLI)
- Web scraping (headless browser + stealth)
- Image generation (local diffusion model)
- Calendar, Reminders, Finance data
- See [docs/TOOLS.md](docs/TOOLS.md) for the full catalog

### ⏰ 12 Cron Jobs
- Daily briefing cache (weather, calendar, email summary)
- Heartbeat monitoring (every 5 minutes)
- Gateway watchdog (auto-restart on failure)
- Weekly memory distillation
- File integrity checks
- See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#cron-architecture) for details

## Quick Start

This repo is a **reference**, not an installer. Here's how to use it:

### 1. Understand the Architecture
Start with [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) to understand the overall design.

### 2. Review the Security Model
Read [docs/SECURITY.md](docs/SECURITY.md) — this is the most important document. Security isn't a feature you bolt on later.

### 3. Copy the Templates
```bash
# Copy templates to your OpenClaw workspace
cp templates/SOUL.md    ~/.openclaw/workspace/SOUL.md
cp templates/AGENTS.md  ~/.openclaw/workspace/AGENTS.md
cp templates/USER.md    ~/.openclaw/workspace/USER.md

# Edit them to match your setup
nano ~/.openclaw/workspace/SOUL.md
```

### 4. Set Up Security Basics
```bash
# Review and customize the security script
nano scripts/setup_security.sh

# Run it (review each step — don't blindly execute)
chmod +x scripts/setup_security.sh
./scripts/setup_security.sh
```

### 5. Configure Exec Approvals
```bash
# Use the example as a starting point
cp examples/exec-approvals-example.json ~/.openclaw/exec-approvals.json
# Add your own safe binaries
nano ~/.openclaw/exec-approvals.json
```

### 6. Build Your Tool Ecosystem
See [docs/TOOLS.md](docs/TOOLS.md) for recommended tools per category.

## Repository Structure

```
atlas-reference-setup/
├── README.md                          # You are here
├── LICENSE                            # MIT
├── docs/
│   ├── ARCHITECTURE.md                # System design & hardware
│   ├── SECURITY.md                    # Security model (the heart)
│   ├── BENCHMARK.md                   # How we evaluated 67 sources
│   └── TOOLS.md                       # Tool catalog by category
├── templates/
│   ├── SOUL.md                        # Agent identity template
│   ├── AGENTS.md                      # Workspace rules template
│   ├── TOPOLOGY.md                    # System documentation template
│   └── USER.md                        # User context template
├── scripts/
│   ├── setup_security.sh              # Security hardening script
│   ├── inbox_sync.sh                  # iCloud → workspace sync
│   └── outbox_sync.sh                 # Workspace → iCloud sync
├── examples/
│   └── exec-approvals-example.json    # Exec allowlist example
└── .github/
    └── CONTRIBUTING.md                # How to contribute
```

## Benchmarks & Evaluation

We evaluated 67 sources (papers, blog posts, CVE reports, real-world incidents) to build the security model. See [docs/BENCHMARK.md](docs/BENCHMARK.md) for the full methodology.

**TL;DR:** Most "AI assistant" setups have zero security hardening. This reference aims to change that.

## Philosophy

1. **Security is not optional.** An AI assistant with shell access and your email is a high-value target. Treat it like a server, not a toy.
2. **Memory is architecture.** Without structured memory, your assistant forgets everything every session. The 3-layer system solves this.
3. **Local > Cloud.** Every tool that can run locally, should. Your voice, your documents, your images — none of it needs to leave your machine.
4. **Approvals prevent disasters.** A well-tuned allowlist means you approve meaningful actions, not every `ls` command.
5. **Document everything.** If it's not written down, it doesn't exist next session.

## Contributing

See [.github/CONTRIBUTING.md](.github/CONTRIBUTING.md). We welcome:
- Security improvements and new threat patterns
- Tool recommendations with setup guides
- Translations
- Bug reports on the templates

## License

[MIT](LICENSE) — Use it, fork it, improve it. Attribution appreciated but not required.

---

*Built with [OpenClaw](https://github.com/openclaw) — the open-source personal AI assistant platform.*
