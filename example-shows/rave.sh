#!/bin/bash
# Rave Mode Show - Intense rapid color flashing with strobe effects
# Usage: ./rave.sh <sceneId>

SCENE_ID=${1:-1}
BASE_URL="http://192.168.178.77:5001"

if [ -z "$1" ]; then
  echo "Usage: ./rave.sh <sceneId>"
  echo "Example: ./rave.sh 5"
  exit 1
fi

echo "🔊 Creating Rave Mode show for scene ID: $SCENE_ID"

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

generate_all_steps() {
  local r=$1
  local g=$2
  local b=$3
  local result=""
  local first=true
  
  for step in {1..14}; do
    read start end count <<< "${STEPS[$step]}"
    if [ "$first" = true ]; then first=false; else result="$result,"; fi
    result="$result$(generate_step $start $end $r $g $b)"
  done
  echo "$result"
}

echo "📤 Sending frames..."

ORDER=0

# Rave colors: Neon pink, electric blue, acid green, UV purple
RAVE_COLORS=(
  "255 0 150"   # Neon Pink
  "0 150 255"   # Electric Blue
  "150 255 0"   # Acid Green
  "180 0 255"   # UV Purple
  "255 100 0"   # Neon Orange
  "0 255 200"   # Electric Cyan
)
NUM_COLORS=${#RAVE_COLORS[@]}

# Pattern 1: Rapid strobe (white)
for ((i=0; i<8; i++)); do
  # White flash
  LEDS=$(generate_all_steps 255 255 255)
  send_frame $ORDER 30 "$LEDS"
  ORDER=$((ORDER + 1))
  
  # Blackout
  send_frame $ORDER 30 ""
  ORDER=$((ORDER + 1))
done

# Pattern 2: Color strobe cycling
for ((cycle=0; cycle<3; cycle++)); do
  for ((c=0; c<NUM_COLORS; c++)); do
    read -r r g b <<< "${RAVE_COLORS[$c]}"
    
    # Color flash
    LEDS=$(generate_all_steps $r $g $b)
    send_frame $ORDER 40 "$LEDS"
    ORDER=$((ORDER + 1))
    
    # Blackout
    send_frame $ORDER 20 ""
    ORDER=$((ORDER + 1))
  done
done

# Pattern 3: Split screen strobe (top/bottom alternating)
for ((i=0; i<12; i++)); do
  color_idx=$((i % NUM_COLORS))
  read -r r g b <<< "${RAVE_COLORS[$color_idx]}"
  
  LEDS=""
  first=true
  
  if [ $((i % 2)) -eq 0 ]; then
    # Bottom half lit
    for step in {1..7}; do
      read start end count <<< "${STEPS[$step]}"
      if [ "$first" = true ]; then first=false; else LEDS="$LEDS,"; fi
      LEDS="$LEDS$(generate_step $start $end $r $g $b)"
    done
  else
    # Top half lit
    for step in {8..14}; do
      read start end count <<< "${STEPS[$step]}"
      if [ "$first" = true ]; then first=false; else LEDS="$LEDS,"; fi
      LEDS="$LEDS$(generate_step $start $end $r $g $b)"
    done
  fi
  
  send_frame $ORDER 60 "$LEDS"
  ORDER=$((ORDER + 1))
done

# Pattern 4: Random step strobes
for ((i=0; i<20; i++)); do
  LEDS=""
  first=true
  
  # Light 3-5 random steps per frame
  num_lit=$((3 + RANDOM % 3))
  lit_steps=()
  
  for ((s=0; s<num_lit; s++)); do
    random_step=$((1 + RANDOM % 14))
    lit_steps+=($random_step)
  done
  
  for step in {1..14}; do
    read start end count <<< "${STEPS[$step]}"
    
    # Check if this step should be lit
    is_lit=false
    for lit in "${lit_steps[@]}"; do
      if [ $lit -eq $step ]; then
        is_lit=true
        break
      fi
    done
    
    if [ "$first" = true ]; then first=false; else LEDS="$LEDS,"; fi
    
    if [ "$is_lit" = true ]; then
      color_idx=$((RANDOM % NUM_COLORS))
      read -r r g b <<< "${RAVE_COLORS[$color_idx]}"
      LEDS="$LEDS$(generate_step $start $end $r $g $b)"
    else
      LEDS="$LEDS$(generate_step $start $end 0 0 0)"
    fi
  done
  
  send_frame $ORDER 50 "$LEDS"
  ORDER=$((ORDER + 1))
done

# Pattern 5: Bass drop build-up
# Increasing strobe speed
wait_times=(150 120 100 80 60 50 40 35 30 25 25 20 20 20 20)
for wait in "${wait_times[@]}"; do
  color_idx=$((RANDOM % NUM_COLORS))
  read -r r g b <<< "${RAVE_COLORS[$color_idx]}"
  
  LEDS=$(generate_all_steps $r $g $b)
  send_frame $ORDER $wait "$LEDS"
  ORDER=$((ORDER + 1))
  
  send_frame $ORDER $((wait / 2)) ""
  ORDER=$((ORDER + 1))
done

# Pattern 6: Final explosion - all colors
LEDS=""
first=true
for step in {1..14}; do
  read start end count <<< "${STEPS[$step]}"
  color_idx=$(( (step - 1) % NUM_COLORS))
  read -r r g b <<< "${RAVE_COLORS[$color_idx]}"
  
  if [ "$first" = true ]; then first=false; else LEDS="$LEDS,"; fi
  LEDS="$LEDS$(generate_step $start $end $r $g $b)"
done
send_frame $ORDER 500 "$LEDS"
ORDER=$((ORDER + 1))

echo ""
echo "✅ Rave Mode show created with $ORDER frames!"
echo ""
echo "▶️  To play: curl '${BASE_URL}/animation/rave?repeat=true'"
