#!/bin/bash

set -a
source .env
set +a

# Output file for storing the map
OUTPUT_FILE="usergroups.json"

# Fetch all usergroups from Slack
response=$(curl -s -H "Authorization: Bearer $SLACK_TOKEN" \
    "https://slack.com/api/usergroups.list")

map=$(echo "$response" | jq -r '.usergroups | map({(.handle): .id}) | add')

echo "$map" > "$OUTPUT_FILE"

echo "User group map saved to $OUTPUT_FILE"