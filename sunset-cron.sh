#!/bin/bash
# sunset-cron.sh
# Fetches today's sunset time for your current IP location and sets a cron job 30 minutes before.

# === CONFIGURATION ===
CRON_COMMAND="/home/noid/script1.sh"  # Command or script to run 30 min before sunset

# === DEPENDENCIES CHECK ===
for cmd in curl jq date; do
  if ! command -v $cmd &>/dev/null; then
    echo "❌ Missing dependency: $cmd (install with: sudo apt install $cmd -y)"
    exit 1
  fi
done

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

# === CALCULATE 30 MINUTES BEFORE SUNSET ===
SUNSET_MINUS_30=$(date -d "30 minutes ago $SUNSET_LOCAL" +"%M %H %d %m *")

# === UPDATE CRON JOB ===
crontab -l 2>/dev/null | grep -v "$CRON_COMMAND" > /tmp/cron.tmp
echo "$SUNSET_MINUS_30 $CRON_COMMAND" >> /tmp/cron.tmp
crontab /tmp/cron.tmp
rm /tmp/cron.tmp

echo "✅ Cron job set for 30 minutes before sunset."
echo "   🌆 Sunset: $SUNSET_LOCAL"
echo "   🕐 Job runs at: $(date -d "30 minutes ago $SUNSET_LOCAL" +"%Y-%m-%d %H:%M:%S")"
