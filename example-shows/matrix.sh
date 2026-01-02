#!/bin/bash
# Matrix Show - Creates and runs the full matrix effect using all 710 LEDs
# Usage: ./matrix.sh <sceneId>

SCENE_ID=${1:-1}
BASE_URL="http://192.168.178.77:5001"

if [ -z "$1" ]; then
  echo "Usage: ./matrix.sh <sceneId>"
  echo "Example: ./matrix.sh 5"
  exit 1
fi

echo "🎬 Creating Matrix show for scene ID: $SCENE_ID"

# Step definitions: [start, end] for each step (1-14, bottom to top)
STEPS=(
  "0 47"
  "48 97"
  "98 147"
  "148 198"
  "199 248"
  "249 298"
  "299 347"
  "348 397"
  "398 451"
  "452 505"
  "506 559"
  "560 609"
  "610 658"
  "659 709"
)

# Generate LED JSON for a step with specific brightness
generate_step_leds() {
  local start=$1
  local end=$2
  local green=$3
  local result=""
  
  for ((led=start; led<=end; led++)); do
    if [ -n "$result" ]; then
      result="$result,"
    fi
    result="$result{\"ledNr\":$led,\"colorRed\":0,\"colorGreen\":$green,\"colorBlue\":0,\"colorAlpha\":0}"
  done
  echo "$result"
}

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

ORDER=0
TOTAL_STEPS=14

echo "📤 Sending frames..."

# Matrix falling effect: from top (step 14) to bottom (step 1)
for ((current=TOTAL_STEPS-1; current>=0; current--)); do
  LEDS=""
  
  # Bright (current step)
  read start end <<< "${STEPS[$current]}"
  LEDS=$(generate_step_leds $start $end 255)
  
  # Medium fade (1 step behind)
  trail1=$((current + 1))
  if [ $trail1 -lt $TOTAL_STEPS ]; then
    read start end <<< "${STEPS[$trail1]}"
    LEDS="$LEDS,$(generate_step_leds $start $end 80)"
  fi
  
  # Dim fade (2 steps behind)
  trail2=$((current + 2))
  if [ $trail2 -lt $TOTAL_STEPS ]; then
    read start end <<< "${STEPS[$trail2]}"
    LEDS="$LEDS,$(generate_step_leds $start $end 25)"
  fi
  
  send_frame $ORDER 60 "$LEDS"
  ORDER=$((ORDER + 1))
done

# Fade out frame 1: step 1 medium + step 2 dim
read start end <<< "${STEPS[0]}"
LEDS=$(generate_step_leds $start $end 80)
read start end <<< "${STEPS[1]}"
LEDS="$LEDS,$(generate_step_leds $start $end 25)"
send_frame $ORDER 60 "$LEDS"
ORDER=$((ORDER + 1))

# Fade out frame 2: step 1 dim
read start end <<< "${STEPS[0]}"
LEDS=$(generate_step_leds $start $end 25)
send_frame $ORDER 60 "$LEDS"
ORDER=$((ORDER + 1))

# Final empty frame
send_frame $ORDER 100 ""
ORDER=$((ORDER + 1))

echo ""
echo "✅ Matrix show created with $ORDER frames!"
echo ""
echo "▶️  To play: curl '${BASE_URL}/animation/matrix?repeat=true'"
