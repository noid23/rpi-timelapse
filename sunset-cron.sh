#!/bin/bash
# sunset-cron.sh
# Fetches today's sunset time for your current IP location and sets a cron job X minutes before.

# === CONFIGURATION ===
CRON_COMMAND="/home/noid/script1.sh"  # Command or script to run X min before sunset
START_TIME="$1"         #User defined start time
# === DEPENDENCIES CHECK ===
for cmd in curl jq date; do
  if ! command -v $cmd &>/dev/null; then
    echo "❌ Missing dependency: $cmd (install with: sudo apt install $cmd -y)"
    exit 1
  fi
done

# === Input Check ===
if [ -z "$START_TIME" ]; then
  echo "Usage: $0 <minutes_before_sunset>"
  exit 1
fi


# === DETECT LOCATION ===
LOCATION_JSON=$(curl -s https://ipinfo.io)
LAT=$(echo "$LOCATION_JSON" | jq -r '.loc' | cut -d',' -f1)
LON=$(echo "$LOCATION_JSON" | jq -r '.loc' | cut -d',' -f2)
CITY=$(echo "$LOCATION_JSON" | jq -r '.city')

if [ -z "$LAT" ] || [ -z "$LON" ] || [ "$LAT" = "null" ]; then
  echo "❌ Failed to detect location."
  exit 1
fi

echo "📍 Detected location: $CITY ($LAT,$LON)"

# === GET SUNSET TIME (UTC) ===
SUNSET_UTC=$(curl -s "https://api.sunrise-sunset.org/json?lat=$LAT&lng=$LON&formatted=0" | jq -r '.results.sunset')

if [ -z "$SUNSET_UTC" ] || [ "$SUNSET_UTC" = "null" ]; then
  echo "❌ Failed to fetch sunset time."
  exit 1
fi

# === CONVERT TO LOCAL TIME ===
SUNSET_LOCAL=$(date -d "$SUNSET_UTC" +"%Y-%m-%d %H:%M:%S")

# === CALCULATE X MINUTES BEFORE SUNSET ===
SUNSET_MINUS_X=$(date -d "$START_TIME minutes ago $SUNSET_LOCAL" +"%M %H %d %m *")

# === UPDATE CRON JOB ===
crontab -l 2>/dev/null | grep -v "$CRON_COMMAND" > /tmp/cron.tmp
echo "$SUNSET_MINUS_X $CRON_COMMAND" >> /tmp/cron.tmp
crontab /tmp/cron.tmp
rm /tmp/cron.tmp

echo "✅ Cron job set for $START_TIME minutes before sunset."
echo "   🌆 Sunset: $SUNSET_LOCAL"
echo "   🕐 Job runs at: $(date -d "$START_TIME minutes ago $SUNSET_LOCAL" +"%Y-%m-%d %H:%M:%S")"
