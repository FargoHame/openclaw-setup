# openclaw-setup

Bash scripts for deploying OpenClaw securely on Linux or macOS — with cost optimization, WhatsApp integration, and a monitoring setup.

## Scripts

| Script | Purpose |
|--------|---------|
| `deploy-openclaw.sh` | Interactive wizard — full deployment in one command |
| `setup-openclaw.sh` | Minimal base install without cost optimization |
| `setup-whatsapp.sh` | WhatsApp channel setup with allowlist security |
| `setup-cost-optimization.sh` | Hybrid model routing (60–85% cost reduction) |
| `monitor-openclaw.sh` | Health checks, disk usage, permission audits |
| `manage-skills.sh` | Safe skill installation with security review |

## Quick Start

```bash
chmod +x deploy-openclaw.sh
./deploy-openclaw.sh
```

The wizard detects your OS, installs dependencies, configures security, sets up a systemd service, and walks you through WhatsApp pairing.

## Cost Optimization

| Strategy | Savings |
|----------|---------|
| Anthropic smart routing (Haiku/Sonnet/Opus) | baseline |
| Kimi hybrid | 60–80% |
| DeepSeek hybrid | 70–85% |
| Ollama local | ~100% (GPU required) |

## Security Defaults

- Gateway bound to `127.0.0.1` only
- File permissions: `700` dirs, `600` sensitive files
- WhatsApp allowlist enforced
- Shell/browser tools disabled by default
- UFW firewall + non-root execution on VPS

## Requirements

- Linux or macOS
- Node.js 18+
- `ANTHROPIC_API_KEY` set in environment

---
