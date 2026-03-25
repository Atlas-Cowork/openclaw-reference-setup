# Tool Catalog

> Recommended tools by category for a production OpenClaw setup. All tools are local-first where possible.

## Guiding Principles

1. **Local over cloud** — If it can run on your machine, it should
2. **CLI over GUI** — Agents need scriptable interfaces
3. **Privacy by default** — No data leaves your machine unless explicitly needed
4. **One tool per job** — Avoid redundancy, reduce maintenance

---

## Text-to-Speech (TTS)

### Recommended: Piper

| Aspect | Details |
|--------|---------|
| **Why** | Fast, high-quality, fully local, supports 30+ languages |
| **Quality** | Near cloud-quality for supported languages |
| **Privacy** | 100% local — no network calls |
| **Cost** | Free (open source) |
| **Setup** | Install via Homebrew or download binary; download voice model (~100MB) |

```bash
# Install
brew install piper  # macOS
# or download from: https://github.com/rhasspy/piper/releases

# Download a voice model
wget https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/high/en_US-lessac-high.onnx

# Usage
echo "Hello world" | piper --model en_US-lessac-high.onnx --output_file output.wav

# Convert to MP3 for smaller file size
lame output.wav output.mp3
```

**Tip:** Create a wrapper script (`tts.sh`) that handles model path, output format, and temp file cleanup.

### Alternatives
- **Coqui TTS** — More voices, but heavier and less maintained
- **espeak** — Ultra-lightweight but robotic quality
- **Cloud TTS** (Google, Amazon, Azure) — Best quality, but sends all text to cloud

---

## Speech-to-Text (STT)

### Recommended: Faster-Whisper

| Aspect | Details |
|--------|---------|
| **Why** | Whisper accuracy with 4x speed improvement |
| **Quality** | State-of-the-art for most languages |
| **Privacy** | 100% local |
| **Cost** | Free (open source) |
| **Model** | `large-v3` recommended (best accuracy) |

```bash
# Install in a virtual environment
python3 -m venv ~/venvs/whisper
source ~/venvs/whisper/bin/activate
pip install faster-whisper

# Usage (via wrapper script)
python3 whisper.py input_audio.ogg
# Output: transcribed text to stdout
```

**Tip:** Use a persistent Python virtual environment to avoid re-downloading models.

### Alternatives
- **OpenAI Whisper** (original) — Slower but simpler setup
- **Whisper.cpp** — C++ port, even faster, good for Raspberry Pi
- **Cloud STT** (Google, Amazon) — Streaming support, but cloud dependency

---

## Email

### Recommended: Himalaya

| Aspect | Details |
|--------|---------|
| **Why** | Modern CLI email client, IMAP/SMTP, scriptable |
| **Privacy** | Connects directly to your mail server |
| **Cost** | Free (open source) |
| **Caveat** | Authentication can be finicky; test thoroughly |

```bash
# Install
brew install himalaya

# Configure (~/.config/himalaya/config.toml)
# Supports multiple accounts

# List emails
himalaya envelope list --account mymail --config /path/to/config.toml

# Read email
himalaya message read <id> --account mymail

# Send email
himalaya message send --account mymail
```

**Tips:**
- Always specify `--config` explicitly (avoids path resolution issues)
- For attachments, Python `smtplib` is more reliable than Himalaya's MML format
- Test with `--dry-run` before enabling automated email actions

### Alternatives
- **mutt/neomutt** — Battle-tested but complex configuration
- **Python smtplib/imaplib** — Most flexible, write your own wrapper
- **msmtp + fetchmail** — Unix philosophy, separate send/receive

---

## Web Scraping

### Recommended: Puppeteer + Stealth Plugin

| Aspect | Details |
|--------|---------|
| **Why** | Full browser rendering, handles JavaScript-heavy sites |
| **Anti-detection** | Stealth plugin bypasses common bot detection |
| **Cost** | Free (open source) |
| **Caveat** | Heavyweight; use simple HTTP for API-like endpoints |

```bash
# Install
npm install puppeteer-extra puppeteer-extra-plugin-stealth

# Usage (in Node.js script)
# See your scraper scripts for patterns
```

**Tips:**
- Use `safe_curl.sh` for simple API calls (weather, finance data)
- Only use Puppeteer for sites that require JavaScript rendering
- Always respect robots.txt and rate limits
- Store scraped results locally; don't re-scrape unnecessarily

### Alternatives
- **Playwright** — Multi-browser, better API, but larger
- **curl + jq** — For JSON APIs, nothing beats simplicity
- **wget** — For bulk downloads

---

## Image Generation

### Recommended: FLUX.1-schnell (Local Diffusion)

