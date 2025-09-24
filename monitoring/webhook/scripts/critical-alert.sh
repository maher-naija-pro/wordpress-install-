#!/bin/bash
# Critical alert script for webhook

# Log the critical alert
echo "$(date): CRITICAL ALERT received" >> /var/log/webhook.log

# Parse the alert data
ALERTS=$(echo "$1" | jq -r '.alerts[]?')

if [ -n "$ALERTS" ]; then
    echo "$ALERTS" | jq -r '.annotations.summary // .labels.alertname' >> /var/log/webhook.log
fi

# Send to Discord if webhook URL is configured
if [ -n "$DISCORD_WEBHOOK_URL" ]; then
    curl -H "Content-Type: application/json" \
         -d "{\"content\": \"🚨 CRITICAL ALERT: $ALERTS\"}" \
         "$DISCORD_WEBHOOK_URL"
fi

# Send to Slack if webhook URL is configured
if [ -n "$SLACK_WEBHOOK_URL" ]; then
    curl -X POST -H 'Content-type: application/json' \
         --data "{\"text\":\"🚨 CRITICAL ALERT: $ALERTS\"}" \
         "$SLACK_WEBHOOK_URL"
fi

exit 0
