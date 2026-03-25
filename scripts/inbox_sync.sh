#!/bin/bash
# =============================================================================
# inbox_sync.sh — Sync files FROM iCloud Drive TO agent workspace
# =============================================================================
#
# Purpose:
#   Pull files that the user dropped into an iCloud Drive folder
#   (e.g., from their phone) into the agent's workspace inbox.
#
# Requirements:
#   - macOS with iCloud Drive enabled
#   - brctl (built into macOS, manages iCloud file downloads)
#   - rsync
#
# Usage:
#   ./inbox_sync.sh
#
# Recommended cron: every 10 minutes
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration — Customize these paths
# ---------------------------------------------------------------------------

# iCloud Drive source folder (owned by admin user)
# Typical path: ~/Library/Mobile Documents/com~apple~CloudDocs/<folder>
ICLOUD_INBOX="${ICLOUD_INBOX:-/Users/ADMIN_USER/Library/Mobile Documents/com~apple~CloudDocs/Assistant/inbox}"

# Agent workspace destination
WORKSPACE_INBOX="${WORKSPACE_INBOX:-/Users/AGENT_USER/.openclaw/workspace/inbox}"

# Log file
LOG_FILE="${LOG_FILE:-/Users/AGENT_USER/.openclaw/logs/inbox_sync.log}"

# Agent user (for chown/chmod after sync)
AGENT_USER="${AGENT_USER:-agent}"

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------

if [[ ! -d "$ICLOUD_INBOX" ]]; then
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) ERROR: iCloud inbox not found: $ICLOUD_INBOX" >> "$LOG_FILE"
    exit 1
fi

# Create workspace inbox if needed
mkdir -p "$WORKSPACE_INBOX"

# ---------------------------------------------------------------------------
# Step 1: Force iCloud to download any cloud-only files
# ---------------------------------------------------------------------------
# iCloud Drive uses "lazy downloads" — files may exist as placeholders
# (.icloud files) until explicitly downloaded. brctl forces the download.

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) Starting inbox sync..." >> "$LOG_FILE"

# Download all files in the iCloud inbox folder
if command -v brctl &>/dev/null; then
    brctl download "$ICLOUD_INBOX" 2>/dev/null || true
    
    # Wait a moment for downloads to complete
    sleep 5
    
    # Check for remaining .icloud placeholder files
    PENDING=$(find "$ICLOUD_INBOX" -name ".*.icloud" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$PENDING" -gt 0 ]]; then
        echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) WARNING: $PENDING files still downloading" >> "$LOG_FILE"
    fi
else
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) WARNING: brctl not found (not macOS?)" >> "$LOG_FILE"
fi

# ---------------------------------------------------------------------------
# Step 2: Sync files to workspace
# ---------------------------------------------------------------------------
# --archive: preserve timestamps, permissions (mostly)
# --ignore-existing: don't overwrite files already in workspace
# --exclude: skip iCloud placeholder files

rsync --archive \
      --ignore-existing \
      --exclude='.*.icloud' \
      --exclude='.DS_Store' \
      "$ICLOUD_INBOX/" \
      "$WORKSPACE_INBOX/"

# ---------------------------------------------------------------------------
# Step 3: Fix permissions (iCloud files are owned by admin user)
# ---------------------------------------------------------------------------

# Make files readable/writable by agent user
chmod -R u+rw "$WORKSPACE_INBOX/" 2>/dev/null || true

# Count synced files
SYNCED=$(find "$WORKSPACE_INBOX" -type f -newer "$LOG_FILE" 2>/dev/null | wc -l | tr -d ' ')

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) Sync complete. New files: $SYNCED" >> "$LOG_FILE"
