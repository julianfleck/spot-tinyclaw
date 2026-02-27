#!/bin/bash
API_BASE="http://localhost:3777"
TS=$(date +%s)
MSG_ID="research-weekly-friday_${TS}_$$"
curl -s -X POST "${API_BASE}/api/message"     -H "Content-Type: application/json"     -d "{\"channel\":\"schedule\",\"sender\":\"Scheduler\",\"senderId\":\"tinyclaw-schedule:research-weekly-friday\",\"message\":\"@research Run research-monitor for areas: memory-architectures, retrieval-architectures, agentic-reasoning, evaluation-governance. Check ~/.tinyclaw/.agents/skills/research-monitor/areas/ for briefings. Report highlights.\",\"messageId\":\"${MSG_ID}\"}"     > /dev/null 2>&1
