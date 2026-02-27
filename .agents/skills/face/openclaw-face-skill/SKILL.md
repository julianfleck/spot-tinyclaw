---
name: face
description: Display an HTML canvas on a TTY using Carbonyl browser - give your AI agent a face
emoji: 🖥️
requires:
  bins: [tmux]
install: ./setup.sh
---

# Face - TTY Display for OpenClaw

This skill gives your OpenClaw agent a "face" - an HTML canvas rendered on a physical display via the Carbonyl terminal browser.

## What It Does

- Renders an HTML file on a TTY using Carbonyl (a terminal-native Chromium browser)
- Auto-refreshes every 30 seconds to show updates
- Perfect for always-on displays, dashboards, or giving your AI agent a visual presence

## Setup

1. Connect a display to your server (HDMI, VGA, etc.)
2. Run the setup script: `./setup.sh`
3. The display will show your HTML file rendered in the terminal

## Usage

Update the HTML file at `~/.openclaw/display/screen.html` to change what's displayed.

### Example: Simple Face

```html
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
  <!-- eyes -->
  <circle cx="30" cy="25" r="11" fill="#eee"/>
  <circle cx="32" cy="24" r="4" fill="#1a1a2e"/>
  <circle cx="70" cy="25" r="11" fill="#eee"/>
  <circle cx="72" cy="24" r="4" fill="#1a1a2e"/>
  <!-- smile -->
  <path d="M 38 40 Q 50 48 62 40" stroke="#7af" stroke-width="3" fill="none" stroke-linecap="round"/>
</svg>
</body>
</html>
```

### Example: Status Dashboard

```html
<!DOCTYPE html>
<html>
<head>
<style>
body { background: #1a1a2e; color: #eee; font-family: monospace; padding: 20px; }
h1 { color: #7af; }
.status { color: #8f8; }
</style>
</head>
<body>
<h1>System Status</h1>
<p class="status">All systems operational</p>
<p>Last updated: <span id="time">--</span></p>
</body>
</html>
```

## How It Works

1. **Carbonyl** is a Chromium-based browser that renders directly to the terminal
2. A **watcher script** runs Carbonyl in a loop, restarting every 30 seconds
3. The display runs in a **tmux session** for persistence
4. Updates to the HTML file appear on the next refresh cycle

## Requirements

- Linux server with a connected display
- TTY access (getty service)
- ~200MB disk space for Carbonyl

## Tips

- Use SVG for scalable graphics that look crisp at any resolution
- Dark backgrounds work best in terminal environments
- Keep animations simple - Carbonyl refreshes every 30s, not continuously
- This is your agent's "face" - get creative!
