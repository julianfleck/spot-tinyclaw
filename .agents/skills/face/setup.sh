#!/bin/bash
set -e

echo "=== Face Skill Setup ==="
echo "This will install Carbonyl and configure the TTY display."
echo ""

# Check if running as root for system setup
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo for system-wide installation:"
    echo "  sudo ./setup.sh"
    exit 1
fi

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)  CARBONYL_ARCH="amd64" ;;
    aarch64) CARBONYL_ARCH="arm64" ;;
    *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

echo "[1/5] Installing dependencies..."
apt-get update -qq
apt-get install -y -qq tmux curl tar

echo "[2/5] Downloading Carbonyl..."
CARBONYL_VERSION="0.0.3"
CARBONYL_URL="https://github.com/fathyb/carbonyl/releases/download/v${CARBONYL_VERSION}/carbonyl.linux-${CARBONYL_ARCH}.tar.gz"
mkdir -p /opt/carbonyl
curl -sL "$CARBONYL_URL" | tar -xz -C /opt/carbonyl

echo "[3/5] Creating display user..."
if ! id -u display &>/dev/null; then
    useradd -r -m -s /bin/bash display
fi

echo "[4/5] Installing display scripts..."

# Carbonyl watcher script
cat > /home/display/carbonyl-watcher.sh << 'WATCHER'
#!/bin/bash
DISPLAY_FILE="${DISPLAY_FILE:-/home/display/screen.html}"
RELOAD_INTERVAL="${RELOAD_INTERVAL:-30}"

while true; do
  /opt/carbonyl/carbonyl "file://$DISPLAY_FILE" 2>/dev/null &
  CARBONYL_PID=$!
  sleep $RELOAD_INTERVAL
  pkill -TERM -P $CARBONYL_PID 2>/dev/null
  kill -TERM $CARBONYL_PID 2>/dev/null
  sleep 0.3
done
WATCHER
chmod +x /home/display/carbonyl-watcher.sh

# Start display script
cat > /home/display/start-display.sh << 'START'
#!/bin/bash
SESSION="Display"
DISPLAY_FILE="${DISPLAY_FILE:-/home/display/screen.html}"

pkill -u display carbonyl 2>/dev/null
tmux kill-session -t "$SESSION" 2>/dev/null || true
sleep 1

tmux new-session -d -s "$SESSION" -x 240 -y 66
tmux send-keys -t "$SESSION" "DISPLAY_FILE=$DISPLAY_FILE /home/display/carbonyl-watcher.sh" C-m
tmux attach-session -t "$SESSION"
START
chmod +x /home/display/start-display.sh

# Default face
cat > /home/display/screen.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
<style>
body {
  background: #1a1a2e;
  margin: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100vh;
}
svg { width: 100vw; height: 100vh; }
</style>
</head>
<body>
<svg viewBox="0 0 100 60">
  <circle cx="30" cy="25" r="11" fill="#eee"/>
  <circle cx="32" cy="24" r="4" fill="#1a1a2e"/>
  <circle cx="70" cy="25" r="11" fill="#eee"/>
  <circle cx="72" cy="24" r="4" fill="#1a1a2e"/>
  <path d="M 38 40 Q 50 48 62 40" stroke="#7af" stroke-width="3" fill="none" stroke-linecap="round"/>
</svg>
</body>
</html>
HTML

chown -R display:display /home/display/

echo "[5/5] Configuring auto-start on TTY1..."

# Create getty override for auto-login
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << 'GETTY'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin display --noclear %I $TERM
GETTY

# Auto-start display on login
cat >> /home/display/.bash_profile << 'PROFILE'
if [ -z "$TMUX" ] && [ "$(tty)" = "/dev/tty1" ]; then
    /home/display/start-display.sh
fi
PROFILE

systemctl daemon-reload
systemctl restart getty@tty1

echo ""
echo "=== Setup Complete ==="
echo ""
echo "The display should now be running on TTY1."
echo ""
echo "To update the display, edit: /home/display/screen.html"
echo "Changes appear within 30 seconds."
echo ""
echo "Manual commands:"
echo "  Start:  sudo -u display /home/display/start-display.sh"
echo "  Stop:   sudo -u display tmux kill-session -t Display"
