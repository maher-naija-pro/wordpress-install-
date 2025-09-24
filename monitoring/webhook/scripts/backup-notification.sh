#!/bin/bash
# Backup notification script for webhook

# Log the notification
echo "$(date): Backup notification received" >> /var/log/webhook.log

# Parse the alert data
ALERTS=$(echo "$1" | jq -r '.alerts[]?')

if [ -n "$ALERTS" ]; then
    echo "$ALERTS" | jq -r '.annotations.summary // .labels.alertname' >> /var/log/webhook.log
fi

# Send to Discord if webhook URL is configured
if [ -n "$DISCORD_WEBHOOK_URL" ]; then
    curl -H "Content-Type: application/json" \
         -d "{\"content\": \"Backup Alert: $ALERTS\"}" \
         "$DISCORD_WEBHOOK_URL"
fi

exit 0
