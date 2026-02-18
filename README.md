# OpenClaw Secure Deployment Scripts

Complete automation scripts for deploying OpenClaw with security and cost optimization.

## 🚀 Quick Start

### One-Command Deployment

```bash
chmod +x deploy-openclaw.sh
./deploy-openclaw.sh
```

This interactive wizard will:
- Install Node.js and OpenClaw
- Configure security (firewall, permissions, etc.)
- Setup cost optimization (Anthropic/Kimi/DeepSeek/Ollama)
- Create systemd service (Linux)
- Guide you through WhatsApp setup

## 📁 Scripts Included

### 1. `deploy-openclaw.sh` (Main Script)
**What it does:** Complete automated deployment with interactive wizard

**Use case:** First-time setup or client deployments

**Features:**
- Detects OS (Linux/Mac)
- Installs dependencies
- Configures security levels
- Sets up cost optimization
- Creates system service
- Generates secure configs

**Usage:**
```bash
./deploy-openclaw.sh
```

---

### 2. `setup-openclaw.sh` (Base Installation)
**What it does:** Minimal secure setup without cost optimization

**Use case:** When you want just the base installation

**Usage:**
```bash
./setup-openclaw.sh
```

**What you get:**
- OpenClaw installed
- Secure file permissions
- Base configuration
- Ready for channel setup

---

### 3. `setup-whatsapp.sh` (WhatsApp Channel)
**What it does:** Configures WhatsApp with allowlist security

**Prerequisites:** Base installation complete, gateway running

**Usage:**
```bash
./setup-whatsapp.sh
```

**Steps:**
1. Prompts for client's phone number
2. Updates config with allowlist
3. Guides through QR code pairing
4. Secures credentials

---

### 4. `setup-cost-optimization.sh` (Cost Reduction)
**What it does:** Adds hybrid model routing to cut API costs 60-80%

**Usage:**
```bash
./setup-cost-optimization.sh
```

**Strategies:**
1. **Anthropic only** - Smart routing (Haiku/Sonnet/Opus)
2. **Kimi hybrid** - 60-80% cost reduction
3. **DeepSeek hybrid** - 70-85% cost reduction  
4. **Ollama local** - Zero API costs (requires GPU)

---

### 5. `monitor-openclaw.sh` (Health Check)
**What it does:** Weekly maintenance checks

**Usage:**
```bash
./monitor-openclaw.sh
```

**Checks:**
- Gateway status
- Disk usage
- Large session files
- Security permissions
- Update availability
- Maintenance recommendations

**Automate it:**
```bash
# Add to crontab for weekly checks
crontab -e
# Add this line:
0 9 * * 1 /path/to/monitor-openclaw.sh
```

---

### 6. `manage-skills.sh` (Skill Security)
**What it does:** Safely install and audit skills

**Usage:**
```bash
./manage-skills.sh
```

**Features:**
- List installed skills
- Security audit (checks for shell exec, eval, etc.)
- Safe installation with code review
- Remove skills
- Audit all skills at once

**Security checks:**
- Shell execution patterns
- Network calls
- Filesystem access
- Dangerous eval() usage
- Code preview before installation

---

## 🎯 Common Workflows

### New Client Setup (VPS)

```bash
# 1. Clone/download these scripts to your VPS
# 2. Set API key
export ANTHROPIC_API_KEY="sk-ant-..."

# 3. Run complete deployment
./deploy-openclaw.sh
# Select: 1 (VPS), 1 (Maximum Security), 2 (Kimi hybrid)

# 4. Setup WhatsApp
./setup-whatsapp.sh

# 5. Start gateway
sudo systemctl start openclaw-gateway

# 6. Test
openclaw /status
```

**Result:**
- 24/7 availability
- Maximum security
- 60-80% cost reduction
- ~$50-100/month for power user

---

### Personal Setup (Mac Mini)

```bash
# 1. Set API key
export ANTHROPIC_API_KEY="sk-ant-..."

# 2. Run deployment
./deploy-openclaw.sh
# Select: 2 (Mac Mini), 2 (Balanced Security), 4 (Ollama)

# 3. Setup WhatsApp
./setup-whatsapp.sh

# 4. Start gateway
openclaw gateway start

# 5. Keep Mac awake
# System Settings → Energy → Prevent sleeping when display is off
```

**Result:**
- Home server control
- Zero API costs (local models)
- Privacy-first

---

### Development/Testing

```bash
# Quick minimal setup
./setup-openclaw.sh

# Or just use deploy wizard with minimal settings
./deploy-openclaw.sh
# Select: 3 (Development), 3 (Minimal), 1 (Anthropic only)
```

---

## 🔒 Security Features

### Implemented by Default

✅ Gateway bound to `127.0.0.1` (not exposed to internet)
✅ File permissions: `700` for dirs, `600` for sensitive files
✅ WhatsApp allowlist (only approved numbers)
✅ Shell/browser tools disabled initially
✅ No auto-skill installation
✅ Credentials encrypted
✅ mDNS broadcasting disabled

### VPS-Specific Hardening

✅ UFW firewall (SSH only)
✅ Systemd service (auto-restart)
✅ Non-root user execution
✅ Tailscale recommended for remote access

