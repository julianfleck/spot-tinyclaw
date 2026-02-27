#!/bin/bash
API_BASE="http://localhost:3777"
TS=$(date +%s)
MSG_ID="rage-changelog_${TS}_$$"
curl -s -X POST "${API_BASE}/api/message"     -H "Content-Type: application/json"     -d "{\"channel\":\"schedule\",\"sender\":\"Scheduler\",\"senderId\":\"tinyclaw-schedule:rage-changelog\",\"message\":\"@coder Update RAGE changelog from recent commits. cd ~/tinyclaw-workspace/spot/repos/rage-substrate, check git log, update CHANGELOG.md, commit and push.\",\"messageId\":\"${MSG_ID}\"}"     > /dev/null 2>&1
