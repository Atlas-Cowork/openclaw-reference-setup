#!/bin/bash
# =============================================================================
# outbox_sync.sh — Sync files FROM agent workspace TO iCloud Drive
# =============================================================================
#
# Purpose:
#   Push files that the agent generated (reports, audio, images) into
#   an iCloud Drive folder so the user can access them on their phone.
#
# Requirements:
#   - macOS with iCloud Drive enabled
#   - rsync
#
# Usage:
#   ./outbox_sync.sh
#
# Recommended cron: every 10 minutes
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration — Customize these paths
# ---------------------------------------------------------------------------

# Agent workspace source
WORKSPACE_OUTBOX="${WORKSPACE_OUTBOX:-/Users/AGENT_USER/.openclaw/workspace/outbox}"

# iCloud Drive destination folder
ICLOUD_OUTBOX="${ICLOUD_OUTBOX:-/Users/ADMIN_USER/Library/Mobile Documents/com~apple~CloudDocs/Assistant/outbox}"

# Log file
LOG_FILE="${LOG_FILE:-/Users/AGENT_USER/.openclaw/logs/outbox_sync.log}"

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------

if [[ ! -d "$WORKSPACE_OUTBOX" ]]; then
    # Nothing to sync
    exit 0
fi

# Create iCloud outbox if needed
mkdir -p "$ICLOUD_OUTBOX" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Step 1: Sync files to iCloud Drive
# ---------------------------------------------------------------------------
# --archive: preserve timestamps
# --ignore-existing: don't overwrite files already synced
# --remove-source-files: clean up workspace outbox after successful sync
#   (remove this flag if you want to keep local copies)

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) Starting outbox sync..." >> "$LOG_FILE"

rsync --archive \
      --ignore-existing \
      --exclude='.DS_Store' \
      "$WORKSPACE_OUTBOX/" \
      "$ICLOUD_OUTBOX/"

# ---------------------------------------------------------------------------
# Step 2: Optional cleanup — remove successfully synced files
# ---------------------------------------------------------------------------
# Uncomment the following to auto-clean the outbox after sync.
# Be careful: only enable this once you've confirmed sync works reliably.

# find "$WORKSPACE_OUTBOX" -type f -not -name '.gitkeep' -delete

# ---------------------------------------------------------------------------
# Step 3: Log completion
# ---------------------------------------------------------------------------

SYNCED=$(find "$ICLOUD_OUTBOX" -type f -newer "$LOG_FILE" 2>/dev/null | wc -l | tr -d ' ')
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) Sync complete. Files in outbox: $SYNCED" >> "$LOG_FILE"
