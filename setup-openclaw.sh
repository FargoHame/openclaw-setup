#!/bin/bash
set -e

# OpenClaw Secure Setup Script
# Usage: ./setup-openclaw.sh

echo "=== OpenClaw Secure Setup ==="
echo ""

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="mac"
else
    echo "Unsupported OS: $OSTYPE"
    exit 1
fi

echo "Detected OS: $OS"
echo ""

# Check if running as root (should not be)
if [ "$EUID" -eq 0 ]; then 
    echo "ERROR: Do not run this script as root"
    exit 1
fi

# Step 1: Install Node.js if needed
echo "=== Step 1: Checking Node.js ==="
if ! command -v node &> /dev/null; then
    echo "Node.js not found. Installing..."
    if [ "$OS" = "linux" ]; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif [ "$OS" = "mac" ]; then
        if ! command -v brew &> /dev/null; then
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install node@20
        brew link node@20
    fi
else
    NODE_VERSION=$(node -v)
    echo "Node.js already installed: $NODE_VERSION"
fi

# Step 2: Install OpenClaw
echo ""
echo "=== Step 2: Installing OpenClaw ==="
npm install -g openclaw
echo "OpenClaw installed: $(openclaw --version)"

# Step 3: Initialize OpenClaw
echo ""
echo "=== Step 3: Initializing OpenClaw ==="
openclaw init

# Step 4: Secure file permissions
echo ""
echo "=== Step 4: Setting secure file permissions ==="
chmod 700 ~/.openclaw
chmod 600 ~/.openclaw/config.jsonc
mkdir -p ~/.openclaw/credentials
chmod 700 ~/.openclaw/credentials
mkdir -p ~/.openclaw/workspace
chmod 700 ~/.openclaw/workspace

echo "Permissions secured"

# Step 5: Backup original config
cp ~/.openclaw/config.jsonc ~/.openclaw/config.jsonc.backup

# Step 6: Create secure config
echo ""
echo "=== Step 5: Creating secure configuration ==="

cat > ~/.openclaw/config.jsonc << 'EOF'
{
  "gateway": {
    // SECURITY: Bind to localhost only (not exposed to internet)
    "bind": "127.0.0.1:18789",
    
    "controlUi": {
      "enabled": true,
      "allowInsecureAuth": false
    },
    
    // Disable broadcasting
    "bonjour": {
      "enabled": false
    },
    
    // Minimal tools enabled
    "tools": {
      "shell": {
        "enabled": false  // DISABLED for security
      },
      "browser": {
        "enabled": false  // DISABLED for security
      },
      "files": {
        "enabled": true,
        "allowedPaths": [
          "~/.openclaw/workspace"  // Restricted to workspace only
        ]
      }
    }
  },
  
  "channels": {
    // Channels will be added via CLI
  },
  
  "models": {
    "providers": {
      "anthropic": {
        "type": "anthropic",
        "apiKey": "${ANTHROPIC_API_KEY}"  // Will be set via env var
      }
    }
  },
  
  "agents": {
    "defaults": {
      // Smart model routing for cost optimization
      "model": "claude-sonnet-4-5-20250929",
      
      "modelFailover": [
        {
          "model": "claude-haiku-4-5-20251001",
          "maxRetries": 2
        }
      ],
      
      // Context optimization to reduce token costs
      "experimental": {
        "contextOptimizeCustom": {
          "enabled": true,
          "level": "balanced",
          "evictionThreshold": 5,
          "maxContextRatio": 0.7
        }
      },
      
      // Enable prompt caching (90% discount)
      "cache": {
        "enabled": true,
        "strategy": "aggressive"
      },
      
      // Heartbeat optimization
      "heartbeat": {
        "enabled": true,
        "interval": "4h",
        "threshold": "high",
        "model": "claude-haiku-4-5-20251001"
      },
      
      // Budget controls
      "budget": {
        "maxTokensPerConversation": 100000,
        "maxTokensPerDay": 500000,
        "maxTokensPerMonth": 10000000,
        "onLimitExceeded": "throttle"
      }
    }
  }
}
EOF

echo "Secure config created"

# Step 7: Setup systemd service (Linux only)
if [ "$OS" = "linux" ]; then
    echo ""
    echo "=== Step 6: Creating systemd service ==="
    
    sudo tee /etc/systemd/system/openclaw-gateway.service > /dev/null << EOF
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

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable openclaw-gateway
    echo "Systemd service created (not started yet)"
fi

# Step 8: Setup firewall (Linux only)
if [ "$OS" = "linux" ]; then
    echo ""
    echo "=== Step 7: Configuring firewall ==="
    
    if command -v ufw &> /dev/null; then
        sudo ufw allow ssh
        sudo ufw --force enable
        echo "UFW firewall enabled (SSH only)"
    else
        echo "UFW not found, skipping firewall setup"
    fi
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "NEXT STEPS:"
echo "1. Set your Anthropic API key:"
echo "   export ANTHROPIC_API_KEY='sk-ant-...'"
echo "   echo 'export ANTHROPIC_API_KEY=\"sk-ant-...\"' >> ~/.bashrc"
echo ""
echo "2. Add WhatsApp channel:"
echo "   openclaw channel add whatsapp"
echo ""
echo "3. Start the gateway:"
if [ "$OS" = "linux" ]; then
    echo "   sudo systemctl start openclaw-gateway"
else
    echo "   openclaw gateway start"
fi
echo ""
echo "4. Check status:"
echo "   openclaw /status"
echo ""
echo "Configuration file: ~/.openclaw/config.jsonc"
echo "Backup saved: ~/.openclaw/config.jsonc.backup"
