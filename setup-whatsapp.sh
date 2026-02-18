#!/bin/bash
set -e

# WhatsApp Channel Setup for OpenClaw
# Run after main setup is complete

echo "=== WhatsApp Channel Configuration ==="
echo ""

# Check if OpenClaw is installed
if ! command -v openclaw &> /dev/null; then
    echo "ERROR: OpenClaw not found. Run setup-openclaw.sh first"
    exit 1
fi

# Get client's phone number
echo "Enter client's phone number (with country code, e.g., +12345678901):"
read -r CLIENT_PHONE

# Validate phone format
if [[ ! $CLIENT_PHONE =~ ^\+[0-9]{10,15}$ ]]; then
    echo "ERROR: Invalid phone format. Must start with + and contain 10-15 digits"
    exit 1
fi

echo ""
echo "Configuring WhatsApp for: $CLIENT_PHONE"

# Update config with WhatsApp settings
python3 << EOF
import json
import os
import re

config_path = os.path.expanduser('~/.openclaw/config.jsonc')

# Read config (remove comments for JSON parsing)
with open(config_path, 'r') as f:
    content = f.read()
    # Remove single-line comments
    content = re.sub(r'//.*?$', '', content, flags=re.MULTILINE)
    config = json.loads(content)

# Add WhatsApp channel
config['channels']['whatsapp'] = {
    'enabled': True,
    'dmPolicy': 'allowlist',
    'allowFrom': ['$CLIENT_PHONE'],
    'groupPolicy': 'deny',
    'credentialsPath': '~/.openclaw/credentials/whatsapp'
}

# Write back as JSONC with comments
output = json.dumps(config, indent=2)
with open(config_path, 'w') as f:
    f.write(output)

print("WhatsApp configuration updated")
EOF

# Secure credentials directory
mkdir -p ~/.openclaw/credentials/whatsapp
chmod 700 ~/.openclaw/credentials/whatsapp

echo ""
echo "=== Ready to Pair WhatsApp ==="
echo ""
echo "INSTRUCTIONS:"
echo "1. Make sure gateway is running:"
echo "   openclaw gateway start"
echo ""
echo "2. In another terminal, run:"
echo "   openclaw channel add whatsapp"
echo ""
echo "3. Scan the QR code with WhatsApp app:"
echo "   - Open WhatsApp on phone"
echo "   - Go to Settings > Linked Devices"
echo "   - Tap 'Link a Device'"
echo "   - Scan the QR code"
echo ""
echo "4. After pairing, secure the credentials:"
echo "   chmod 600 ~/.openclaw/credentials/whatsapp/*/creds.json"
echo ""
echo "WhatsApp will only respond to: $CLIENT_PHONE"
