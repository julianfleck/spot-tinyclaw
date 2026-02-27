#!/bin/bash
API_BASE="http://localhost:3777"
TS=$(date +%s)
MSG_ID="research-brand-mentions_${TS}_$$"
curl -s -X POST "${API_BASE}/api/message"     -H "Content-Type: application/json"     -d "{\"channel\":\"schedule\",\"sender\":\"Scheduler\",\"senderId\":\"tinyclaw-schedule:research-brand-mentions\",\"message\":\"@research Run research-monitor for area: brand-mentions. Search for Julian Fleck, julianfleck.net, recurse.cc mentions. Report only if significant new findings.\",\"messageId\":\"${MSG_ID}\"}"     > /dev/null 2>&1
