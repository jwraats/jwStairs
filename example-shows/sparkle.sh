#!/bin/bash
# Sparkle/Twinkle Show - Random stars twinkling across all LEDs
# Usage: ./sparkle.sh <sceneId>

SCENE_ID=${1:-1}
BASE_URL="http://192.168.178.77:5001"

if [ -z "$1" ]; then
  echo "Usage: ./sparkle.sh <sceneId>"
  echo "Example: ./sparkle.sh 5"
  exit 1
fi

echo "✨ Creating Sparkle show for scene ID: $SCENE_ID"

send_frame() {
  curl -s -X 'POST' \
    "${BASE_URL}/scenes/${SCENE_ID}/frame" \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d "{\"orderNr\":$1,\"waitTillNextFrame\":$2,\"leds\":[$3]}" > /dev/null
  echo "  ✓ Frame $1 sent"
}

led_json() {
  echo "{\"ledNr\":$1,\"colorRed\":$2,\"colorGreen\":$3,\"colorBlue\":$4,\"colorAlpha\":0}"
}

echo "📤 Sending frames..."

NUM_FRAMES=40
TOTAL_LEDS=710
SPARKLES_PER_FRAME=50

for ((frame=0; frame<NUM_FRAMES; frame++)); do
  LEDS=""
  first=true
  
  # Background: dim warm white on all LEDs
  for ((led=0; led<TOTAL_LEDS; led++)); do
    if [ "$first" = true ]; then first=false; else LEDS="$LEDS,"; fi
    LEDS="$LEDS$(led_json $led 15 12 8)"
  done
  
  # Add random sparkles
  for ((s=0; s<SPARKLES_PER_FRAME; s++)); do
    led=$((RANDOM % TOTAL_LEDS))
    # Random brightness
    brightness=$((150 + RANDOM % 106))
    # Slight color variation (warm white to cool white)
    r=$brightness
    g=$((brightness - RANDOM % 30))
    b=$((brightness - RANDOM % 50))
    if [ $g -lt 100 ]; then g=100; fi
    if [ $b -lt 80 ]; then b=80; fi
    
    LEDS="$LEDS,$(led_json $led $r $g $b)"
  done
  
  send_frame $frame 100 "$LEDS"
done

echo ""
echo "✅ Sparkle show created with $NUM_FRAMES frames!"
echo ""
echo "▶️  To play: curl '${BASE_URL}/animation/sparkle?repeat=true'"
