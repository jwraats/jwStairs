#!/bin/bash
# Bouncing Ball Show - A ball bouncing up and down the stairs
# Usage: ./bounce.sh <sceneId>

SCENE_ID=${1:-1}
BASE_URL="http://192.168.178.77:5001"

if [ -z "$1" ]; then
  echo "Usage: ./bounce.sh <sceneId>"
  echo "Example: ./bounce.sh 5"
  exit 1
fi

echo "⚽ Creating Bouncing Ball show for scene ID: $SCENE_ID"

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

generate_step() {
  local start=$1
  local end=$2
  local r=$3
  local g=$4
  local b=$5
  local result=""
  
  for ((led=start; led<=end; led++)); do
    if [ -n "$result" ]; then result="$result,"; fi
    result="$result$(led_json $led $r $g $b)"
  done
  echo "$result"
}

echo "📤 Sending frames..."

ORDER=0

# Ball bounce pattern with realistic physics (slower at top, faster at bottom)
# Bounce heights decrease over time
BOUNCES=(14 11 8 6 4 3 2 1)

for bounce_height in "${BOUNCES[@]}"; do
  # Going up (decelerating)
  for ((step=1; step<=bounce_height; step++)); do
    LEDS=""
    read start end count <<< "${STEPS[$step]}"
    
    # Ball (full step lit)
    LEDS=$(generate_step $start $end 255 150 0)
    
    # Trail (previous step dimmer)
    if [ $step -gt 1 ]; then
      read pstart pend pcount <<< "${STEPS[$((step-1))]}"
      LEDS="$LEDS,$(generate_step $pstart $pend 100 60 0)"
    fi
    if [ $step -gt 2 ]; then
      read pstart pend pcount <<< "${STEPS[$((step-2))]}"
      LEDS="$LEDS,$(generate_step $pstart $pend 30 20 0)"
    fi
    
    # Slower at top (larger wait), faster at bottom
    wait=$((30 + (step * step / 2)))
    send_frame $ORDER $wait "$LEDS"
    ORDER=$((ORDER + 1))
  done
  
  # Going down (accelerating)
  for ((step=bounce_height; step>=1; step--)); do
    LEDS=""
    read start end count <<< "${STEPS[$step]}"
    
    LEDS=$(generate_step $start $end 255 150 0)
    
    # Trail (previous step dimmer)
    if [ $step -lt 14 ]; then
      read pstart pend pcount <<< "${STEPS[$((step+1))]}"
      LEDS="$LEDS,$(generate_step $pstart $pend 100 60 0)"
    fi
    if [ $step -lt 13 ]; then
      read pstart pend pcount <<< "${STEPS[$((step+2))]}"
      LEDS="$LEDS,$(generate_step $pstart $pend 30 20 0)"
    fi
    
    # Faster at bottom
    wait=$((30 + (step * step / 2)))
    send_frame $ORDER $wait "$LEDS"
    ORDER=$((ORDER + 1))
  done
  
  # Impact flash
  read start end count <<< "${STEPS[1]}"
  LEDS=$(generate_step $start $end 255 200 100)
  send_frame $ORDER 50 "$LEDS"
  ORDER=$((ORDER + 1))
done

# Ball comes to rest
read start end count <<< "${STEPS[1]}"
LEDS=$(generate_step $start $end 150 100 0)
send_frame $ORDER 500 "$LEDS"
ORDER=$((ORDER + 1))

# Fade out
for fade in 100 50 20; do
  LEDS=$(generate_step $start $end $fade $((fade*2/3)) 0)
  send_frame $ORDER 200 "$LEDS"
  ORDER=$((ORDER + 1))
done

send_frame $ORDER 100 ""
ORDER=$((ORDER + 1))

echo ""
echo "✅ Bouncing Ball show created with $ORDER frames!"
echo ""
echo "▶️  To play: curl '${BASE_URL}/animation/bounce?repeat=true'"
