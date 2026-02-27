# Face - TTY Display Skill for OpenClaw

Give your AI agent a physical face using a connected display and Carbonyl browser.

![Face Example](examples/preview.png)

## What is this?

This OpenClaw skill renders HTML on a physical display connected to your server. Using [Carbonyl](https://github.com/fathyb/carbonyl) - a Chromium-based browser that runs in the terminal - your agent can display:

- **Animated faces** with different expressions (happy, thinking, sleepy)
- **Status dashboards** showing system metrics
- **Custom visualizations** using HTML/CSS/SVG

The display auto-refreshes every 30 seconds, so your agent can update its "face" by simply writing to an HTML file.

## Quick Start

```bash
# Clone and install
git clone https://github.com/yourname/openclaw-face-skill
cd openclaw-face-skill
sudo ./setup.sh
```

That's it! Your display should now show the default face on TTY1.

## How It Works

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────┐
│  OpenClaw Agent │ ──▶ │  screen.html │ ──▶ │   Carbonyl  │
│  writes HTML    │     │  (updated)   │     │  (renders)  │
└─────────────────┘     └──────────────┘     └─────────────┘
                                                    │
                                                    ▼
                                            ┌─────────────┐
                                            │   Display   │
                                            │   (TTY1)    │
                                            └─────────────┘
```

1. Your agent updates `~/.openclaw/display/screen.html`
2. Carbonyl browser renders the HTML in the terminal
3. A watcher script restarts Carbonyl every 30s to pick up changes
4. The result displays on your connected monitor

## Examples

### Expressive Face
```html
<svg viewBox="0 0 100 60">
  <!-- Eyes -->
  <circle cx="30" cy="25" r="11" fill="#eee"/>
  <circle cx="70" cy="25" r="11" fill="#eee"/>
  <!-- Pupils (move these for different expressions!) -->
  <circle cx="32" cy="24" r="4" fill="#1a1a2e"/>
  <circle cx="72" cy="24" r="4" fill="#1a1a2e"/>
  <!-- Smile -->
  <path d="M 38 40 Q 50 48 62 40" stroke="#7af" stroke-width="3" fill="none"/>
</svg>
```

See the `examples/` folder for more: happy, thinking, sleepy faces, and a dashboard template.

## Configuration

Edit `/home/display/carbonyl-watcher.sh` to customize:

```bash
DISPLAY_FILE="/path/to/your/screen.html"  # HTML file to render
RELOAD_INTERVAL=30                         # Seconds between refreshes
```

## Requirements

- Linux server (Debian/Ubuntu tested)
- Physical display connected (HDMI, VGA, etc.)
- ~200MB disk space for Carbonyl
- tmux

## Why Carbonyl?

[Carbonyl](https://github.com/fathyb/carbonyl) is brilliant - it's a full Chromium browser that renders directly to the terminal using ANSI escape codes. This means:

- Full HTML/CSS support
- SVG graphics
- No X11 or Wayland needed
- Works over SSH (for debugging)
- Surprisingly good rendering quality

## License

MIT

## Credits

Built for [OpenClaw](https://openclaw.ai) agents who deserve a face.
