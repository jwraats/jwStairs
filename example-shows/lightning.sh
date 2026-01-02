#!/bin/bash
# Lightning Show - Electric bolts zigzagging down the stairs
# Usage: ./lightning.sh <sceneId>

SCENE_ID=${1:-1}
BASE_URL="http://192.168.178.77:5001"

if [ -z "$1" ]; then
  echo "Usage: ./lightning.sh <sceneId>"
  echo "Example: ./lightning.sh 5"
  exit 1
fi

echo "⚡ Creating Lightning show for scene ID: $SCENE_ID"

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

# Generate a lightning bolt path (zigzag from top to bottom)
generate_bolt() {
  local seed=$1
  local positions=()
  
  # Start at random position on top step
  RANDOM=$seed
  local pos=50  # percentage from left
  
  for step in {14..1}; do
    # Zigzag: move left or right randomly
    local move=$((RANDOM % 30 - 15))
    pos=$((pos + move))
    if [ $pos -lt 10 ]; then pos=10; fi
    if [ $pos -gt 90 ]; then pos=90; fi
    positions[$step]=$pos
  done
  
  echo "${positions[@]}"
}

echo "📤 Sending frames..."

ORDER=0

# Generate 3 lightning strikes
for strike in 1 2 3; do
  # Generate random bolt path
  BOLT_POS=($(generate_bolt $((RANDOM))))
  
  # Flash sequence: dark -> bright -> dim -> bright -> fade
  
  # Dark before strike
  send_frame $ORDER 300 ""
  ORDER=$((ORDER + 1))
  
  # STRIKE 1: Full bright bolt
  LEDS=""
  first=true
  for step in {14..1}; do
    read start end count <<< "${STEPS[$step]}"
    pos_pct=${BOLT_POS[$step]:-50}
    center=$((start + count * pos_pct / 100))
    
    # Main bolt (narrow, very bright)
    for ((offset=-2; offset<=2; offset++)); do
      led=$((center + offset))
      if [ $led -ge $start ] && [ $led -le $end ]; then
        if [ "$first" = true ]; then first=false; else LEDS="$LEDS,"; fi
        # White/blue lightning
        if [ $offset -eq 0 ]; then
          LEDS="$LEDS$(led_json $led 255 255 255)"
        else
          LEDS="$LEDS$(led_json $led 200 200 255)"
        fi
      fi
    done
    
    # Branch sometimes
    if [ $((RANDOM % 3)) -eq 0 ]; then
      branch_offset=$((RANDOM % 20 - 10))
      branch_led=$((center + branch_offset))
      if [ $branch_led -ge $start ] && [ $branch_led -le $end ]; then
        LEDS="$LEDS,$(led_json $branch_led 180 180 255)"
      fi
    fi
  done
  send_frame $ORDER 50 "$LEDS"
  ORDER=$((ORDER + 1))
  
  # Brief dark
  send_frame $ORDER 30 ""
  ORDER=$((ORDER + 1))
  
  # STRIKE 2: Second flash (slightly different)
  LEDS=""
  first=true
  for step in {14..1}; do
    read start end count <<< "${STEPS[$step]}"
    pos_pct=${BOLT_POS[$step]:-50}
    jitter=$((RANDOM % 6 - 3))
    center=$((start + count * pos_pct / 100 + jitter))
    
    for ((offset=-3; offset<=3; offset++)); do
      led=$((center + offset))
      if [ $led -ge $start ] && [ $led -le $end ]; then
        if [ "$first" = true ]; then first=false; else LEDS="$LEDS,"; fi
        brightness=$((255 - (offset * offset * 15)))
        if [ $brightness -lt 100 ]; then brightness=100; fi
        LEDS="$LEDS$(led_json $led $brightness $brightness 255)"
      fi
    done
  done
  send_frame $ORDER 80 "$LEDS"
  ORDER=$((ORDER + 1))
  
  # Fade out
  for fade in 150 80 30; do
    LEDS=""
    first=true
    for step in {14..1}; do
      read start end count <<< "${STEPS[$step]}"
      pos_pct=${BOLT_POS[$step]:-50}
      center=$((start + count * pos_pct / 100))
      led=$center
      if [ $led -ge $start ] && [ $led -le $end ]; then
        if [ "$first" = true ]; then first=false; else LEDS="$LEDS,"; fi
        LEDS="$LEDS$(led_json $led $fade $fade $((fade + 50)))"
      fi
    done
    send_frame $ORDER 40 "$LEDS"
    ORDER=$((ORDER + 1))
  done
  
  # Pause between strikes
  send_frame $ORDER 500 ""
  ORDER=$((ORDER + 1))
done

echo ""
echo "✅ Lightning show created with $ORDER frames!"
echo ""
echo "▶️  To play: curl '${BASE_URL}/animation/lightning?repeat=true'"
