#!/bin/bash
# =========================================================
# sunset-timelapse.sh
# Capture a timelapse from a webcam or Pi Camera.
# =========================================================
# Usage:
#   ./sunset-timelapse.sh <interval_seconds> <duration_minutes>
#
# Example:
#   ./sunset-timelapse.sh 30 60
#   → Takes a photo every 30 seconds for 60 minutes
# =========================================================

# --- CONFIGURATION ---
OUTPUT_DIR_BASE="$HOME/sunset-timelapse"   # Where finished videos will go
CAMERA_DEVICE="/dev/video0"                # Change if needed
IMAGE_WIDTH=1920
IMAGE_HEIGHT=1080

# --- DEPENDENCY CHECK ---
for cmd in ffmpeg libcamera-still date mkdir; do
  if ! command -v $cmd &>/dev/null; then
    echo "❌ Missing dependency: $cmd"
    echo "Install with: sudo apt install ffmpeg libcamera-apps -y"
    exit 1
  fi
done

# --- ARGUMENTS ---
INTERVAL="$1"   # seconds between shots
DURATION="$2"   # total duration in minutes

if [ -z "$INTERVAL" ] || [ -z "$DURATION" ]; then
  echo "Usage: $0 <interval_seconds> <duration_minutes>"
  exit 1
fi

# --- PREPARE DIRECTORIES ---
DATE_STR=$(date +"%Y-%m-%d")
WORK_DIR="$HOME/timelapse-$DATE_STR"
mkdir -p "$WORK_DIR"
mkdir -p "$OUTPUT_DIR_BASE"

echo "📸 Starting timelapse..."
echo "   Interval: $INTERVAL sec"
echo "   Duration: $DURATION min"
echo "   Working directory: $WORK_DIR"

# --- CALCULATE NUMBER OF SHOTS ---
TOTAL_SHOTS=$(( (DURATION * 60) / INTERVAL ))
echo "   Total images to capture: $TOTAL_SHOTS"

# --- CAPTURE LOOP ---
for ((i=1; i<=TOTAL_SHOTS; i++)); do
    TS=$(date +"%Y-%m-%d_%H-%M-%S")
    FILENAME="$WORK_DIR/$TS.jpg"

    # --- CAPTURE IMAGE ---
    # Try libcamera-still first; fallback to fswebcam if unavailable
    if command -v libcamera-still &>/dev/null; then
        libcamera-still -o "$FILENAME" --width $IMAGE_WIDTH --height $IMAGE_HEIGHT -n
    elif command -v fswebcam &>/dev/null; then
        fswebcam -d "$CAMERA_DEVICE" -r ${IMAGE_WIDTH}x${IMAGE_HEIGHT} --no-banner "$FILENAME"
    else
        echo "❌ No supported camera command found (libcamera-still or fswebcam)."
        exit 1
    fi

    echo "✅ Captured $FILENAME"
    sleep "$INTERVAL"
done

# --- CREATE TIMELAPSE VIDEO ---
echo "🎞️ Creating video from captured images..."
OUTPUT_VIDEO="$OUTPUT_DIR_BASE/sunset-$DATE_STR.mp4"

# Generate video from images in chronological order
ffmpeg -y -pattern_type glob -i "$WORK_DIR/*.jpg" \
  -c:v libx264 -r 30 -pix_fmt yuv420p "$OUTPUT_VIDEO"

if [ $? -eq 0 ]; then
  echo "✅ Timelapse created: $OUTPUT_VIDEO"
else
  echo "❌ Failed to generate video."
  exit 1
fi

# --- DONE ---
echo "🧹 Done! Images remain in: $WORK_DIR"
