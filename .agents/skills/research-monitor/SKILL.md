---
name: research-monitor
description: Monitors research areas with structured briefings, configurable cadence, and formatted reports. Spawns sub-agents during off-peak hours.
---

# Research Monitor

Structured research monitoring with per-area briefings, output formats, and delivery schedules.

## Structure

```
research-monitor/
├── config.json              # Global settings
├── areas/
│   └── {area-slug}/
│       ├── briefing.md      # What to look for (1-2 paragraphs)
│       ├── format.md        # Output format specification
│       └── config.json      # Area config (keywords, sources, cadence)

Reports are saved to workspace:
~/.openclaw/workspace/research/
└── {area-slug}/
    ├── runs/
    │   └── {date}.md        # Generated reports (dd-mm-yyyy format)
    └── overview.md          # Current state tracking
```

## Workflow

### 1. Scheduled Execution (Cron)

Research runs are triggered by cron jobs during off-peak hours (default: 04:00-06:00).
Each area has its own schedule defined in `areas/{slug}/config.json`.

The cron job spawns an isolated sub-agent with a task like:
```
Run research-monitor for area: {area-slug}
```

### 2. Sub-Agent Execution

When triggered for a specific area:

1. **Load Context**
   - Read `areas/{slug}/config.json` for keywords, sources, cadence
   - Read `areas/{slug}/briefing.md` for research focus
   - Read `areas/{slug}/format.md` for output requirements

2. **Check Cadence**
   - Compare current date against `lastRun` and `cadence` in config
   - Skip if not due (unless `--force` flag)

3. **Search Sources (with fallback)**
   - Read `searchProviders` array from config — try providers in order
   - For each provider, attempt search for all keywords
   - If provider fails (rate limit, error), log and try next provider
   - If all providers fail, log error and skip this run
   
   **Provider implementations:**
   - `brave`: Use web_search tool
   - `serpapi`: curl to `https://serpapi.com/search.json?q=QUERY&api_key=$SERPER_API_KEY`
   - `arxiv`: Direct fetch from arxiv.org/search
   - `browser`: Browser automation (last resort, slow)

4. **Filter & Analyze**
   - Apply briefing criteria to filter noise
   - Score relevance based on briefing.md guidance
   - **If nothing significant: do not deliver, just update lastRun**

5. **Generate Report**
   - Format according to `format.md`
   - Save to `~/.openclaw/workspace/research/{slug}/runs/{date}.md`
   - **Deliver the markdown file as an attachment** to the configured channel
   - Use message tool with filePath to send the report file directly

6. **Accumulate Links**
   - Append highlighted papers to `~/.openclaw/workspace/links.yaml`
   - Format per entry:
     ```yaml
     - title: "Paper Title"
       description: "1-sentence summary"
       url: "https://arxiv.org/abs/..."
       area: "memory-architectures"
       date: "2026-02-02"
       relevance: "high"
     ```
   - This enables a downstream synthesis agent to process accumulated findings

7. **Track Notable Researchers**
   - When papers reveal researchers/groups doing directly relevant work, add them to `~/.openclaw/workspace/outreach.yaml`
   - Format:
     ```yaml
     - name: "Researcher Name"
       affiliation: "Institution"
       area: "research-area"
       reason: "Why they're relevant"
       papers:
         - title: "Paper Title"
           url: "https://..."
       discovered: "YYYY-MM-DD"
       status: "identified"
       notes: ""
     ```
   - Status values: identified → drafted → reached_out → responded → connected

7. **Update State**
   - Set `lastRun` in config to current date

## Config Schema

### Global (`config.json`)

```json
{
  "defaults": {
    "runWindow": { "start": "04:00", "end": "06:00" },
    "timezone": "Europe/Berlin",
    "deliverTo": "telegram",
    "model": "anthropic/claude-sonnet-4"
  }
}
```

### Per-Area (`areas/{slug}/config.json`)

```json
{
  "name": "Human-readable name",
  "enabled": true,
  "keywords": ["keyword1", "keyword2"],
  "searchProviders": ["brave", "serpapi"],
  "cadence": "weekly:friday",
  "deliverEmpty": false,
  "lastRun": "2026-01-28"
}
```

**Search providers** (tried in order, first success wins):
- `"brave"` — Brave Search API (web_search tool)
- `"serpapi"` — SerpAPI for real Google results (requires SERPER_API_KEY)
- `"arxiv"` — Direct arxiv API fetch
- `"browser"` — Browser automation fallback (slow, may hit CAPTCHAs)

**Cadence formats:**
- `"daily"` — every day
- `"weekly:monday"` — every Monday
- `"weekly:friday"` — every Friday
- `"biweekly:monday"` — every other Monday
- `"monthly:1"` — 1st of each month

## Adding a New Area

1. Create folder: `areas/{new-slug}/`
2. Write `briefing.md` — explain what matters, what to ignore
3. Write `format.md` — specify report structure
4. Create `config.json` with keywords, sources, cadence
5. Register cron job (or let main agent handle scheduling)

## Manual Trigger

To run a specific area manually:
```
Research monitor: run {area-slug} --force
```

## Scripts

- `python scripts/manage.py list` — list all areas and their status
- `python scripts/manage.py status {slug}` — show area details
- `python scripts/manage.py run {slug}` — trigger run (for testing)
