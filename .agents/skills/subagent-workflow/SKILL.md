---
name: subagent-workflow
description: Protocol for spawning, monitoring, and coordinating sub-agents with time-bounded check-ins.
allowed-tools: sessions_spawn, sessions_list, sessions_history, sessions_send, cron
---

# Sub-Agent Workflow

Protocol for parallel work via sub-agents with proper monitoring.

## When to Use Sub-Agents

**Use sub-agents for:**
- Tasks taking >30 seconds (builds, installs, long operations)
- Parallelizable work (multiple independent tasks)
- Work that doesn't need real-time feedback
- Implementation tasks with clear specs

**Stay in main session for:**
- Quick checks (<30s)
- Decisions requiring user input
- Exploratory work needing back-and-forth

## Spawning Sub-Agents

Use Sonnet (`anthropic/claude-sonnet-4-5`) as the default model for sub-agents to ensure reliable execution. Override if the task explicitly requires a different model.

```python
sessions_spawn(
    task="Clear description of what to do",
    label="short-memorable-name",  # Required for tracking
    agentId="main",
    model="anthropic/claude-sonnet-4-5"  # Default to Sonnet
)
```

**Task description should include:**
- Specific goal
- Relevant file paths
- Success criteria
- Where to save output

## Git Identity for Sub-Agents

**CRITICAL:** Sub-agents must use proper git identity, not default to OpenClaw.

Before any git commits, sub-agents should verify identity is set:
```bash
git config user.name || git config --global user.name "Spot"
git config user.email || git config --global user.email "spot@julianfleck.net"
```

Sub-agents inherit the main agent's identity (Spot). This ensures:
- Commits are attributed correctly
- Vercel/CI systems accept pushes
- No "agent@openclaw.ai" leaking into repos

## Time-Bounded Check-Ins

**CRITICAL:** When monitoring sub-agents, create time-bounded check-ins, not perpetual crons.

### Pattern: Iteration Cycle

For a 2-hour work session with 15-minute check-ins:

```python
# Calculate end time (2 hours from now)
import time
end_time_ms = int((time.time() + 2*60*60) * 1000)

# Create bounded check-in cron
cron(
    action="add",
    job={
        "name": "iteration-checkin",
        "schedule": {
            "kind": "every",
            "everyMs": 900000,  # 15 minutes
            "endAtMs": end_time_ms  # BOUNDED
        },
        "payload": {
            "kind": "systemEvent",
            "text": "15-minute check-in. Poll sub-agents, report status to user."
        },
        "sessionTarget": "main",
        "enabled": True
    }
)
```

### Alternative: One-Shot Reminders

For simpler cases, schedule discrete check-ins:

```python
# Check in 15, 30, 45 minutes from now
for mins in [15, 30, 45]:
    cron(
        action="add",
        job={
            "name": f"checkin-{mins}m",
            "schedule": {"kind": "at", "atMs": now_ms + mins*60*1000},
            "payload": {"kind": "systemEvent", "text": f"{mins}m check-in"},
            "sessionTarget": "main",
            "deleteAfterRun": True
        }
    )
```

## Monitoring Protocol

### At Each Check-In:

1. **List active sub-agents:**
   ```python
   sessions_list(kinds=["subagent"], activeMinutes=60, messageLimit=1)
   ```

2. **Get detailed history if needed:**
   ```python
   sessions_history(sessionKey="agent:main:subagent:...", limit=3)
   ```

3. **Report status to user:**
   - Which agents are running
   - What they're working on
   - Any completions or errors
   - ETA if known

### On Sub-Agent Completion:

Sub-agents auto-announce when done. Summarize naturally:
- What was accomplished
- Key outputs (file paths, etc.)
- Any issues or next steps

## Cleanup

After work session ends:

1. **Remove bounded crons** (or let them expire via `endAtMs`)
2. **Check for orphaned sub-agents:**
   ```python
   sessions_list(kinds=["subagent"])
   ```
3. **Update memory** with session summary

## Common Mistakes

❌ **Perpetual crons** — Always set `endAtMs` or use `deleteAfterRun`
❌ **systemEvent without activity** — Only fires when main session is processing
❌ **No labels** — Makes tracking impossible
❌ **Forgetting to clean up** — Stale crons accumulate

## Example: 2-Hour Implementation Cycle

```
User: "Build feature X, Y, Z. Check in every 15 min."

1. Spawn sub-agents:
   - sessions_spawn(task="Build X", label="build-x")
   - sessions_spawn(task="Build Y", label="build-y")
   - sessions_spawn(task="Build Z", label="build-z")

2. Set up bounded check-ins:
   - cron with endAtMs = now + 2 hours

3. At each 15-min check:
   - sessions_list → report which are done/running
   - sessions_history for any that seem stuck

4. On completion:
   - Summarize all outputs
   - Clean up cron
   - Update memory
```

## Integration with Linear

For tracked projects, create Linear issues before spawning:
- Issue links to sub-agent task
- Sub-agent updates issue on completion
- Provides external visibility into progress

---

*See also: AGENTS.md for general sub-agent guidelines*
