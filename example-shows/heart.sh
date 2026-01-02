#!/bin/bash
# Heart Shape Show - Creates a heart visible when standing at the bottom looking up
# Usage: ./heart.sh <sceneId>

SCENE_ID=${1:-1}
BASE_URL="http://192.168.178.77:5001"

if [ -z "$1" ]; then
  echo "Usage: ./heart.sh <sceneId>"
  echo "Example: ./heart.sh 5"
  exit 1
fi

echo "❤️  Creating Heart show for scene ID: $SCENE_ID"

# Step definitions: [start, end, count] for each step
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

# Get LEDs for a range on a step (from center offset)
# step, left_offset, right_offset (from center, as percentage 0-50)
get_step_range() {
  local step=$1
  local left_pct=$2
  local right_pct=$3
  local r=$4
  local g=$5
  local b=$6
  
  read start end count <<< "${STEPS[$step]}"
  local center=$((start + count / 2))
  local left_led=$((center - (count * left_pct / 100)))
  local right_led=$((center + (count * right_pct / 100)))
  
  # Clamp to valid range
  if [ $left_led -lt $start ]; then left_led=$start; fi
  if [ $right_led -gt $end ]; then right_led=$end; fi
  
  local result=""
  for ((led=left_led; led<=right_led; led++)); do
    if [ -n "$result" ]; then result="$result,"; fi
    result="$result$(led_json $led $r $g $b)"
  done
  echo "$result"
}

# Get two separate sections for the top bumps of the heart
get_two_bumps() {
  local step=$1
  local inner_pct=$2  # gap from center
  local outer_pct=$3  # outer edge
  local r=$4
  local g=$5
  local b=$6
  
  read start end count <<< "${STEPS[$step]}"
  local center=$((start + count / 2))
  
  # Left bump
  local left_outer=$((center - (count * outer_pct / 100)))
  local left_inner=$((center - (count * inner_pct / 100)))
  # Right bump
  local right_inner=$((center + (count * inner_pct / 100)))
  local right_outer=$((center + (count * outer_pct / 100)))
  
  # Clamp
  if [ $left_outer -lt $start ]; then left_outer=$start; fi
  if [ $right_outer -gt $end ]; then right_outer=$end; fi
  
  local result=""
  # Left bump
  for ((led=left_outer; led<=left_inner; led++)); do
    if [ -n "$result" ]; then result="$result,"; fi
    result="$result$(led_json $led $r $g $b)"
  done
  # Right bump
  for ((led=right_inner; led<=right_outer; led++)); do
    result="$result,$(led_json $led $r $g $b)"
  done
  echo "$result"
}

echo "📤 Sending frames..."

# Heart color: Red with pink glow
R=255
G=20
B=60

# Build the heart shape
# Looking up at stairs: Step 1=bottom, Step 14=top
# Heart point at bottom, bumps at top

LEDS=""

# Step 1: Bottom point of heart (narrow)
LEDS="$LEDS$(get_step_range 1 3 3 $R $G $B)"

# Step 2: Slightly wider
LEDS="$LEDS,$(get_step_range 2 8 8 $R $G $B)"

# Step 3: Wider
LEDS="$LEDS,$(get_step_range 3 14 14 $R $G $B)"

# Step 4: Wider still
LEDS="$LEDS,$(get_step_range 4 20 20 $R $G $B)"

# Step 5: Getting to widest
LEDS="$LEDS,$(get_step_range 5 26 26 $R $G $B)"

# Step 6: Near widest
LEDS="$LEDS,$(get_step_range 6 32 32 $R $G $B)"

# Step 7: Widest part
LEDS="$LEDS,$(get_step_range 7 38 38 $R $G $B)"

# Step 8: Still wide, starting to curve in
LEDS="$LEDS,$(get_step_range 8 42 42 $R $G $B)"

# Step 9: Maximum width (curved section)
LEDS="$LEDS,$(get_step_range 9 45 45 $R $G $B)"

# Step 10: Starting to indent at top
LEDS="$LEDS,$(get_step_range 10 44 44 $R $G $B)"

# Step 11: More indent - two bumps starting to form
LEDS="$LEDS,$(get_two_bumps 11 8 45 $R $G $B)"

# Step 12: Two bumps more pronounced
LEDS="$LEDS,$(get_two_bumps 12 12 42 $R $G $B)"

# Step 13: Two bumps at top
LEDS="$LEDS,$(get_two_bumps 13 18 38 $R $G $B)"

# Step 14: Top of heart bumps (smaller)
LEDS="$LEDS,$(get_two_bumps 14 22 35 $R $G $B)"

# Frame 0: Static heart
send_frame 0 3000 "$LEDS"

# Frame 1: Pulsing effect - slightly dimmer
LEDS_DIM=""
LEDS_DIM="$LEDS_DIM$(get_step_range 1 3 3 200 15 45)"
LEDS_DIM="$LEDS_DIM,$(get_step_range 2 8 8 200 15 45)"
LEDS_DIM="$LEDS_DIM,$(get_step_range 3 14 14 200 15 45)"
LEDS_DIM="$LEDS_DIM,$(get_step_range 4 20 20 200 15 45)"
LEDS_DIM="$LEDS_DIM,$(get_step_range 5 26 26 200 15 45)"
LEDS_DIM="$LEDS_DIM,$(get_step_range 6 32 32 200 15 45)"
LEDS_DIM="$LEDS_DIM,$(get_step_range 7 38 38 200 15 45)"
LEDS_DIM="$LEDS_DIM,$(get_step_range 8 42 42 200 15 45)"
LEDS_DIM="$LEDS_DIM,$(get_step_range 9 45 45 200 15 45)"
LEDS_DIM="$LEDS_DIM,$(get_step_range 10 44 44 200 15 45)"
LEDS_DIM="$LEDS_DIM,$(get_two_bumps 11 8 45 200 15 45)"
LEDS_DIM="$LEDS_DIM,$(get_two_bumps 12 12 42 200 15 45)"
LEDS_DIM="$LEDS_DIM,$(get_two_bumps 13 18 38 200 15 45)"
LEDS_DIM="$LEDS_DIM,$(get_two_bumps 14 22 35 200 15 45)"
send_frame 1 200 "$LEDS_DIM"

# Frame 2: Back to bright (heartbeat)
send_frame 2 800 "$LEDS"

# Frame 3: Dim again
send_frame 3 200 "$LEDS_DIM"

# Frame 4: Bright (complete heartbeat cycle)
send_frame 4 2000 "$LEDS"

echo ""
echo "✅ Heart show created with 5 frames (pulsing heartbeat)!"
echo ""
echo "▶️  To play: curl '${BASE_URL}/animation/heart?repeat=true'"
