# Benchmark Methodology

> How we evaluated 67 sources to build the security model and tool ecosystem.

## Why Benchmark?

When building a personal AI assistant, every decision matters: which TTS engine, which email client, which security model. The internet is full of opinions but short on structured comparisons. We built a systematic evaluation process to make informed decisions.

## Sources Evaluated

We reviewed **67 sources** across these categories:

| Category | Count | Source Types |
|----------|-------|-------------|
| Academic papers | 12 | AI safety, prompt injection, agent security |
| CVE reports | 8 | Real vulnerabilities in chat platforms, LLM tools |
| Blog posts (technical) | 15 | Practitioner experiences with AI agents |
| Tool documentation | 18 | Official docs for TTS, STT, email, scraping tools |
| Security frameworks | 6 | OWASP, MITRE ATT&CK, NIST AI RMF |
| Community discussions | 8 | GitHub issues, forums, Discord threads |

## Evaluation Categories

### Tool Selection (TTS, STT, Email, etc.)

Each tool was scored on:

| Criterion | Weight | Description |
|-----------|--------|-------------|
| **Privacy** | 30% | Can it run locally? Does it phone home? |
| **Quality** | 25% | Output quality for its category |
| **Reliability** | 20% | Crash frequency, edge cases, maintenance |
| **Integration** | 15% | CLI-friendly? Scriptable? |
| **Cost** | 10% | Free/open-source preferred |

### Security Measures

Each security pattern was evaluated on:

| Criterion | Weight | Description |
|-----------|--------|-------------|
| **Effectiveness** | 35% | Does it actually prevent the threat? |
| **Practicality** | 25% | Can a solo operator maintain it? |
| **Usability impact** | 20% | How much friction does it add? |
| **Coverage** | 20% | How many attack vectors does it address? |

## Score System

### 5-Point Scale

| Score | Meaning |
|-------|---------|
| ⭐⭐⭐⭐⭐ | Excellent — clear winner, no significant downsides |
| ⭐⭐⭐⭐ | Very good — strong choice with minor tradeoffs |
| ⭐⭐⭐ | Good — works well but notable limitations |
| ⭐⭐ | Acceptable — gets the job done, better options exist |
| ⭐ | Poor — significant issues, avoid if possible |

### Example: TTS Engine Evaluation

| Engine | Privacy | Quality | Reliability | Integration | Cost | **Total** |
|--------|---------|---------|-------------|-------------|------|-----------|
| Piper (local) | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | **4.5** |
| Cloud TTS (various) | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | **3.6** |
| espeak | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | **3.8** |
| Coqui TTS | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | **4.0** |

Winner: **Piper** — best balance of privacy, quality, and ease of integration.

## Key Findings

### Security

1. **90%+ of public AI assistant setups have zero security hardening.** No exec approvals, no egress control, no credential isolation.
2. **Prompt injection is the #1 real-world threat.** Not theoretical — we found multiple CVEs and documented incidents.
3. **Memory poisoning is underrated.** Few setups validate what gets written to persistent memory.
4. **Link preview exfiltration is a real CVE class.** Chat platforms auto-fetching URLs creates an exfiltration channel.

### Tools

1. **Local tools have caught up in quality.** Piper TTS, Whisper STT, and local LLMs are now production-viable.
2. **CLI tools beat GUI tools for agents.** Scriptability > pretty interface.
3. **Email CLIs are fragile.** IMAP authentication varies wildly between providers. Budget time for debugging.
4. **Headless browsers need stealth.** Vanilla Puppeteer gets blocked by most sites. Stealth plugins are essential.

### Architecture

1. **Dedicated hardware pays for itself.** Reliability and isolation justify a $500-800 Mac Mini.
2. **Memory without structure is useless.** Flat files grow unbounded. The 3-layer system with hard limits works.
3. **Cron is underrated.** Most "AI automation" could be solved with well-designed cron jobs + a good briefing system.

## Recommendation: Do Your Own Benchmark

Our evaluations reflect our specific needs (German language TTS, macOS host, privacy-first). Your needs will differ.

### How to Run Your Own

1. **Define your criteria** — What matters most? Privacy? Quality? Cost?
2. **Weight them** — Not everything is equally important
3. **List candidates** — At least 3 options per category
4. **Test each one** — Spend 30 minutes with each tool, not 5
5. **Score honestly** — The tool you *want* to like isn't always the best
6. **Document the decision** — Future you will thank you

### Template

```markdown
## [Category] Evaluation — [Date]

### Candidates
1. [Tool A] — [one-line description]
2. [Tool B] — [one-line description]
3. [Tool C] — [one-line description]

### Scores

| Criterion | Weight | Tool A | Tool B | Tool C |
|-----------|--------|--------|--------|--------|
| Privacy   | 30%    |        |        |        |
| Quality   | 25%    |        |        |        |
| ...       | ...    |        |        |        |

### Decision: [Winner]
### Reason: [Why, in 2-3 sentences]
```

Save these evaluations. They become documentation for your `decisions.md` file.