---

## 💰 Cost Optimization Results

### Anthropic Only (Smart Routing)
- Light user: $30-50/month
- Moderate: $80-120/month  
- Power: $150-250/month

### Hybrid with Kimi
- Light user: $15-25/month
- Moderate: $40-60/month
- Power: $60-100/month
- **Savings: 60-80%**

### Hybrid with DeepSeek
- Light user: $10-20/month
- Moderate: $30-50/month
- Power: $50-80/month
- **Savings: 70-85%**

### Local with Ollama
- API costs: $0/month
- Hardware: GPU recommended
- Fallback to Claude for complex tasks

---

## 📊 Monitoring

### Check Usage
```bash
openclaw /status      # System health + token usage
openclaw /cost        # Detailed cost breakdown
```

### Weekly Health Check
```bash
./monitor-openclaw.sh
```

### Alerts Setup
Configure in Anthropic Console:
- 50% of monthly budget → Early warning
- 80% of monthly budget → Serious alert  
- 95% of monthly budget → Final warning

---

## 🔧 Troubleshooting

### Gateway won't start
```bash
# Check logs
tail -f ~/.openclaw/logs/gateway.log

# Check if port is in use
lsof -i :18789

# Restart
openclaw gateway stop
openclaw gateway start
```

### WhatsApp keeps disconnecting
```bash
# Check credentials
ls -la ~/.openclaw/credentials/whatsapp/

# Re-pair
openclaw channel remove whatsapp
./setup-whatsapp.sh
```

### Costs too high
```bash
# Check which conversations are expensive
openclaw /usage by-conversation

# Enable aggressive context optimization
./setup-cost-optimization.sh

# Switch to cheaper model tier
# Edit ~/.openclaw/config.jsonc
# Change default model to claude-haiku-4-5
```

### Large session files
```bash
# Find big sessions
find ~/.openclaw/agents -name "*.jsonl" -size +50M

# Prune old sessions
openclaw session prune --older-than 30d

# Or reset specific conversation
openclaw /reset
```

---

## 🛠 Customization

### Edit Configuration

```bash
# Main config
nano ~/.openclaw/config.jsonc

# Restart to apply
openclaw gateway restart
```

### Add More Channels

```bash
# Telegram
openclaw channel add telegram

# Discord
openclaw channel add discord

# Slack
openclaw channel add slack
```

### Install Skills

```bash
# Use secure skill manager
./manage-skills.sh

# Select option 3 (Install with security review)
```

---

## 📋 Files Created

```
~/.openclaw/
├── config.jsonc              # Main configuration
├── config.jsonc.backup       # Original backup
├── credentials/              # API keys, channel tokens
│   └── whatsapp/            # WhatsApp session
├── agents/                   # Agent state
│   └── default/
│       └── sessions/         # Conversation history
├── skills/                   # Installed skills
├── workspace/                # Agent working directory
└── logs/                     # Gateway logs
```

---

## 🆘 Support

### Official Resources
- OpenClaw Docs: https://docs.openclaw.ai
- GitHub: https://github.com/openclaw/openclaw
- Discord: https://discord.gg/openclaw

### These Scripts
- Report issues: Create GitHub issue
- Questions: Discord #support channel

---

## 📝 Notes for Upwork Clients

### What You're Getting

✅ **Secure Setup**
- No exposed ports
- Encrypted credentials
- File permissions locked down
- Firewall configured

✅ **Cost Optimized**
- 60-80% savings vs default
- Budget limits configured
- Usage monitoring enabled
- Predictable monthly costs

✅ **Production Ready**
- 24/7 availability (VPS)
- Auto-restart on failure
- System service configured
- Monitoring scripts included

### Included Documentation
- This README
- Configuration comments in all scripts
- Client handoff guide in main deployment
- Weekly maintenance checklist

### Ongoing Maintenance
Run weekly:
```bash
./monitor-openclaw.sh
```

Monthly:
```bash
npm update -g openclaw
./monitor-openclaw.sh
openclaw session prune --older-than 60d
```

---

## ⚠️ Important Notes

1. **API Keys**: Never commit API keys to git. Use environment variables.

2. **Credentials**: The `~/.openclaw/credentials/` directory contains sensitive auth tokens. Keep it secure (permissions are set to 700 by scripts).

3. **Backups**: Original config is backed up to `config.jsonc.backup`. VPS deployments should setup automated backups of `~/.openclaw/` directory.

4. **Updates**: Run `npm update -g openclaw` monthly to get security patches.

5. **Skills**: ALWAYS audit skills before installation using `./manage-skills.sh`. Skills are executable code with full system access.

---

## 🎓 Learning Resources

### Understanding the Architecture
Read: `openclaw-secure-setup-guide.md` (Part 1)

### Cost Optimization Deep Dive  
Read: `openclaw-secure-setup-guide.md` (Part 3 & 5)

### Security Best Practices
Read: `openclaw-secure-setup-guide.md` (Part 2)

---

## License

These scripts are provided as-is for OpenClaw deployment. OpenClaw itself is open-source under its own license.
