#!/bin/bash

# OpenClaw Monitoring & Maintenance Script
# Run this weekly or setup as a cron job

echo "=== OpenClaw Health Check ==="
echo ""

# Check if gateway is running
if pgrep -f "openclaw gateway" > /dev/null; then
    echo "✓ Gateway is running"
else
    echo "✗ Gateway is NOT running"
    echo "  Start with: openclaw gateway start"
    exit 1
fi

# Check disk usage
OPENCLAW_SIZE=$(du -sh ~/.openclaw 2>/dev/null | cut -f1)
echo "✓ OpenClaw directory size: $OPENCLAW_SIZE"

# Check session file sizes
echo ""
echo "=== Session Analysis ==="
SESSION_DIR="$HOME/.openclaw/agents"
if [ -d "$SESSION_DIR" ]; then
    echo "Large session files (>10MB):"
    find "$SESSION_DIR" -name "*.jsonl" -size +10M -exec ls -lh {} \; 2>/dev/null | awk '{print $9, $5}'
    
    TOTAL_SESSIONS=$(find "$SESSION_DIR" -name "*.jsonl" | wc -l)
    echo ""
    echo "Total sessions: $TOTAL_SESSIONS"
fi

# Check credentials
echo ""
echo "=== Security Check ==="
CREDS_DIR="$HOME/.openclaw/credentials"
if [ -d "$CREDS_DIR" ]; then
    echo "Checking credential file permissions..."
    find "$CREDS_DIR" -type f -not -perm 600 2>/dev/null | while read -r file; do
        echo "⚠ INSECURE: $file (should be 600)"
        chmod 600 "$file"
        echo "  Fixed: $file"
    done
fi

# Check for world-readable config
CONFIG_PERM=$(stat -c "%a" ~/.openclaw/config.jsonc 2>/dev/null || stat -f "%OLp" ~/.openclaw/config.jsonc 2>/dev/null)
if [ "$CONFIG_PERM" != "600" ]; then
    echo "⚠ Config file permissions: $CONFIG_PERM (should be 600)"
    chmod 600 ~/.openclaw/config.jsonc
    echo "  Fixed: config.jsonc"
else
    echo "✓ Config file permissions correct"
fi

# Check for updates
echo ""
echo "=== Update Check ==="
CURRENT_VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
echo "Current version: $CURRENT_VERSION"
echo "Run 'npm update -g openclaw' to update"

# Usage stats (if available)
echo ""
echo "=== Usage Statistics ==="
echo "Run these commands to check usage:"
echo "  openclaw /status    # System status and token usage"
echo "  openclaw /cost      # Detailed cost breakdown"
echo ""

# Maintenance recommendations
echo "=== Maintenance Recommendations ==="

# Check for old sessions
OLD_SESSIONS=$(find "$SESSION_DIR" -name "*.jsonl" -mtime +60 2>/dev/null | wc -l)
if [ "$OLD_SESSIONS" -gt 0 ]; then
    echo "⚠ Found $OLD_SESSIONS sessions older than 60 days"
    echo "  Consider pruning: openclaw session prune --older-than 60d"
fi

# Check workspace size
WORKSPACE_SIZE=$(du -sh ~/.openclaw/workspace 2>/dev/null | cut -f1)
echo "Workspace size: $WORKSPACE_SIZE"

# Log file check
if [ -d ~/.openclaw/logs ]; then
    LOG_SIZE=$(du -sh ~/.openclaw/logs 2>/dev/null | cut -f1)
    echo "Logs size: $LOG_SIZE"
    
    if [[ $LOG_SIZE =~ ([0-9]+)M ]] && [ "${BASH_REMATCH[1]}" -gt 100 ]; then
        echo "⚠ Large log files detected"
        echo "  Consider rotating: find ~/.openclaw/logs -name '*.log' -mtime +30 -delete"
    fi
fi

echo ""
echo "=== Health Check Complete ==="
