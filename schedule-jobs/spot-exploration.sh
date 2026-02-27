#!/bin/bash
API_BASE="http://localhost:3777"
TS=$(date +%s)
MSG_ID="spot-exploration_${TS}_$$"
curl -s -X POST "${API_BASE}/api/message"     -H "Content-Type: application/json"     -d "{\"channel\":\"schedule\",\"sender\":\"Scheduler\",\"senderId\":\"tinyclaw-schedule:spot-exploration\",\"message\":\"@spot Autonomous exploration. Review state, memory, priorities. Organize files. Think/research. Build when possible. Send Telegram update. Log to memory.\",\"messageId\":\"${MSG_ID}\"}"     > /dev/null 2>&1
