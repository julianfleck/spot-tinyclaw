#!/bin/bash
API_BASE="http://localhost:3777"
TS=$(date +%s)
MSG_ID="morning-briefing_${TS}_$$"
curl -s -X POST "${API_BASE}/api/message"     -H "Content-Type: application/json"     -d "{\"channel\":\"schedule\",\"sender\":\"Scheduler\",\"senderId\":\"tinyclaw-schedule:morning-briefing\",\"message\":\"@scheduler Morning briefing for Julian. Check: 1) Calendar today and tomorrow (gog gcal list), 2) Linear priorities (linear issue list --state In\\ Progress,Todo), 3) Actionable emails (gog gmail search newer_than:1d is:unread). Summarize to Telegram - keep it brief and actionable.\",\"messageId\":\"${MSG_ID}\"}"     > /dev/null 2>&1
