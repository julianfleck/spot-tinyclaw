# Spot VM Setup Guide

Setting up Spot on TinyClaw in a systemd-nspawn container on data.basicbold.de.

## 1. Create Container (on host)

SSH to data:
```bash
ssh -p 2323 julian@data.basicbold.de
```

### Create base container from mochi template
```bash
# Copy mochi as template (or create fresh Debian container)
sudo cp -a /var/lib/machines/mochi /var/lib/machines/spot

# Or create fresh:
sudo debootstrap --include=systemd,dbus bookworm /var/lib/machines/spot
```

### Create nspawn config
```bash
sudo tee /etc/systemd/nspawn/spot.nspawn << 'EOF'
[Exec]
PrivateUsers=pick
Capability=
NoNewPrivileges=yes
Boot=yes

[Files]
Bind=/etc/nginx/spot-apps

[Network]
Private=no
EOF
```

### Start container
```bash
sudo machinectl start spot
sudo machinectl enable spot
```

## 2. Container Setup (inside container)

```bash
# Enter container
sudo machinectl shell root@spot

# Create user
useradd -m -s /bin/bash tinyclaw
passwd tinyclaw

# Install dependencies
apt update && apt install -y \
  nodejs npm git tmux curl wget \
  build-essential python3

# Install Claude Code
su - tinyclaw
npm install -g @anthropic-ai/claude-code
```

## 3. TinyClaw Installation

As tinyclaw user:
```bash
su - tinyclaw
cd ~

# Clone the fork
git clone https://github.com/julianfleck/spot-tinyclaw.git .tinyclaw
cd .tinyclaw
npm install

# Create workspace
mkdir -p ~/tinyclaw-workspace/spot
mkdir -p ~/tinyclaw-workspace/spot/memory
```

## 4. Configuration

### Copy spot config files
```bash
cp docs/spot/SOUL.md .tinyclaw/SOUL.md
cp docs/spot/settings.json.template .tinyclaw/settings.json
```

### Edit settings.json
- Add Telegram bot token
- Verify paths

### Set up Claude Code
```bash
claude auth login
# Follow prompts to authenticate
```

### Configure git identity
```bash
git config --global user.name "Spot"
git config --global user.email "spot@julianfleck.net"
```

## 5. Migrate Content from Old Spot

From the old openclaw container, copy:

```bash
# On host, copy between containers:
sudo cp -r /var/lib/machines/openclaw/home/openclaw/.openclaw/workspace/MEMORY.md \
  /var/lib/machines/spot/home/tinyclaw/tinyclaw-workspace/spot/

sudo cp -r /var/lib/machines/openclaw/home/openclaw/.openclaw/workspace/memory \
  /var/lib/machines/spot/home/tinyclaw/tinyclaw-workspace/spot/

# Clone repos fresh or copy:
sudo cp -r /var/lib/machines/openclaw/home/openclaw/.openclaw/workspace/repos \
  /var/lib/machines/spot/home/tinyclaw/tinyclaw-workspace/spot/

# Fix permissions
sudo chown -R $(id -u tinyclaw):$(id -g tinyclaw) /var/lib/machines/spot/home/tinyclaw/
```

## 6. Create Systemd Service

```bash
sudo tee /etc/systemd/system/tinyclaw.service << 'EOF'
[Unit]
Description=TinyClaw Agent
After=network.target

[Service]
Type=simple
User=tinyclaw
WorkingDirectory=/home/tinyclaw/.tinyclaw
ExecStart=/home/tinyclaw/.tinyclaw/tinyclaw.sh start
ExecStop=/home/tinyclaw/.tinyclaw/tinyclaw.sh stop
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable tinyclaw
sudo systemctl start tinyclaw
```

## 7. Shell Access Alias

Add to local machine's shell config:
```bash
alias spot-shell='mosh --ssh="ssh -fp 2323" julian@data.basicbold.de -- bash -l -c "sudo machinectl shell tinyclaw@spot /bin/bash"'
```

## 8. Verification

```bash
# Check service status
sudo systemctl status tinyclaw

# Check logs
journalctl -u tinyclaw -f

# Test Telegram
# Send a message to your Telegram bot
```

## Container Ports

| Container | Purpose | Gateway Port |
|-----------|---------|--------------|
| openclaw  | Old Spot (OpenClaw) | 18789 |
| mochi     | Mochi (TinyClaw) | 18790 |
| spot      | New Spot (TinyClaw) | N/A (uses Claude Code) |

## Troubleshooting

### Cron/Heartbeat Issues
Check heartbeat.md exists and has content:
```bash
cat ~/.tinyclaw/heartbeat.md
```

Check heartbeat interval in settings.json (in seconds):
```json
"monitoring": {
  "heartbeat_interval": 1800
}
```

### Permission Issues
```bash
# On host, fix ownership
sudo chown -R $(cat /etc/subuid | grep spot | cut -d: -f2):$(cat /etc/subgid | grep spot | cut -d: -f2) \
  /var/lib/machines/spot/home/tinyclaw/
```
