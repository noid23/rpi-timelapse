#!/bin/bash
# sunset-cron.sh
# Fetches today's sunset time and sets a cron job 30 minutes before sunset.

# === CONFIGURATION ===
LAT="0.0000"       # Your latitude
LON="0.0000"      # Your longitude
CRON_COMMAND="/home/noid/script.sh"  # Command or script to run

# === DEPENDENCIES CHECK ===
if ! command -v jq &>/dev/null; then
  echo "jq is required. Install with: sudo apt install jq"
  exit 1
fi

# === GET SUNSET TIME (UTC) ===
SUNSET_UTC=$(curl -s "https://api.sunrise-sunset.org/json?lat=$LAT&lng=$LON&formatted=0" | jq -r '.results.sunset')

if [ -z "$SUNSET_UTC" ] || [ "$SUNSET_UTC" = "null" ]; then
  echo "❌ Failed to fetch sunset time."
  exit 1
fi

# === CONVERT TO LOCAL TIME ===
SUNSET_LOCAL=$(date -d "$SUNSET_UTC" +"%Y-%m-%d %H:%M:%S")

# === CALCULATE 30 MINUTES BEFORE SUNSET ===
# Note: put the relative offset *before* the timestamp.
SUNSET_MINUS_30=$(date -d "30 minutes ago $SUNSET_LOCAL" +"%M %H %d %m *")

# === UPDATE CRON JOB ===
# Backup current crontab
crontab -l 2>/dev/null | grep -v "$CRON_COMMAND" > /tmp/cron.tmp

# Add the new cron entry
echo "$SUNSET_MINUS_30 $CRON_COMMAND" >> /tmp/cron.tmp

# Load it into crontab
crontab /tmp/cron.tmp
rm /tmp/cron.tmp

echo "✅ Cron job set for 30 minutes before sunset."
echo "   Sunset: $SUNSET_LOCAL"
echo "   Job runs at: $(date -d "30 minutes ago $SUNSET_LOCAL" +"%Y-%m-%d %H:%M:%S")"
