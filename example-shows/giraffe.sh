#!/bin/bash
# Giraffe Dots Show - Random giraffe-like spots across all 710 LEDs
# Usage: ./giraffe.sh <sceneId>

SCENE_ID=${1:-1}
BASE_URL="http://192.168.178.77:5001"

if [ -z "$1" ]; then
  echo "Usage: ./giraffe.sh <sceneId>"
  echo "Example: ./giraffe.sh 5"
  exit 1
fi

echo "🦒 Creating Giraffe Dots show for scene ID: $SCENE_ID"

# Giraffe colors
# Base: warm yellow/tan (background)
# Spots: dark brown

# Send frame to API
send_frame() {
  local order=$1
  local wait=$2
  local leds=$3
  
  curl -s -X 'POST' \
    "${BASE_URL}/scenes/${SCENE_ID}/frame" \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d "{\"orderNr\":$order,\"waitTillNextFrame\":$wait,\"leds\":[$leds]}" > /dev/null
  
  echo "  ✓ Frame $order sent"
}

# Generate LED with color
led_json() {
  local nr=$1
  local r=$2
  local g=$3
  local b=$4
  echo "{\"ledNr\":$nr,\"colorRed\":$r,\"colorGreen\":$g,\"colorBlue\":$b,\"colorAlpha\":0}"
}

echo "📤 Sending frames..."

# Frame 0: Giraffe pattern - base tan with brown spots
LEDS=""
for ((i=0; i<=709; i++)); do
  if [ -n "$LEDS" ]; then LEDS="$LEDS,"; fi
  
  # Create giraffe-like spot pattern
  # Spots at pseudo-random positions based on LED number
  if (( i % 7 == 0 || i % 13 == 3 || i % 17 == 5 || i % 23 == 11 || i % 31 == 7 )); then
    # Dark brown spot
    LEDS="$LEDS$(led_json $i 101 67 33)"
  elif (( i % 7 == 1 || i % 13 == 4 || i % 17 == 6 || i % 23 == 12 )); then
    # Medium brown (spot edge)
    LEDS="$LEDS$(led_json $i 139 90 43)"
  else
    # Tan/yellow base
    LEDS="$LEDS$(led_json $i 255 200 120)"
  fi
done
send_frame 0 2000 "$LEDS"

# Frame 1: Spots shift slightly (animation)
LEDS=""
for ((i=0; i<=709; i++)); do
  if [ -n "$LEDS" ]; then LEDS="$LEDS,"; fi
  
  if (( (i+3) % 7 == 0 || (i+2) % 13 == 3 || (i+1) % 17 == 5 || (i+4) % 23 == 11 || (i+2) % 31 == 7 )); then
    LEDS="$LEDS$(led_json $i 101 67 33)"
  elif (( (i+3) % 7 == 1 || (i+2) % 13 == 4 || (i+1) % 17 == 6 || (i+4) % 23 == 12 )); then
    LEDS="$LEDS$(led_json $i 139 90 43)"
  else
    LEDS="$LEDS$(led_json $i 255 200 120)"
  fi
done
send_frame 1 2000 "$LEDS"

# Frame 2: More shift
LEDS=""
for ((i=0; i<=709; i++)); do
  if [ -n "$LEDS" ]; then LEDS="$LEDS,"; fi
  
  if (( (i+5) % 7 == 0 || (i+4) % 13 == 3 || (i+3) % 17 == 5 || (i+2) % 23 == 11 || (i+5) % 31 == 7 )); then
    LEDS="$LEDS$(led_json $i 101 67 33)"
  elif (( (i+5) % 7 == 1 || (i+4) % 13 == 4 || (i+3) % 17 == 6 || (i+2) % 23 == 12 )); then
    LEDS="$LEDS$(led_json $i 139 90 43)"
  else
    LEDS="$LEDS$(led_json $i 255 200 120)"
  fi
done
send_frame 2 2000 "$LEDS"

# Frame 3: Another pattern
LEDS=""
for ((i=0; i<=709; i++)); do
  if [ -n "$LEDS" ]; then LEDS="$LEDS,"; fi
  
  if (( (i+1) % 11 == 0 || (i+3) % 19 == 5 || (i+2) % 29 == 8 )); then
    LEDS="$LEDS$(led_json $i 101 67 33)"
  elif (( (i+1) % 11 == 1 || (i+3) % 19 == 6 || (i+2) % 29 == 9 )); then
    LEDS="$LEDS$(led_json $i 139 90 43)"
  else
    LEDS="$LEDS$(led_json $i 255 200 120)"
  fi
done
send_frame 3 2000 "$LEDS"

# Frame 4: Return to original
LEDS=""
for ((i=0; i<=709; i++)); do
  if [ -n "$LEDS" ]; then LEDS="$LEDS,"; fi
  
  if (( i % 7 == 0 || i % 13 == 3 || i % 17 == 5 || i % 23 == 11 || i % 31 == 7 )); then
    LEDS="$LEDS$(led_json $i 101 67 33)"
  elif (( i % 7 == 1 || i % 13 == 4 || i % 17 == 6 || i % 23 == 12 )); then
    LEDS="$LEDS$(led_json $i 139 90 43)"
  else
    LEDS="$LEDS$(led_json $i 255 200 120)"
  fi
done
send_frame 4 2000 "$LEDS"

echo ""
echo "✅ Giraffe Dots show created with 5 frames!"
echo ""
echo "▶️  To play: curl '${BASE_URL}/animation/giraffe?repeat=true'"
