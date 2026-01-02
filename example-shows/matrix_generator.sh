#!/bin/bash
# Matrix Show Generator - Creates the full matrix effect using all 710 LEDs
# Usage: ./matrix_generator.sh <sceneId> > matrix_frames.curl

SCENE_ID=${1:-1}
BASE_URL="http://192.168.178.77:5001"

# Step definitions: [start, end] for each step (1-14, bottom to top)
declare -a STEPS=(
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
  local first=true
  
  for ((led=start; led<=end; led++)); do
    if [ "$first" = true ]; then
      first=false
    else
      echo ","
    fi
    echo "    {\"ledNr\": $led, \"colorRed\": 0, \"colorGreen\": $green, \"colorBlue\": 0, \"colorAlpha\": 0}"
  done
}

# Build frames array
echo "curl -X 'POST' \\"
echo "  '${BASE_URL}/scenes/${SCENE_ID}/frames' \\"
echo "  -H 'accept: */*' \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '["

ORDER=0
TOTAL_STEPS=14

# Matrix falling effect: from top (step 14) to bottom (step 1)
# Each frame lights up the current step bright, with trailing fade behind
for ((current=TOTAL_STEPS-1; current>=0; current--)); do
  echo "  {"
  echo "    \"orderNr\": $ORDER,"
  echo "    \"waitTillNextFrame\": 60,"
  echo "    \"leds\": ["
  
  first_led=true
  
  # Bright (current step)
  if [ $current -ge 0 ] && [ $current -lt $TOTAL_STEPS ]; then
    read start end <<< "${STEPS[$current]}"
    if [ "$first_led" = false ]; then echo ","; fi
    generate_step_leds $start $end 255
    first_led=false
  fi
  
  # Medium fade (1 step behind)
  trail1=$((current + 1))
  if [ $trail1 -lt $TOTAL_STEPS ]; then
    read start end <<< "${STEPS[$trail1]}"
    echo ","
    generate_step_leds $start $end 80
  fi
  
  # Dim fade (2 steps behind)
  trail2=$((current + 2))
  if [ $trail2 -lt $TOTAL_STEPS ]; then
    read start end <<< "${STEPS[$trail2]}"
    echo ","
    generate_step_leds $start $end 25
  fi
  
  echo ""
  echo "    ]"
  
  ORDER=$((ORDER + 1))
  if [ $current -gt 0 ]; then
    echo "  },"
  else
    echo "  },"
  fi
done

# Fade out frames
for fade in 80 25; do
  echo "  {"
  echo "    \"orderNr\": $ORDER,"
  echo "    \"waitTillNextFrame\": 60,"
  echo "    \"leds\": ["
  
  read start end <<< "${STEPS[0]}"
  generate_step_leds $start $end $fade
  
  if [ $fade -eq 80 ]; then
    echo ","
    read start end <<< "${STEPS[1]}"
    generate_step_leds $start $end 25
  fi
  
  echo ""
  echo "    ]"
  echo "  },"
  ORDER=$((ORDER + 1))
done

# Final empty frame
echo "  {"
echo "    \"orderNr\": $ORDER,"
echo "    \"waitTillNextFrame\": 100,"
echo "    \"leds\": []"
echo "  }"

echo "]'"
