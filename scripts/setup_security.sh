#!/bin/bash
# =============================================================================
# setup_security.sh — Security Hardening for OpenClaw
# =============================================================================
#
# This script sets up the basic security layers for a production OpenClaw
# installation. Review each section before running. Designed for macOS but
# includes Linux alternatives in comments.
#
# Usage:
#   chmod +x setup_security.sh
#   ./setup_security.sh [--dry-run]
#
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration — Customize these variables for your setup
# ---------------------------------------------------------------------------

AGENT_USER="${AGENT_USER:-agent}"
AGENT_HOME="${AGENT_HOME:-/Users/$AGENT_USER}"
WORKSPACE="${WORKSPACE:-$AGENT_HOME/.openclaw/workspace}"
CREDENTIALS_DIR="${CREDENTIALS_DIR:-$AGENT_HOME/.credentials}"
LOG_DIR="${LOG_DIR:-$AGENT_HOME/.openclaw/logs}"
CHECKSUM_DIR="${CHECKSUM_DIR:-$WORKSPACE/checksums}"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "🔍 DRY RUN — no changes will be made"
fi

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

run() {
    if $DRY_RUN; then
        echo "  [DRY RUN] $*"
    else
        "$@"
    fi
}

check_os() {
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "macos"
    else
        echo "linux"
    fi
}

# ---------------------------------------------------------------------------
# Step 1: Verify dual-user setup
# ---------------------------------------------------------------------------

echo ""
echo "═══════════════════════════════════════════════════════"
echo " Step 1: Verify Dual-User Isolation"
echo "═══════════════════════════════════════════════════════"

if id "$AGENT_USER" &>/dev/null; then
    log "✅ Agent user '$AGENT_USER' exists"
    AGENT_UID=$(id -u "$AGENT_USER")
    log "   UID: $AGENT_UID"
else
    log "❌ Agent user '$AGENT_USER' does not exist"
    log "   Create it with:"
    log "   macOS: sudo sysadminctl -addUser $AGENT_USER -password '<random>' -home $AGENT_HOME"
    log "   Linux: sudo useradd -m -s /bin/bash $AGENT_USER"
    exit 1
fi

# Check that agent user does NOT have sudo
if sudo -l -U "$AGENT_USER" 2>/dev/null | grep -q "ALL"; then
    log "⚠️  WARNING: Agent user has sudo access. This is a security risk."
    log "   Remove with: sudo visudo (delete agent's entry)"
else
    log "✅ Agent user does not have sudo access"
fi

# ---------------------------------------------------------------------------
# Step 2: Secure credential files
# ---------------------------------------------------------------------------

echo ""
echo "═══════════════════════════════════════════════════════"
echo " Step 2: Secure Credential Files"
echo "═══════════════════════════════════════════════════════"

# Create credentials directory if needed
if [[ ! -d "$CREDENTIALS_DIR" ]]; then
    log "Creating credentials directory: $CREDENTIALS_DIR"
    run mkdir -p "$CREDENTIALS_DIR"
fi

# Set directory permissions
log "Setting $CREDENTIALS_DIR to 700 (owner-only access)"
run chmod 700 "$CREDENTIALS_DIR"

