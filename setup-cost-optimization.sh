#!/bin/bash
set -e

# Cost Optimization Setup for OpenClaw
# Adds hybrid model strategy to reduce costs by 60-80%

echo "=== Cost Optimization Configuration ==="
echo ""

# Menu for optimization strategy
echo "Choose optimization strategy:"
echo "1) Anthropic only (smart routing with Haiku/Sonnet/Opus)"
echo "2) Hybrid with Kimi (60-80% cost reduction)"
echo "3) Hybrid with DeepSeek (70-85% cost reduction)"
echo "4) Local models with Ollama (zero API costs)"
echo ""
read -p "Selection [1-4]: " STRATEGY

case $STRATEGY in
    1)
        echo "Selected: Anthropic smart routing"
        PROVIDER="anthropic"
        ;;
    2)
        echo "Selected: Hybrid with Kimi"
        PROVIDER="kimi"
        echo ""
        echo "You'll need a Kimi API key from: https://platform.moonshot.cn"
        read -p "Enter Kimi API key: " KIMI_KEY
        ;;
    3)
        echo "Selected: Hybrid with DeepSeek"
        PROVIDER="deepseek"
        echo ""
        echo "You'll need a DeepSeek API key from: https://platform.deepseek.com"
        read -p "Enter DeepSeek API key: " DEEPSEEK_KEY
        ;;
    4)
        echo "Selected: Local with Ollama"
        PROVIDER="ollama"
        
        # Check if Ollama is installed
        if ! command -v ollama &> /dev/null; then
            echo "Ollama not found. Installing..."
            curl -fsSL https://ollama.com/install.sh | sh
        fi
        
        echo "Pulling Qwen2.5:14b model (this may take a few minutes)..."
        ollama pull qwen2.5:14b
        ;;
    *)
        echo "Invalid selection"
        exit 1
        ;;
esac

# Generate optimized config based on selection
python3 << EOF
import json
import os
import re

config_path = os.path.expanduser('~/.openclaw/config.jsonc')

# Read existing config
with open(config_path, 'r') as f:
    content = f.read()
    content = re.sub(r'//.*?$', '', content, flags=re.MULTILINE)
    config = json.loads(content)

provider = '$PROVIDER'
anthropic_key = os.environ.get('ANTHROPIC_API_KEY', 'sk-ant-...')

# Base providers
providers = {
    'anthropic': {
        'type': 'anthropic',
        'apiKey': anthropic_key
    }
}

# Model routing based on strategy
if provider == 'anthropic':
    # Smart routing with Anthropic only
    config['agents']['defaults']['model'] = 'claude-sonnet-4-5-20250929'
    config['agents']['defaults']['modelFailover'] = [
        {'model': 'claude-haiku-4-5-20251001', 'maxRetries': 2}
    ]
    
elif provider == 'kimi':
    # Hybrid with Kimi
    providers['kimi'] = {
        'type': 'openai',
        'baseUrl': 'https://api.moonshot.cn/v1',
        'apiKey': '$KIMI_KEY'
    }
    config['agents']['defaults']['model'] = 'kimi/moonshot-v1-128k'
    config['agents']['defaults']['modelFailover'] = [
        {'model': 'claude-sonnet-4-5-20250929', 'maxRetries': 1}
    ]
    
    # Add routing rules
    config['agents']['defaults']['routing'] = {
        'simple': 'kimi/moonshot-v1-128k',
        'moderate': 'claude-sonnet-4-5-20250929',
        'complex': 'claude-opus-4-5-20251101'
    }
    
elif provider == 'deepseek':
    # Hybrid with DeepSeek
    providers['deepseek'] = {
        'type': 'openai',
        'baseUrl': 'https://api.deepseek.com/v1',
        'apiKey': '$DEEPSEEK_KEY'
    }
    config['agents']['defaults']['model'] = 'deepseek/deepseek-chat'
    config['agents']['defaults']['modelFailover'] = [
        {'model': 'claude-sonnet-4-5-20250929', 'maxRetries': 1}
    ]
    
    config['agents']['defaults']['routing'] = {
        'simple': 'deepseek/deepseek-chat',
        'moderate': 'claude-sonnet-4-5-20250929',
        'complex': 'claude-opus-4-5-20251101'
    }
    
elif provider == 'ollama':
    # Local with Ollama
    providers['ollama'] = {
        'type': 'openai',
        'baseUrl': 'http://127.0.0.1:11434/v1',
        'apiKey': 'ollama'
    }
    config['agents']['defaults']['model'] = 'ollama/qwen2.5:14b'
    config['agents']['defaults']['modelFailover'] = [
        {'model': 'claude-sonnet-4-5-20250929', 'maxRetries': 1}
    ]
    
    config['agents']['defaults']['routing'] = {
        'simple': 'ollama/qwen2.5:14b',
        'moderate': 'ollama/qwen2.5:14b',
        'complex': 'claude-sonnet-4-5-20250929'
    }

# Update providers
config['models']['providers'] = providers

# Enhanced cost optimizations
config['agents']['defaults']['experimental'] = {
    'contextOptimizeCustom': {
        'enabled': True,
        'level': 'aggressive' if provider in ['kimi', 'deepseek', 'ollama'] else 'balanced',
        'evictionThreshold': 4,
        'maxContextRatio': 0.6,
        'protectedZones': ['core', 'active_tasks'],
        'evictableTypes': ['skill_docs', 'temp_results', 'old_outputs']
    }
}

config['agents']['defaults']['cache'] = {
    'enabled': True,
    'strategy': 'aggressive'
}

config['agents']['defaults']['heartbeat'] = {
    'enabled': True,
    'interval': '6h',  # Even longer for cost optimization
    'threshold': 'high',
    'model': 'claude-haiku-4-5-20251001' if provider == 'anthropic' else config['agents']['defaults']['model']
}

# Stricter budget for cost-conscious setup
config['agents']['defaults']['budget'] = {
    'maxTokensPerConversation': 80000,
    'maxTokensPerDay': 400000,
    'maxTokensPerMonth': 8000000,  # ~\$100 max with hybrid
    'onLimitExceeded': 'throttle'
}

# Write optimized config
output = json.dumps(config, indent=2)
with open(config_path, 'w') as f:
    f.write(output)

print(f"Configuration optimized for {provider}")
EOF

echo ""
echo "=== Cost Optimization Complete ==="
echo ""
echo "Estimated monthly costs:"
case $STRATEGY in
    1)
        echo "Conservative: \$30-50"
        echo "Moderate: \$80-120"
        echo "Power user: \$150-250"
        ;;
    2|3)
        echo "Conservative: \$15-25"
        echo "Moderate: \$40-60"
        echo "Power user: \$60-100"
        echo "(60-80% reduction vs Anthropic-only)"
        ;;
    4)
        echo "API costs: \$0 (local inference)"
        echo "Note: Requires GPU for best performance"
        echo "Fallback to Claude for complex tasks"
        ;;
esac
echo ""
echo "Monitor usage with:"
echo "  openclaw /status"
echo "  openclaw /cost"
