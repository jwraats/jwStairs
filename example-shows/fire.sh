#!/bin/bash
# Fire Show - Flickering flames rising up the stairs
# Usage: ./fire.sh <sceneId>

SCENE_ID=${1:-1}
BASE_URL="http://192.168.178.77:5001"

if [ -z "$1" ]; then
  echo "Usage: ./fire.sh <sceneId>"
  echo "Example: ./fire.sh 5"
  exit 1
fi

echo "🔥 Creating Fire show for scene ID: $SCENE_ID"

# Step definitions
declare -A STEPS
STEPS[1]="0 47 48"
STEPS[2]="48 97 50"
STEPS[3]="98 147 50"
STEPS[4]="148 198 51"
STEPS[5]="199 248 50"
STEPS[6]="249 298 50"
STEPS[7]="299 347 49"
STEPS[8]="348 397 50"
STEPS[9]="398 451 54"
STEPS[10]="452 505 54"
STEPS[11]="506 559 54"
STEPS[12]="560 609 50"
STEPS[13]="610 658 49"
STEPS[14]="659 709 51"

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

NUM_FRAMES=30

for ((frame=0; frame<NUM_FRAMES; frame++)); do
  LEDS=""
  first=true
  
  for step in {1..14}; do
    read start end count <<< "${STEPS[$step]}"
    
    # Fire intensity decreases as we go up (flames taper)
    base_intensity=$((255 - (step - 1) * 12))
    if [ $base_intensity -lt 60 ]; then base_intensity=60; fi
    
    for ((led=start; led<=end; led++)); do
      # Random flicker
      flicker=$((RANDOM % 80 - 40))
      intensity=$((base_intensity + flicker))
      if [ $intensity -gt 255 ]; then intensity=255; fi
      if [ $intensity -lt 20 ]; then intensity=20; fi
      
      # Position-based variation (edges more intense)
      pos_in_step=$((led - start))
      center=$((count / 2))
      dist_from_center=$((pos_in_step - center))
      if [ $dist_from_center -lt 0 ]; then dist_from_center=$((-dist_from_center)); fi
      
      # Flame tongues more likely at random positions
      flame_chance=$((RANDOM % 100))
      if [ $flame_chance -lt 15 ]; then
        # Bright flame tongue
        intensity=$((intensity + 50))
        if [ $intensity -gt 255 ]; then intensity=255; fi
      fi
      
      # Skip some LEDs at top steps (sparser flames)
      if [ $step -gt 10 ] && [ $((RANDOM % 100)) -lt $((step * 5)) ]; then
        continue
      fi
      
      # Fire colors: red base, orange/yellow highlights
      r=$intensity
      g=$((intensity * 40 / 100 + RANDOM % 30))  # Orange tint
      b=$((intensity / 15))  # Slight blue at base
      
      if [ $g -gt 180 ]; then g=180; fi
      
      if [ "$first" = true ]; then
        first=false
      else
        LEDS="$LEDS,"
      fi
      LEDS="$LEDS$(led_json $led $r $g $b)"
    done
  done
  
  send_frame $frame 60 "$LEDS"
done

echo ""
echo "✅ Fire show created with $NUM_FRAMES frames!"
echo ""
echo "▶️  To play: curl '${BASE_URL}/animation/fire?repeat=true'"