# Secure all credential files
if [[ -d "$CREDENTIALS_DIR" ]]; then
    CRED_COUNT=0
    for cred_file in "$CREDENTIALS_DIR"/*; do
        if [[ -f "$cred_file" ]]; then
            log "Securing: $(basename "$cred_file") → chmod 600"
            run chmod 600 "$cred_file"
            CRED_COUNT=$((CRED_COUNT + 1))
        fi
    done
    log "✅ Secured $CRED_COUNT credential file(s)"
else
    log "ℹ️  No credential files found yet"
fi

# ---------------------------------------------------------------------------
# Step 3: Create log directory
# ---------------------------------------------------------------------------

echo ""
echo "═══════════════════════════════════════════════════════"
echo " Step 3: Create Log Directory"
echo "═══════════════════════════════════════════════════════"

if [[ ! -d "$LOG_DIR" ]]; then
    log "Creating log directory: $LOG_DIR"
    run mkdir -p "$LOG_DIR"
fi
run chmod 750 "$LOG_DIR"
log "✅ Log directory ready"

# ---------------------------------------------------------------------------
# Step 4: Set up file integrity (checksums)
# ---------------------------------------------------------------------------

echo ""
echo "═══════════════════════════════════════════════════════"
echo " Step 4: File Integrity Setup"
echo "═══════════════════════════════════════════════════════"

# Create checksum directory
if [[ ! -d "$CHECKSUM_DIR" ]]; then
    log "Creating checksum directory: $CHECKSUM_DIR"
    run mkdir -p "$CHECKSUM_DIR"
fi

# List of critical files to protect
CRITICAL_FILES=(
    "$WORKSPACE/SOUL.md"
    "$WORKSPACE/AGENTS.md"
    # Add your egress control script, cron runners, etc.:
    # "$WORKSPACE/scripts/safe_curl.sh"
    # "$WORKSPACE/scripts/briefing_cache.sh"
)

for file in "${CRITICAL_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        basename_file=$(basename "$file")
        log "Generating SHA256 for: $basename_file"
        if ! $DRY_RUN; then
            shasum -a 256 "$file" > "$CHECKSUM_DIR/${basename_file}.sha256"
        else
            echo "  [DRY RUN] shasum -a 256 $file > $CHECKSUM_DIR/${basename_file}.sha256"
        fi
    else
        log "⚠️  File not found (skipping): $file"
    fi
done

log "✅ Checksums generated"

# ---------------------------------------------------------------------------
# Step 5: Set immutable flags on critical files
# ---------------------------------------------------------------------------

echo ""
echo "═══════════════════════════════════════════════════════"
echo " Step 5: Immutable Flags (uchg)"
echo "═══════════════════════════════════════════════════════"

OS=$(check_os)

for file in "${CRITICAL_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        basename_file=$(basename "$file")
        if [[ "$OS" == "macos" ]]; then
            log "Setting uchg on: $basename_file"
            run chflags uchg "$file"
        else
            log "Setting chattr +i on: $basename_file"
            run sudo chattr +i "$file"
        fi
    fi
done

# Also protect checksum files
for sha_file in "$CHECKSUM_DIR"/*.sha256; do
    if [[ -f "$sha_file" ]]; then
        basename_file=$(basename "$sha_file")
        if [[ "$OS" == "macos" ]]; then
            log "Setting uchg on: $basename_file"
            run chflags uchg "$sha_file"
        else
            log "Setting chattr +i on: $basename_file"
            run sudo chattr +i "$sha_file"
        fi
    fi
done

log "✅ Immutable flags set"

# ---------------------------------------------------------------------------
# Step 6: Create file_watchdog base config
# ---------------------------------------------------------------------------

echo ""
echo "═══════════════════════════════════════════════════════"
echo " Step 6: File Watchdog Configuration"
echo "═══════════════════════════════════════════════════════"

WATCHDOG_CONFIG="$WORKSPACE/scripts/file_watchdog.conf"

if ! $DRY_RUN; then
    cat > "$WATCHDOG_CONFIG" << 'WATCHDOG_EOF'
# file_watchdog.conf — Files to monitor for integrity
# Format: relative/path/from/workspace
# Lines starting with # are comments

# Identity files (if poisoned, all behavior changes)
SOUL.md
AGENTS.md

# Security scripts
# scripts/safe_curl.sh
# scripts/briefing_cache.sh
# scripts/briefing_cache_runner.sh

# Checksum files
# checksums/SOUL.md.sha256
# checksums/safe_curl.sh.sha256
WATCHDOG_EOF
    log "✅ Watchdog config created: $WATCHDOG_CONFIG"
else
    echo "  [DRY RUN] Would create $WATCHDOG_CONFIG"
fi

# ---------------------------------------------------------------------------
# Step 7: Secure gateway config
# ---------------------------------------------------------------------------

echo ""
echo "═══════════════════════════════════════════════════════"
echo " Step 7: Gateway Security"
echo "═══════════════════════════════════════════════════════"

GATEWAY_CONFIG="$AGENT_HOME/.openclaw/openclaw.json"
if [[ -f "$GATEWAY_CONFIG" ]]; then
    log "Setting gateway config to chmod 600"
    run chmod 600 "$GATEWAY_CONFIG"
    log "✅ Gateway config secured"
else
    log "ℹ️  Gateway config not found at $GATEWAY_CONFIG (may not be installed yet)"
fi

# LaunchAgent plist
LAUNCH_AGENT_DIR="$AGENT_HOME/Library/LaunchAgents"
if [[ -d "$LAUNCH_AGENT_DIR" ]]; then
    for plist in "$LAUNCH_AGENT_DIR"/*.plist; do
        if [[ -f "$plist" ]]; then
            log "Securing: $(basename "$plist") → chmod 600"
            run chmod 600 "$plist"
        fi
    done
    log "✅ LaunchAgent plists secured"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo ""
echo "═══════════════════════════════════════════════════════"
echo " Security Setup Complete"
echo "═══════════════════════════════════════════════════════"
echo ""
echo " ✅ Dual-user isolation verified"
echo " ✅ Credential files secured (chmod 600)"
echo " ✅ Log directory created"
echo " ✅ SHA256 checksums generated"
echo " ✅ Immutable flags set on critical files"
echo " ✅ File watchdog configured"
echo " ✅ Gateway config secured"
echo ""
echo " Next steps:"
echo "   1. Set up exec-approvals.json (see examples/)"
echo "   2. Create safe_curl.sh egress wrapper"
echo "   3. Configure cron jobs (heartbeat, watchdog, etc.)"
echo "   4. Run a purple team audit (see docs/SECURITY.md)"
echo "   5. Calculate your security score"
echo ""

if $DRY_RUN; then
    echo "🔍 This was a DRY RUN. No changes were made."
    echo "   Run without --dry-run to apply changes."
fi
