#!/bin/bash
# Disco Ball Show - Sparkly mirror ball effect with moving light reflections
# Usage: ./disco.sh <sceneId>

SCENE_ID=${1:-1}
BASE_URL="http://192.168.178.77:5001"

if [ -z "$1" ]; then
  echo "Usage: ./disco.sh <sceneId>"
  echo "Example: ./disco.sh 5"
  exit 1
fi

echo "🪩 Creating Disco Ball show for scene ID: $SCENE_ID"

# All edge LEDs
ALL_EDGES=(0 47 48 97 98 147 148 198 199 248 249 298 299 347 348 397 398 451 452 505 506 559 560 609 610 658 659 709)

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

TOTAL_LEDS=710
NUM_FRAMES=60
REFLECTIONS_PER_FRAME=40  # Number of light reflections per frame

ORDER=0

# Disco colors: whites, silvers, and occasional color bursts
for ((frame=0; frame<NUM_FRAMES; frame++)); do
  LEDS=""
  first=true
  
  # Dark background base
  for ((led=0; led<TOTAL_LEDS; led++)); do
    if [ "$first" = true ]; then first=false; else LEDS="$LEDS,"; fi
    LEDS="$LEDS$(led_json $led 5 5 10)"
  done
  
  # Add random reflections (simulating disco ball mirror reflections)
  for ((r=0; r<REFLECTIONS_PER_FRAME; r++)); do
    led=$((RANDOM % TOTAL_LEDS))
    
    # Most reflections are white/silver, some are colored
    color_roll=$((RANDOM % 100))
    if [ $color_roll -lt 70 ]; then
      # White/silver reflection
      brightness=$((180 + RANDOM % 76))
      red=$brightness
      green=$brightness
      blue=$brightness
    elif [ $color_roll -lt 80 ]; then
      # Pink/magenta
      red=$((200 + RANDOM % 56))
      green=$((50 + RANDOM % 50))
      blue=$((200 + RANDOM % 56))
    elif [ $color_roll -lt 90 ]; then
      # Light blue
      red=$((100 + RANDOM % 50))
      green=$((180 + RANDOM % 76))
      blue=$((255))
    else
      # Gold/yellow
      red=$((220 + RANDOM % 36))
      green=$((180 + RANDOM % 50))
      blue=$((50 + RANDOM % 50))
    fi
    
    LEDS="$LEDS,$(led_json $led $red $green $blue)"
    
    # Sometimes add a small cluster of adjacent LEDs
    if [ $((RANDOM % 4)) -eq 0 ]; then
      adjacent=$((led + 1))
      if [ $adjacent -lt $TOTAL_LEDS ]; then
        dim=$((red * 2 / 3))
        LEDS="$LEDS,$(led_json $adjacent $dim $((green * 2 / 3)) $((blue * 2 / 3)))"
      fi
    fi
  done
  
  # Add rotating edge accents (like light beams sweeping)
  beam_start=$(( (frame * 4) % 28 ))
  for ((i=0; i<6; i++)); do
    edge_idx=$(( (beam_start + i) % 28 ))
    edge_led=${ALL_EDGES[$edge_idx]}
    LEDS="$LEDS,$(led_json $edge_led 255 255 255)"
  done
  
  send_frame $ORDER 80 "$LEDS"
  ORDER=$((ORDER + 1))
done

echo ""
echo "✅ Disco Ball show created with $ORDER frames!"
echo ""
echo "▶️  To play: curl '${BASE_URL}/animation/disco?repeat=true'"