| Aspect | Details |
|--------|---------|
| **Why** | High quality, runs locally on Apple Silicon |
| **Privacy** | 100% local |
| **Cost** | Free (model download ~35GB) |
| **Speed** | ~5-7 minutes per image on M4 (4 steps) |
| **Caveat** | Needs 16GB+ RAM; slow compared to cloud |

```bash
# Setup (one-time)
python3 -m venv ~/venvs/imagegen
source ~/venvs/imagegen/bin/activate
pip install diffusers torch

# Usage via wrapper script
python3 flux_generate.py "a sunset over mountains" output.png --steps 4
```

### Alternatives
- **Stable Diffusion (local)** — More models available, similar hardware requirements
- **DALL-E / Midjourney (cloud)** — Much faster, higher quality, but cloud + cost
- **Ollama vision models** — For image understanding, not generation

---

## Calendar & Reminders

### Recommended: Native OS Integration

| Platform | Calendar | Reminders |
|----------|----------|-----------|
| **macOS** | `icalBuddy` or AppleScript | OpenClaw `remindctl` skill |
| **Linux** | `calcurse` or `khal` | `todoman` or Taskwarrior |

```bash
# macOS Calendar (via icalBuddy)
brew install ical-buddy
icalBuddy -f eventsToday

# macOS Reminders (via OpenClaw skill)
# Built-in skill handles list, add, complete, delete
```

**Tip:** For iCloud Calendar/Reminders on macOS, native tools are the most reliable. CalDAV libraries work but require more setup.

---

## Finance Data

### Recommended: Yahoo Finance + CoinGecko (Free APIs)

| Source | Data | Auth | Rate Limit |
|--------|------|------|-----------|
| Yahoo Finance | Stocks, ETFs, commodities | No API key needed | ~2000/day |
| CoinGecko | Cryptocurrency prices | No API key needed | 30/min |

```bash
# Stock price (via safe_curl.sh)
safe_curl.sh "https://query1.finance.yahoo.com/v8/finance/chart/AAPL?interval=1d"

# Crypto price
safe_curl.sh "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd"
```

**Tip:** Use a Mozilla User-Agent header for Yahoo Finance to avoid blocks.

---

## Document Conversion

### Recommended: Pandoc

| Aspect | Details |
|--------|---------|
| **Why** | Universal document converter, incredible format support |
| **Formats** | Markdown ↔ PDF, DOCX, PPTX, HTML, LaTeX, EPUB... |
| **Cost** | Free (open source) |

```bash
brew install pandoc

# Markdown to PDF
pandoc notes.md -o notes.pdf

# Markdown to PowerPoint
pandoc presentation.md -o slides.pptx
```

**Security note:** Never use `--extract-media` with untrusted documents (potential path traversal).

---

## JSON Processing

### Recommended: jq

Essential for parsing API responses, processing logs, and building data pipelines.

```bash
brew install jq

# Parse JSON response
echo '{"temp": 22.5}' | jq '.temp'

# Filter log entries
jq 'select(.level == "error")' app.jsonl
```

---

## Video/Audio Processing

### Recommended: ffmpeg + yt-dlp

```bash
brew install ffmpeg yt-dlp

# Convert audio format
ffmpeg -i input.wav -c:a libmp3lame output.mp3

# Download audio from video (user-approved URLs only!)
yt-dlp -x --audio-format mp3 -o output.mp3 "https://..."
```

**Security:** Only download from URLs explicitly provided by the user. Never auto-process URLs from external sources.

---

## Local LLM Inference

### Recommended: Ollama

| Aspect | Details |
|--------|---------|
| **Why** | Simplest local LLM setup, great model library |
| **Models** | Llama 3, Qwen, Mistral, Gemma, and many more |
| **RAM** | 7B model ≈ 4GB, 27B model ≈ 17GB |

```bash
brew install ollama
ollama pull qwen2.5:7b

# Optimize for limited RAM
export OLLAMA_MAX_LOADED_MODELS=1
export OLLAMA_KEEP_ALIVE=60s
```

---

## Summary Table

| Category | Recommended Tool | Local? | Cost |
|----------|-----------------|--------|------|
| TTS | Piper | ✅ | Free |
| STT | Faster-Whisper | ✅ | Free |
| Email | Himalaya | ✅* | Free |
| Scraping | Puppeteer + Stealth | ✅ | Free |
| Image Gen | FLUX.1-schnell | ✅ | Free |
| Calendar | OS-native tools | ✅ | Free |
| Finance | Yahoo Finance + CoinGecko | ❌ | Free |
| Documents | Pandoc | ✅ | Free |
| JSON | jq | ✅ | Free |
| Audio/Video | ffmpeg + yt-dlp | ✅ | Free |
| Local LLM | Ollama | ✅ | Free |

*Connects to external IMAP/SMTP servers by nature, but runs locally.
