#!/bin/bash
# Party Mode Show - Vibrant color cycling with beat-like pulsing effects
# Usage: ./party.sh <sceneId>

SCENE_ID=${1:-1}
BASE_URL="http://192.168.178.77:5001"

if [ -z "$1" ]; then
  echo "Usage: ./party.sh <sceneId>"
  echo "Example: ./party.sh 5"
  exit 1
fi

echo "🎉 Creating Party Mode show for scene ID: $SCENE_ID"

# Step definitions: [start, end, count]
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

# Party colors: Magenta, Cyan, Yellow, Purple, Orange, Green
COLORS=(
  "255 0 255"   # Magenta
  "0 255 255"   # Cyan
  "255 255 0"   # Yellow
  "128 0 255"   # Purple
  "255 128 0"   # Orange
  "0 255 128"   # Green
)
NUM_COLORS=${#COLORS[@]}

# Pattern 1: Color wave (each step gets a different color, rotating)
for ((cycle=0; cycle<NUM_COLORS; cycle++)); do
  LEDS=""
  first=true
  
  for step in {1..14}; do
    color_idx=$(( (step + cycle) % NUM_COLORS ))
    read -r r g b <<< "${COLORS[$color_idx]}"
    read start end count <<< "${STEPS[$step]}"
    
    if [ "$first" = true ]; then
      first=false
    else
      LEDS="$LEDS,"
    fi
    LEDS="$LEDS$(generate_step $start $end $r $g $b)"
  done
  
  send_frame $ORDER 150 "$LEDS"
  ORDER=$((ORDER + 1))
done

# Pattern 2: Beat pulse (all LEDs flash to the beat)
for beat in {1..8}; do
  # Flash ON - random party color
  color_idx=$((RANDOM % NUM_COLORS))
  read -r r g b <<< "${COLORS[$color_idx]}"
  
  LEDS=""
  first=true
  for step in {1..14}; do
    read start end count <<< "${STEPS[$step]}"
    if [ "$first" = true ]; then first=false; else LEDS="$LEDS,"; fi
    LEDS="$LEDS$(generate_step $start $end $r $g $b)"
  done
  send_frame $ORDER 100 "$LEDS"
  ORDER=$((ORDER + 1))
  
  # Flash OFF (dim)
  LEDS=""
  first=true
  for step in {1..14}; do
    read start end count <<< "${STEPS[$step]}"
    if [ "$first" = true ]; then first=false; else LEDS="$LEDS,"; fi
    LEDS="$LEDS$(generate_step $start $end $((r/5)) $((g/5)) $((b/5)))"
  done
  send_frame $ORDER 100 "$LEDS"
  ORDER=$((ORDER + 1))
done

# Pattern 3: Alternating steps (even/odd different colors)
for ((cycle=0; cycle<6; cycle++)); do
  color1_idx=$((cycle % NUM_COLORS))
  color2_idx=$(( (cycle + 3) % NUM_COLORS))
  read -r r1 g1 b1 <<< "${COLORS[$color1_idx]}"
  read -r r2 g2 b2 <<< "${COLORS[$color2_idx]}"
  
  LEDS=""
  first=true
  for step in {1..14}; do
    read start end count <<< "${STEPS[$step]}"
    if [ "$first" = true ]; then first=false; else LEDS="$LEDS,"; fi
    
    if [ $((step % 2)) -eq 0 ]; then
      LEDS="$LEDS$(generate_step $start $end $r1 $g1 $b1)"
    else
      LEDS="$LEDS$(generate_step $start $end $r2 $g2 $b2)"
    fi
  done
  send_frame $ORDER 200 "$LEDS"
  ORDER=$((ORDER + 1))
done

# Pattern 4: Rising color from bottom to top
for color_idx in {0..5}; do
  read -r r g b <<< "${COLORS[$color_idx]}"
  
  for step in {1..14}; do
    LEDS=""
    first=true
    
    for s in {1..14}; do
      read start end count <<< "${STEPS[$s]}"
      if [ "$first" = true ]; then first=false; else LEDS="$LEDS,"; fi
      
      if [ $s -le $step ]; then
        LEDS="$LEDS$(generate_step $start $end $r $g $b)"
      else
        LEDS="$LEDS$(generate_step $start $end 20 20 20)"
      fi
    done
    
    send_frame $ORDER 40 "$LEDS"
    ORDER=$((ORDER + 1))
  done
done

# Pattern 5: Multi-color strobe finale
for ((i=0; i<16; i++)); do
  LEDS=""
  first=true
  
  for step in {1..14}; do
    # Each step gets random color
    color_idx=$((RANDOM % NUM_COLORS))
    read -r r g b <<< "${COLORS[$color_idx]}"
    read start end count <<< "${STEPS[$step]}"
    
    if [ "$first" = true ]; then first=false; else LEDS="$LEDS,"; fi
    LEDS="$LEDS$(generate_step $start $end $r $g $b)"
  done
  
  send_frame $ORDER 80 "$LEDS"
  ORDER=$((ORDER + 1))
done

echo ""
echo "✅ Party Mode show created with $ORDER frames!"
echo ""
echo "▶️  To play: curl '${BASE_URL}/animation/party?repeat=true'"
