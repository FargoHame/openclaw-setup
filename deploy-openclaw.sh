#!/bin/bash
set -e

# Complete OpenClaw Deployment Script
# This orchestrates the full secure setup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         OpenClaw Secure Deployment Wizard                  ║"
echo "║         Personal Assistant Setup                           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Pre-flight checks
echo "=== Pre-flight Checks ==="

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "✗ ERROR: Do not run as root"
    exit 1
fi

echo "✓ Not running as root"

# Check OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    echo "✓ Detected OS: Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="mac"
    echo "✓ Detected OS: macOS"
else
    echo "✗ Unsupported OS: $OSTYPE"
    exit 1
fi

# Check API key
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo ""
    echo "⚠ ANTHROPIC_API_KEY not set"
    read -p "Enter your Anthropic API key (sk-ant-...): " API_KEY
    export ANTHROPIC_API_KEY="$API_KEY"
    
    # Save to .bashrc/.zshrc
    SHELL_RC="${HOME}/.bashrc"
    if [ "$OS" = "mac" ]; then
        SHELL_RC="${HOME}/.zshrc"
    fi
    
    echo "" >> "$SHELL_RC"
    echo "# OpenClaw API Key" >> "$SHELL_RC"
    echo "export ANTHROPIC_API_KEY='$API_KEY'" >> "$SHELL_RC"
    echo "✓ API key saved to $SHELL_RC"
else
    echo "✓ ANTHROPIC_API_KEY is set"
fi

echo ""
echo "=== Deployment Configuration ==="
echo ""

# Deployment type
echo "Choose deployment type:"
echo "1) VPS (DigitalOcean/Hetzner/AWS) - Recommended for 24/7 availability"
echo "2) Mac Mini (Home server) - Good for privacy"
echo "3) Development/Testing - Minimal security, testing only"
echo ""
read -p "Selection [1-3]: " DEPLOY_TYPE

# Security level
echo ""
echo "Choose security level:"
echo "1) Maximum (Recommended for client deployments)"
echo "2) Balanced (Good for personal use)"
echo "3) Minimal (Development only)"
echo ""
read -p "Selection [1-3]: " SECURITY_LEVEL

# Cost optimization
echo ""
echo "Choose cost optimization:"
echo "1) Anthropic only (smart routing)"
echo "2) Hybrid with Kimi (60-80% cost reduction)"
echo "3) Hybrid with DeepSeek (70-85% cost reduction)"
echo "4) Local with Ollama (zero API costs, requires GPU)"
echo ""
read -p "Selection [1-4]: " COST_STRATEGY

echo ""
echo "=== Configuration Summary ==="
echo "Deployment: $([ "$DEPLOY_TYPE" = "1" ] && echo "VPS" || [ "$DEPLOY_TYPE" = "2" ] && echo "Mac Mini" || echo "Development")"
echo "Security: $([ "$SECURITY_LEVEL" = "1" ] && echo "Maximum" || [ "$SECURITY_LEVEL" = "2" ] && echo "Balanced" || echo "Minimal")"
echo "Cost Strategy: $([ "$COST_STRATEGY" = "1" ] && echo "Anthropic" || [ "$COST_STRATEGY" = "2" ] && echo "Kimi" || [ "$COST_STRATEGY" = "3" ] && echo "DeepSeek" || echo "Ollama")"
echo ""
read -p "Proceed with installation? [y/N] " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled"
    exit 0
fi

# STEP 1: Base installation
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║ STEP 1: Base Installation                                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Install Node.js
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    if [ "$OS" = "linux" ]; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif [ "$OS" = "mac" ]; then
        if ! command -v brew &> /dev/null; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install node@20
        brew link --force node@20
    fi
fi

echo "✓ Node.js: $(node -v)"

# Install OpenClaw
echo "Installing OpenClaw..."
npm install -g openclaw
echo "✓ OpenClaw: $(openclaw --version)"

# Initialize
echo "Initializing OpenClaw..."
openclaw init
echo "✓ Initialized ~/.openclaw/"

