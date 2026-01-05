#!/bin/bash
# Rainbow Strobe Show - Fast rainbow color transitions with strobe flashes
# Usage: ./rainbow_strobe.sh <sceneId>

SCENE_ID=${1:-1}
BASE_URL="http://192.168.178.77:5001"

if [ -z "$1" ]; then
  echo "Usage: ./rainbow_strobe.sh <sceneId>"
  echo "Example: ./rainbow_strobe.sh 5"
  exit 1
fi

echo "🌈⚡ Creating Rainbow Strobe show for scene ID: $SCENE_ID"

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

# Rainbow colors
RAINBOW=(
  "255 0 0"     # Red
  "255 127 0"   # Orange
  "255 255 0"   # Yellow
  "0 255 0"     # Green
  "0 0 255"     # Blue
  "75 0 130"    # Indigo
  "148 0 211"   # Violet
)
NUM_RAINBOW=${#RAINBOW[@]}

# Pattern 1: Rainbow wave across steps with strobe
for ((cycle=0; cycle<4; cycle++)); do
  for ((offset=0; offset<NUM_RAINBOW; offset++)); do
    LEDS=""
    first=true
    
    for step in {1..14}; do
      color_idx=$(( (step + offset) % NUM_RAINBOW))
      read -r r g b <<< "${RAINBOW[$color_idx]}"
      read start end count <<< "${STEPS[$step]}"
      
      if [ "$first" = true ]; then first=false; else LEDS="$LEDS,"; fi
      LEDS="$LEDS$(generate_step $start $end $r $g $b)"
    done
    
    send_frame $ORDER 80 "$LEDS"
    ORDER=$((ORDER + 1))
    
    # Quick white strobe flash every 3rd frame
    if [ $((offset % 3)) -eq 0 ]; then
      LEDS=$(generate_all_steps 255 255 255)
      send_frame $ORDER 20 "$LEDS"
      ORDER=$((ORDER + 1))
    fi
  done
done

# Pattern 2: Full rainbow strobe
for ((c=0; c<NUM_RAINBOW; c++)); do
  read -r r g b <<< "${RAINBOW[$c]}"
  
  # Color flash
  LEDS=$(generate_all_steps $r $g $b)
  send_frame $ORDER 60 "$LEDS"
  ORDER=$((ORDER + 1))
  
  # White strobe
  LEDS=$(generate_all_steps 255 255 255)
  send_frame $ORDER 30 "$LEDS"
  ORDER=$((ORDER + 1))
done

# Pattern 3: Rainbow sweep up then down with strobes
# Up sweep
for step in {1..14}; do
  LEDS=""
  first=true
  
  for s in {1..14}; do
    read start end count <<< "${STEPS[$s]}"
    
    if [ "$first" = true ]; then first=false; else LEDS="$LEDS,"; fi
    
    if [ $s -le $step ]; then
      color_idx=$(( (s - 1) % NUM_RAINBOW))
      read -r r g b <<< "${RAINBOW[$color_idx]}"
      LEDS="$LEDS$(generate_step $start $end $r $g $b)"
    else
      LEDS="$LEDS$(generate_step $start $end 0 0 0)"
    fi
  done
  
  send_frame $ORDER 50 "$LEDS"
  ORDER=$((ORDER + 1))
done

# White flash at peak
LEDS=$(generate_all_steps 255 255 255)
send_frame $ORDER 30 "$LEDS"
ORDER=$((ORDER + 1))

# Down sweep
for step in {14..1}; do
  LEDS=""
  first=true
  
  for s in {1..14}; do
    read start end count <<< "${STEPS[$s]}"
    
    if [ "$first" = true ]; then first=false; else LEDS="$LEDS,"; fi
    
    if [ $s -le $step ]; then
      color_idx=$(( (s - 1) % NUM_RAINBOW))
      read -r r g b <<< "${RAINBOW[$color_idx]}"
      LEDS="$LEDS$(generate_step $start $end $r $g $b)"
    else
      LEDS="$LEDS$(generate_step $start $end 0 0 0)"
    fi
  done
  
  send_frame $ORDER 50 "$LEDS"
  ORDER=$((ORDER + 1))
done

# Pattern 4: Rapid rainbow strobe finale
for ((i=0; i<21; i++)); do
  color_idx=$((i % NUM_RAINBOW))
  read -r r g b <<< "${RAINBOW[$color_idx]}"
  
  LEDS=$(generate_all_steps $r $g $b)
  send_frame $ORDER 40 "$LEDS"
  ORDER=$((ORDER + 1))
  
  # Blackout between
  send_frame $ORDER 20 ""
  ORDER=$((ORDER + 1))
done

# Final full rainbow display
LEDS=""
first=true
for step in {1..14}; do
  color_idx=$(( (step - 1) % NUM_RAINBOW))
  read -r r g b <<< "${RAINBOW[$color_idx]}"
  read start end count <<< "${STEPS[$step]}"
  
  if [ "$first" = true ]; then first=false; else LEDS="$LEDS,"; fi
  LEDS="$LEDS$(generate_step $start $end $r $g $b)"
done
send_frame $ORDER 800 "$LEDS"
ORDER=$((ORDER + 1))

echo ""
echo "✅ Rainbow Strobe show created with $ORDER frames!"
echo ""
echo "▶️  To play: curl '${BASE_URL}/animation/rainbow_strobe?repeat=true'"
