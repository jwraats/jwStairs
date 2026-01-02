#!/bin/bash
# Go Downstairs Show - Arrow animation going from top to bottom
# Usage: ./go_downstairs.sh <sceneId>

SCENE_ID=${1:-1}
BASE_URL="http://192.168.178.77:5001"

if [ -z "$1" ]; then
  echo "Usage: ./go_downstairs.sh <sceneId>"
  echo "Example: ./go_downstairs.sh 5"
  exit 1
fi

echo "⬇️  Creating Go Downstairs show for scene ID: $SCENE_ID"

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

# Generate full step with color
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
TOTAL_STEPS=14

# Arrow colors - cool white/blue gradient for downward motion
# Bright head: cool white (200, 220, 255)
# Medium trail: (150, 165, 200)
# Dim trail: (80, 90, 120)

# Go downstairs: from step 13 (top) to step 0 (bottom)
for ((current=TOTAL_STEPS-1; current>=0; current--)); do
  LEDS=""
  
  # Bright (current step - arrow head)
  read start end <<< "${STEPS[$current]}"
  LEDS=$(generate_step $start $end 200 220 255)
  
  # Medium fade (1 step behind = above)
  trail1=$((current + 1))
  if [ $trail1 -lt $TOTAL_STEPS ]; then
    read start end <<< "${STEPS[$trail1]}"
    LEDS="$LEDS,$(generate_step $start $end 120 135 180)"
  fi
  
  # Dim fade (2 steps behind)
  trail2=$((current + 2))
  if [ $trail2 -lt $TOTAL_STEPS ]; then
    read start end <<< "${STEPS[$trail2]}"
    LEDS="$LEDS,$(generate_step $start $end 60 70 100)"
  fi
  
  # Very dim (3 steps behind)
  trail3=$((current + 3))
  if [ $trail3 -lt $TOTAL_STEPS ]; then
    read start end <<< "${STEPS[$trail3]}"
    LEDS="$LEDS,$(generate_step $start $end 20 25 40)"
  fi
  
  send_frame $ORDER 100 "$LEDS"
  ORDER=$((ORDER + 1))
done

# Fade out at bottom
for fade in 1 2 3; do
  LEDS=""
  
  step=$((fade - 1))
  if [ $step -lt $TOTAL_STEPS ]; then
    read start end <<< "${STEPS[$step]}"
    case $fade in
      1) LEDS=$(generate_step $start $end 120 135 180) ;;
      2) LEDS=$(generate_step $start $end 60 70 100) ;;
      3) LEDS=$(generate_step $start $end 20 25 40) ;;
    esac
  fi
  
  # Add remaining trails above
  for ((t=1; t<=3; t++)); do
    trail=$((step + t))
    if [ $trail -lt $TOTAL_STEPS ]; then
      read start end <<< "${STEPS[$trail]}"
      case $((fade + t)) in
        2) LEDS="$LEDS,$(generate_step $start $end 120 135 180)" ;;
        3) LEDS="$LEDS,$(generate_step $start $end 60 70 100)" ;;
        4) LEDS="$LEDS,$(generate_step $start $end 20 25 40)" ;;
      esac
    fi
  done
  
  if [ -n "$LEDS" ]; then
    send_frame $ORDER 100 "$LEDS"
    ORDER=$((ORDER + 1))
  fi
done

# Final empty frame
send_frame $ORDER 200 ""
ORDER=$((ORDER + 1))

echo ""
echo "✅ Go Downstairs show created with $ORDER frames!"
echo ""
echo "▶️  To play: curl '${BASE_URL}/animation/go_downstairs?repeat=true'"