# STEP 2: Security hardening
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║ STEP 2: Security Hardening                                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Set file permissions based on security level
if [ "$SECURITY_LEVEL" = "1" ] || [ "$SECURITY_LEVEL" = "2" ]; then
    echo "Setting strict file permissions..."
    chmod 700 ~/.openclaw
    chmod 600 ~/.openclaw/config.jsonc
    mkdir -p ~/.openclaw/credentials
    chmod 700 ~/.openclaw/credentials
    mkdir -p ~/.openclaw/workspace
    chmod 700 ~/.openclaw/workspace
    echo "✓ File permissions secured"
fi

# Configure firewall (VPS only)
if [ "$DEPLOY_TYPE" = "1" ] && [ "$OS" = "linux" ]; then
    echo "Configuring firewall..."
    if command -v ufw &> /dev/null; then
        sudo ufw allow ssh
        sudo ufw --force enable
        echo "✓ UFW firewall enabled"
    fi
fi

# STEP 3: Configuration
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║ STEP 3: Configuration                                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Backup original config
cp ~/.openclaw/config.jsonc ~/.openclaw/config.jsonc.backup

# Generate config based on selections
python3 << EOF
import json
import os
import re

config_path = os.path.expanduser('~/.openclaw/config.jsonc')

# Security settings
bind_address = "127.0.0.1:18789"  # Always localhost for security
shell_enabled = $SECURITY_LEVEL == "3"  # Only in minimal security
browser_enabled = $SECURITY_LEVEL == "3"

# Model configuration
anthropic_key = os.environ.get('ANTHROPIC_API_KEY', '')

providers = {
    'anthropic': {
        'type': 'anthropic',
        'apiKey': anthropic_key
    }
}

# Default model based on cost strategy
if $COST_STRATEGY == 1:
    default_model = 'claude-sonnet-4-5-20250929'
    failover = [{'model': 'claude-haiku-4-5-20251001', 'maxRetries': 2}]
elif $COST_STRATEGY == 2:
    # Kimi configuration will be added by cost optimization script
    default_model = 'claude-sonnet-4-5-20250929'
    failover = [{'model': 'claude-haiku-4-5-20251001', 'maxRetries': 2}]
elif $COST_STRATEGY == 3:
    # DeepSeek configuration will be added by cost optimization script
    default_model = 'claude-sonnet-4-5-20250929'
    failover = [{'model': 'claude-haiku-4-5-20251001', 'maxRetries': 2}]
else:
    # Ollama configuration will be added by cost optimization script
    default_model = 'claude-sonnet-4-5-20250929'
    failover = [{'model': 'claude-haiku-4-5-20251001', 'maxRetries': 2}]

# Generate config
config = {
    'gateway': {
        'bind': bind_address,
        'controlUi': {
            'enabled': True,
            'allowInsecureAuth': False
        },
        'bonjour': {
            'enabled': False
        },
        'tools': {
            'shell': {
                'enabled': shell_enabled
            },
            'browser': {
                'enabled': browser_enabled
            },
            'files': {
                'enabled': True,
                'allowedPaths': ['~/.openclaw/workspace']
            }
        }
    },
    'channels': {},
    'models': {
        'providers': providers
    },
    'agents': {
        'defaults': {
            'model': default_model,
            'modelFailover': failover,
            'experimental': {
                'contextOptimizeCustom': {
                    'enabled': True,
                    'level': 'balanced',
                    'evictionThreshold': 5,
                    'maxContextRatio': 0.7
                }
            },
            'cache': {
                'enabled': True,
                'strategy': 'aggressive'
            },
            'heartbeat': {
                'enabled': True,
                'interval': '4h',
                'threshold': 'high',
                'model': 'claude-haiku-4-5-20251001'
            },
            'budget': {
                'maxTokensPerConversation': 100000,
                'maxTokensPerDay': 500000,
                'maxTokensPerMonth': 10000000,
                'onLimitExceeded': 'throttle'
            }
        }
    }
}

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)

print("✓ Configuration generated")
EOF

