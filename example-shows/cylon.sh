#!/bin/bash
# Cylon/Scanner Show - Knight Rider style sweep across each step
# Usage: ./cylon.sh <sceneId>

SCENE_ID=${1:-1}
BASE_URL="http://192.168.178.77:5001"

if [ -z "$1" ]; then
  echo "Usage: ./cylon.sh <sceneId>"
  echo "Example: ./cylon.sh 5"
  exit 1
fi

echo "🤖 Creating Cylon Scanner show for scene ID: $SCENE_ID"

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
STEPS_PER_SWEEP=20  # How many positions across each step

# Each step scans at a different phase for wave effect
for ((frame=0; frame<STEPS_PER_SWEEP*2; frame++)); do
  LEDS=""
  first=true
  
  for step in {1..14}; do
    read start end count <<< "${STEPS[$step]}"
    
    # Phase offset based on step (creates cascading wave)
    phase_offset=$((step * 2))
    effective_frame=$(( (frame + phase_offset) % (STEPS_PER_SWEEP * 2) ))
    
    # Calculate scanner position (bounces back and forth)
    if [ $effective_frame -lt $STEPS_PER_SWEEP ]; then
      pos_pct=$((effective_frame * 100 / STEPS_PER_SWEEP))
    else
      pos_pct=$(( (STEPS_PER_SWEEP * 2 - effective_frame) * 100 / STEPS_PER_SWEEP ))
    fi
    
    center=$((start + count * pos_pct / 100))
    
    # Scanner eye with trail
    for ((offset=-6; offset<=6; offset++)); do
      led=$((center + offset))
      if [ $led -ge $start ] && [ $led -le $end ]; then
        if [ "$first" = true ]; then first=false; else LEDS="$LEDS,"; fi
        
        # Brightness falls off from center
        dist=$offset
        if [ $dist -lt 0 ]; then dist=$((-dist)); fi
        
        if [ $dist -eq 0 ]; then
          # Core: bright red
          LEDS="$LEDS$(led_json $led 255 0 0)"
        elif [ $dist -le 2 ]; then
          # Inner glow
          LEDS="$LEDS$(led_json $led 200 0 0)"
        elif [ $dist -le 4 ]; then
          # Outer glow
          LEDS="$LEDS$(led_json $led 100 0 0)"
        else
          # Trail
          LEDS="$LEDS$(led_json $led 40 0 0)"
        fi
      fi
    done
  done
  
  send_frame $ORDER 50 "$LEDS"
  ORDER=$((ORDER + 1))
done

echo ""
echo "✅ Cylon Scanner show created with $ORDER frames!"
echo ""
echo "▶️  To play: curl '${BASE_URL}/animation/cylon?repeat=true'"
