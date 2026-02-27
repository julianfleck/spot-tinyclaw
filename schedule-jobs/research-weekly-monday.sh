#!/bin/bash
API_BASE="http://localhost:3777"
TS=$(date +%s)
MSG_ID="research-weekly-monday_${TS}_$$"
curl -s -X POST "${API_BASE}/api/message"     -H "Content-Type: application/json"     -d "{\"channel\":\"schedule\",\"sender\":\"Scheduler\",\"senderId\":\"tinyclaw-schedule:research-weekly-monday\",\"message\":\"@research Run research-monitor for areas: divergence-engines, ephemeral-interfaces. Check briefings in ~/.tinyclaw/.agents/skills/research-monitor/areas/. Report highlights.\",\"messageId\":\"${MSG_ID}\"}"     > /dev/null 2>&1