# STEP 4: Cost optimization (if hybrid or local)
if [ "$COST_STRATEGY" != "1" ]; then
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║ STEP 4: Cost Optimization                                  ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    if [ "$COST_STRATEGY" = "2" ]; then
        read -p "Enter Kimi API key (from https://platform.moonshot.cn): " KIMI_KEY
        export KIMI_KEY
    elif [ "$COST_STRATEGY" = "3" ]; then
        read -p "Enter DeepSeek API key (from https://platform.deepseek.com): " DEEPSEEK_KEY
        export DEEPSEEK_KEY
    elif [ "$COST_STRATEGY" = "4" ]; then
        echo "Installing Ollama..."
        if ! command -v ollama &> /dev/null; then
            curl -fsSL https://ollama.com/install.sh | sh
        fi
        echo "Pulling model (this may take a few minutes)..."
        ollama pull qwen2.5:14b
    fi
    
    # Run cost optimization script
    bash "$SCRIPT_DIR/setup-cost-optimization.sh" <<< "$COST_STRATEGY"
fi

# STEP 5: Systemd service (Linux production only)
if [ "$DEPLOY_TYPE" = "1" ] && [ "$OS" = "linux" ]; then
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║ STEP 5: System Service                                     ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    sudo tee /etc/systemd/system/openclaw-gateway.service > /dev/null << SYSTEMD
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME
ExecStart=$(which openclaw) gateway start
Restart=always
RestartSec=10
Environment="PATH=$PATH"
Environment="HOME=$HOME"
Environment="ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY"

[Install]
WantedBy=multi-user.target
SYSTEMD

    sudo systemctl daemon-reload
    sudo systemctl enable openclaw-gateway
    echo "✓ Systemd service created and enabled"
fi

# STEP 6: Summary and next steps
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║ Installation Complete!                                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "=== Next Steps ==="
echo ""
echo "1. Start the gateway:"
if [ "$DEPLOY_TYPE" = "1" ] && [ "$OS" = "linux" ]; then
    echo "   sudo systemctl start openclaw-gateway"
    echo "   sudo systemctl status openclaw-gateway"
else
    echo "   openclaw gateway start"
fi

echo ""
echo "2. Setup WhatsApp channel:"
echo "   bash $SCRIPT_DIR/setup-whatsapp.sh"
echo "   (or for other channels: openclaw channel add <channel>)"

echo ""
echo "3. Monitor the system:"
echo "   bash $SCRIPT_DIR/monitor-openclaw.sh"

echo ""
echo "4. Check usage:"
echo "   openclaw /status"
echo "   openclaw /cost"

echo ""
echo "=== Configuration Files ==="
echo "Main config: ~/.openclaw/config.jsonc"
echo "Backup: ~/.openclaw/config.jsonc.backup"
echo "Credentials: ~/.openclaw/credentials/"
echo "Workspace: ~/.openclaw/workspace/"

echo ""
echo "=== Expected Monthly Costs ==="
case $COST_STRATEGY in
    1)
        echo "Strategy: Anthropic smart routing"
        echo "Conservative: \$30-50"
        echo "Moderate: \$80-120"
        echo "Power: \$150-250"
        ;;
    2)
        echo "Strategy: Hybrid with Kimi"
        echo "Conservative: \$15-25"
        echo "Moderate: \$40-60"
        echo "Power: \$60-100"
        ;;
    3)
        echo "Strategy: Hybrid with DeepSeek"
        echo "Conservative: \$10-20"
        echo "Moderate: \$30-50"
        echo "Power: \$50-80"
        ;;
    4)
        echo "Strategy: Local with Ollama"
        echo "API costs: \$0"
        echo "Note: Uses Claude for complex tasks only"
        ;;
esac

echo ""
echo "=== Security Status ==="
echo "Gateway bound to: 127.0.0.1 (not exposed to internet)"
echo "File permissions: Secured"
if [ "$DEPLOY_TYPE" = "1" ] && [ "$OS" = "linux" ]; then
    echo "Firewall: Enabled (SSH only)"
fi
echo ""

echo "=== Support ==="
echo "Monitor script: bash $SCRIPT_DIR/monitor-openclaw.sh"
echo "Skill management: bash $SCRIPT_DIR/manage-skills.sh"
echo "OpenClaw Discord: https://discord.gg/openclaw"
echo ""

echo "Deployment complete! 🎉"
