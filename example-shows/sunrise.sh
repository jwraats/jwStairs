#!/bin/bash
# Sunrise Show - Gradient from dark to warm light, bottom to top
# Usage: ./sunrise.sh <sceneId>

SCENE_ID=${1:-1}
BASE_URL="http://192.168.178.77:5001"

if [ -z "$1" ]; then
  echo "Usage: ./sunrise.sh <sceneId>"
  echo "Example: ./sunrise.sh 5"
  exit 1
fi

echo "🌅 Creating Sunrise show for scene ID: $SCENE_ID"

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

ORDER=0
NUM_PHASES=20

for ((phase=0; phase<=NUM_PHASES; phase++)); do
  LEDS=""
  first=true
  
  # How "risen" is the sun (0 = night, NUM_PHASES = full day)
  sun_height=$((phase * 14 / NUM_PHASES))
  
  for step in {1..14}; do
    read start end count <<< "${STEPS[$step]}"
    
    # Calculate this step's brightness based on sun position
    # Steps below sun_height are lit, above are dark/dim
    if [ $step -le $sun_height ]; then
      # Full sunrise color
      progress=$((step * 100 / 14))
      # Bottom = orange/red, top = yellow/white
      r=255
      g=$((80 + progress))
      b=$((progress / 2))
    elif [ $step -le $((sun_height + 3)) ]; then
      # Transition zone (horizon glow)
      dist=$((step - sun_height))
      factor=$((100 - dist * 30))
      r=$((255 * factor / 100))
      g=$((80 * factor / 100))
      b=$((20 * factor / 100))
    else
      # Dark sky (deep blue, very dim)
      sky_factor=$((14 - step))
      r=$((5 + sky_factor))
      g=$((5 + sky_factor * 2))
      b=$((20 + sky_factor * 3))
    fi
    
    for ((led=start; led<=end; led++)); do
      if [ "$first" = true ]; then first=false; else LEDS="$LEDS,"; fi
      LEDS="$LEDS$(led_json $led $r $g $b)"
    done
  done
  
  send_frame $ORDER 200 "$LEDS"
  ORDER=$((ORDER + 1))
done

# Hold at full sunrise
send_frame $ORDER 2000 "$LEDS"
ORDER=$((ORDER + 1))

echo ""
echo "✅ Sunrise show created with $ORDER frames!"
echo ""
echo "▶️  To play: curl '${BASE_URL}/animation/sunrise?repeat=false'"
