#!/usr/bin/env bash
# Fetches remaining DeepSeek API credit balance
curl -s -X GET "https://api.deepseek.com/user/balance" \
  -H "Authorization: Bearer $DEEPSEEK_API_KEY" \
  -H "Accept: application/json" |
  jq -r '.balance_infos[0].total_balance // "N/A"'
