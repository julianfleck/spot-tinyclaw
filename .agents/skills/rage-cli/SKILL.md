---
name: rage-cli
description: Interact with the RAGE substrate via CLI for knowledge management, semantic search, and frame operations.
allowed-tools: Bash(rage:*), Bash(cd:*), Bash(source:*)
---

# RAGE CLI Skill

RAGE (Recursive Agentic Graph Embeddings) is a knowledge substrate that stores typed frames with semantic relationships. Use this skill for persistent memory, knowledge organization, and retrieval.

## Prerequisites

The RAGE substrate must be running:
```bash
cd /home/openclaw/.openclaw/workspace/repos/rage-substrate
./scripts/server status  # Check if running
./scripts/server start   # Start without auth
```

Activate the environment:
```bash
cd /home/openclaw/.openclaw/workspace/repos/rage-substrate
source .venv/bin/activate
```

## Core Commands

### Navigation

```bash
# Go to a territory (bare words work)
rage go research          # Navigate to #research
rage go /                 # Root - list all territories
rage go frm_abc123        # Navigate to specific frame

# Navigate hierarchy
rage back                 # Go back in history
```

### Querying

```bash
# List frames at current location
rage list                 # Current location
rage list --limit 50      # More results
rage list --json          # JSON output

# Semantic search
rage find "attention mechanisms"        # Search everywhere
rage find "phase dynamics" --limit 5    # Limit results

# Temporal filters (filter by recency)
rage find "meeting notes" --filter "5m"      # Last 5 minutes
rage find "decisions" --filter "2h"          # Last 2 hours
rage find "research" --filter "7d"           # Last 7 days
rage find "project" --filter "1M"            # Last 1 month (uppercase M)
rage find "anything" --filter "today"        # Today only
rage find "anything" --filter "yesterday"    # Yesterday only

# Combined filters (territory + time)
rage find "insight" --filter "/research?5m"  # Research territory, last 5 min

# Get frame content
rage get frm_abc123       # Full content
rage get frm_abc123 --json  # JSON with metadata

# Show hierarchy
rage tree                 # Tree from current location
```

### Territories

```bash
rage territories list     # List all territories with counts
```

### Adding Content

```bash
# Add with semantic decomposition (creates claims, evidence, etc.)
rage add "Long content here..." --to research
rage add document.md --to research    # Ingest file

# Quick notes (no decomposition, defaults to #notes)
rage note "Quick thought"
rage note "Meeting notes" --to meetings
```

### Status

```bash
rage status               # Substrate metrics (frames, energy, entropy)
rage status --json        # JSON format
```

## Frame Types

RAGE uses typed frames from a dynamic registry:
- **claim**: Assertions or statements of belief
- **evidence**: Data supporting claims
- **observation**: Factual notes
- **question**: Open questions
- **decision**: Choices made
- **context**: Background information
- **definition**: Term definitions
- **method**: Procedures or approaches

## Territories

Territories are semantic regions. Use `#` prefix:
- `#research` - Research content
- `#notes` - Quick notes (default for `rage note`)
- `#conversations` - Chat history
- `#inbox` - Default fallback

## Output Formats

Most commands support `--json` for machine-readable output:
```bash
rage list --json | jq '.frames[].title'
rage get frm_abc123 --json | jq '.frame.content'
rage find "query" --json | jq '.results[].similarity'
```

## Timestamps

All frames include `created_at`. Get with:
```bash
rage get frm_abc123 --json | jq '.frame.created_at'
```

## Example Workflow

```bash
# 1. Check status
rage status

# 2. Add research document with decomposition
rage add paper.md --to research

# 3. Navigate to research territory
rage go research

# 4. Search for specific topics
rage find "attention mechanisms"

# 5. Get details on a result
rage get frm_abc123

# 6. Add a quick note
rage note "Remember to follow up on X"
```

## WebSocket Server

The RAGE substrate also runs a WebSocket server for real-time integration:
```bash
./scripts/server start    # ws://0.0.0.0:8765
./scripts/server stop
./scripts/server restart
./scripts/server status
./scripts/server logs     # View logs
```

## Bridge (OpenClaw Integration)

Sync conversations to RAGE:
```bash
python scripts/openclaw-bridge.py --backfill --limit 5
```

## Database Location

Default: `substrate.db` in repo root. Override with:
```bash
rage status --db /path/to/other.db
```

## Tips

1. **Bare words work**: `rage go inbox` = `rage go #inbox`
2. **Decomposition is automatic**: `rage add` extracts semantic frames
3. **Notes are quick**: `rage note` skips decomposition
4. **JSON for scripting**: Add `--json` to any command
5. **Timestamps included**: All frames have `created_at`
