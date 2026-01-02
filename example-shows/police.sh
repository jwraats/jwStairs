#!/bin/bash
# Police Lights Show - Red and blue alternating emergency lights
# Usage: ./police.sh <sceneId>

SCENE_ID=${1:-1}
BASE_URL="http://192.168.178.77:5001"

if [ -z "$1" ]; then
  echo "Usage: ./police.sh <sceneId>"
  echo "Example: ./police.sh 5"
  exit 1
fi

echo "🚔 Creating Police Lights show for scene ID: $SCENE_ID"

# Left and Right edge LEDs
LEFT_EDGES=(0 97 98 198 199 298 299 397 398 505 506 609 610 659)
RIGHT_EDGES=(47 48 147 148 248 249 347 348 451 452 559 560 658 709)

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

ORDER=0

# Pattern: Red-Blue alternating with strobe effect
for cycle in {1..4}; do
  # RED left, BLUE right - 3 strobes
  for strobe in 1 2 3; do
    LEDS=""
    first=true
    for led in "${LEFT_EDGES[@]}"; do
      if [ "$first" = true ]; then first=false; else LEDS="$LEDS,"; fi
      LEDS="$LEDS$(led_json $led 255 0 0)"
    done
    for led in "${RIGHT_EDGES[@]}"; do
      LEDS="$LEDS,$(led_json $led 0 0 255)"
    done
    send_frame $ORDER 60 "$LEDS"
    ORDER=$((ORDER + 1))
    
    # Dark
    send_frame $ORDER 40 ""
    ORDER=$((ORDER + 1))
  done
  
  # BLUE left, RED right - 3 strobes
  for strobe in 1 2 3; do
    LEDS=""
    first=true
    for led in "${LEFT_EDGES[@]}"; do
      if [ "$first" = true ]; then first=false; else LEDS="$LEDS,"; fi
      LEDS="$LEDS$(led_json $led 0 0 255)"
    done
    for led in "${RIGHT_EDGES[@]}"; do
      LEDS="$LEDS,$(led_json $led 255 0 0)"
    done
    send_frame $ORDER 60 "$LEDS"
    ORDER=$((ORDER + 1))
    
    # Dark
    send_frame $ORDER 40 ""
    ORDER=$((ORDER + 1))
  done
done

echo ""
echo "✅ Police Lights show created with $ORDER frames!"
echo ""
echo "▶️  To play: curl '${BASE_URL}/animation/police?repeat=true'"
