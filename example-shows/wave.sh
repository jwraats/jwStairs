#!/bin/bash
# Wave Show - A sine wave rippling up the stairs
# Usage: ./wave.sh <sceneId>

SCENE_ID=${1:-1}
BASE_URL="http://192.168.178.77:5001"

if [ -z "$1" ]; then
  echo "Usage: ./wave.sh <sceneId>"
  echo "Example: ./wave.sh 5"
  exit 1
fi

echo "🌊 Creating Wave show for scene ID: $SCENE_ID"

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

led_json() {
  echo "{\"ledNr\":$1,\"colorRed\":$2,\"colorGreen\":$3,\"colorBlue\":$4,\"colorAlpha\":0}"
}

echo "📤 Sending frames..."

# Wave parameters
WAVE_LENGTH=6  # Steps per full wave
NUM_FRAMES=24  # Frames for one complete cycle

for ((frame=0; frame<NUM_FRAMES; frame++)); do
  LEDS=""
  first=true
  
  for step in {1..14}; do
    read start end count <<< "${STEPS[$step]}"
    
    # Calculate wave position for this step and frame
    # Wave moves upward over time
    phase=$(echo "scale=4; (($step + $frame * 14 / $NUM_FRAMES) % $WAVE_LENGTH) / $WAVE_LENGTH * 6.283" | bc)
    
    # Sine wave determines the horizontal position (0 to 1, mapped to LED range)
    # Using integer math approximation
    wave_pos=$(echo "scale=4; (s($phase) + 1) / 2" | bc -l)
    
    # Wave width varies with position
    wave_width=$(echo "scale=0; 5 + ($wave_pos * 10)/1" | bc)
    
    # Center LED for this step based on wave
    center_offset=$(echo "scale=0; ($wave_pos * $count)/1" | bc)
    center=$((start + center_offset))
    
    # Create a blob of lit LEDs around the center
    left=$((center - wave_width))
    right=$((center + wave_width))
    if [ $left -lt $start ]; then left=$start; fi
    if [ $right -gt $end ]; then right=$end; fi
    
    for ((led=left; led<=right; led++)); do
      # Color: ocean blue with brightness based on distance from center
      dist=$((led - center))
      if [ $dist -lt 0 ]; then dist=$((-dist)); fi
      brightness=$((255 - dist * 20))
      if [ $brightness -lt 50 ]; then brightness=50; fi
      
      if [ "$first" = true ]; then
        first=false
      else
        LEDS="$LEDS,"
      fi
      # Ocean colors: teal/cyan
      r=$((brightness / 5))
      g=$((brightness * 3 / 4))
      b=$brightness
      LEDS="$LEDS$(led_json $led $r $g $b)"
    done
  done
  
  send_frame $frame 80 "$LEDS"
done

echo ""
echo "✅ Wave show created with $NUM_FRAMES frames!"
echo ""
echo "▶️  To play: curl '${BASE_URL}/animation/wave?repeat=true'"
