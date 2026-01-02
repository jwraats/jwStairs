#!/bin/bash
# Christmas Side Lights Show - Festive red & green edge LEDs
# Usage: ./xmas_sides.sh <sceneId>

SCENE_ID=${1:-1}
BASE_URL="http://192.168.178.77:5001"

if [ -z "$1" ]; then
  echo "Usage: ./xmas_sides.sh <sceneId>"
  echo "Example: ./xmas_sides.sh 5"
  exit 1
fi

echo "🎄 Creating Christmas Side Lights show for scene ID: $SCENE_ID"

# Edge LEDs per step [left, right] based on copilot.md
# Left edges (physical left side)
LEFT_EDGES=(0 97 98 198 199 298 299 397 398 505 506 609 610 659)
# Right edges (physical right side)
RIGHT_EDGES=(47 48 147 148 248 249 347 348 451 452 559 560 658 709)

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

echo "📤 Sending frames..."

ORDER=0

# Christmas colors
# Red: (255, 0, 0)
# Green: (0, 255, 0)
# Gold/White: (255, 200, 100)

# Frame 0: Left=Red, Right=Green
LEDS=""
for i in "${!LEFT_EDGES[@]}"; do
  if [ -n "$LEDS" ]; then LEDS="$LEDS,"; fi
  LEDS="$LEDS$(led_json ${LEFT_EDGES[$i]} 255 0 0)"
done
for i in "${!RIGHT_EDGES[@]}"; do
  LEDS="$LEDS,$(led_json ${RIGHT_EDGES[$i]} 0 255 0)"
done
send_frame $ORDER 500 "$LEDS"
ORDER=$((ORDER + 1))

# Frame 1: Left=Green, Right=Red (swap)
LEDS=""
for i in "${!LEFT_EDGES[@]}"; do
  if [ -n "$LEDS" ]; then LEDS="$LEDS,"; fi
  LEDS="$LEDS$(led_json ${LEFT_EDGES[$i]} 0 255 0)"
done
for i in "${!RIGHT_EDGES[@]}"; do
  LEDS="$LEDS,$(led_json ${RIGHT_EDGES[$i]} 255 0 0)"
done
send_frame $ORDER 500 "$LEDS"
ORDER=$((ORDER + 1))

# Frame 2: Alternating per step - Red/Green pattern
LEDS=""
for i in "${!LEFT_EDGES[@]}"; do
  if [ -n "$LEDS" ]; then LEDS="$LEDS,"; fi
  if (( i % 2 == 0 )); then
    LEDS="$LEDS$(led_json ${LEFT_EDGES[$i]} 255 0 0)"
  else
    LEDS="$LEDS$(led_json ${LEFT_EDGES[$i]} 0 255 0)"
  fi
done
for i in "${!RIGHT_EDGES[@]}"; do
  LEDS="$LEDS,"
  if (( i % 2 == 0 )); then
    LEDS="$LEDS$(led_json ${RIGHT_EDGES[$i]} 0 255 0)"
  else
    LEDS="$LEDS$(led_json ${RIGHT_EDGES[$i]} 255 0 0)"
  fi
done
send_frame $ORDER 500 "$LEDS"
ORDER=$((ORDER + 1))

# Frame 3: Opposite alternating
LEDS=""
for i in "${!LEFT_EDGES[@]}"; do
  if [ -n "$LEDS" ]; then LEDS="$LEDS,"; fi
  if (( i % 2 == 1 )); then
    LEDS="$LEDS$(led_json ${LEFT_EDGES[$i]} 255 0 0)"
  else
    LEDS="$LEDS$(led_json ${LEFT_EDGES[$i]} 0 255 0)"
  fi
done
for i in "${!RIGHT_EDGES[@]}"; do
  LEDS="$LEDS,"
  if (( i % 2 == 1 )); then
    LEDS="$LEDS$(led_json ${RIGHT_EDGES[$i]} 0 255 0)"
  else
    LEDS="$LEDS$(led_json ${RIGHT_EDGES[$i]} 255 0 0)"
  fi
done
send_frame $ORDER 500 "$LEDS"
ORDER=$((ORDER + 1))

# Frame 4: All gold/white sparkle
LEDS=""
for i in "${!LEFT_EDGES[@]}"; do
  if [ -n "$LEDS" ]; then LEDS="$LEDS,"; fi
  LEDS="$LEDS$(led_json ${LEFT_EDGES[$i]} 255 200 100)"
done
for i in "${!RIGHT_EDGES[@]}"; do
  LEDS="$LEDS,$(led_json ${RIGHT_EDGES[$i]} 255 200 100)"
done
send_frame $ORDER 300 "$LEDS"
ORDER=$((ORDER + 1))

# Frame 5: Red chase going up (left side)
LEDS=""
for i in "${!LEFT_EDGES[@]}"; do
  if [ -n "$LEDS" ]; then LEDS="$LEDS,"; fi
  if (( i < 4 )); then
    LEDS="$LEDS$(led_json ${LEFT_EDGES[$i]} 255 0 0)"
  else
    LEDS="$LEDS$(led_json ${LEFT_EDGES[$i]} 50 0 0)"
  fi
done
for i in "${!RIGHT_EDGES[@]}"; do
  LEDS="$LEDS,$(led_json ${RIGHT_EDGES[$i]} 0 100 0)"
done
send_frame $ORDER 200 "$LEDS"
ORDER=$((ORDER + 1))

# Frames 6-12: Continue chase up
for chase in {1..7}; do
  LEDS=""
  for i in "${!LEFT_EDGES[@]}"; do
    if [ -n "$LEDS" ]; then LEDS="$LEDS,"; fi
    if (( i >= chase && i < chase + 4 )); then
      LEDS="$LEDS$(led_json ${LEFT_EDGES[$i]} 255 0 0)"
    else
      LEDS="$LEDS$(led_json ${LEFT_EDGES[$i]} 50 0 0)"
    fi
  done
  for i in "${!RIGHT_EDGES[@]}"; do
    LEDS="$LEDS,"
    if (( i >= chase && i < chase + 4 )); then
      LEDS="$LEDS$(led_json ${RIGHT_EDGES[$i]} 0 255 0)"
    else
      LEDS="$LEDS$(led_json ${RIGHT_EDGES[$i]} 0 50 0)"
    fi
  done
  send_frame $ORDER 200 "$LEDS"
  ORDER=$((ORDER + 1))
done

# Frames 13-19: Chase back down
for chase in {7..1}; do
  LEDS=""
  for i in "${!LEFT_EDGES[@]}"; do
    if [ -n "$LEDS" ]; then LEDS="$LEDS,"; fi
    if (( i >= chase && i < chase + 4 )); then
      LEDS="$LEDS$(led_json ${LEFT_EDGES[$i]} 0 255 0)"
    else
      LEDS="$LEDS$(led_json ${LEFT_EDGES[$i]} 0 50 0)"
    fi
  done
  for i in "${!RIGHT_EDGES[@]}"; do
    LEDS="$LEDS,"
    if (( i >= chase && i < chase + 4 )); then
      LEDS="$LEDS$(led_json ${RIGHT_EDGES[$i]} 255 0 0)"
    else
      LEDS="$LEDS$(led_json ${RIGHT_EDGES[$i]} 50 0 0)"
    fi
  done
  send_frame $ORDER 200 "$LEDS"
  ORDER=$((ORDER + 1))
done

# Final frame: All sparkle gold
LEDS=""
for i in "${!LEFT_EDGES[@]}"; do
  if [ -n "$LEDS" ]; then LEDS="$LEDS,"; fi
  LEDS="$LEDS$(led_json ${LEFT_EDGES[$i]} 255 220 150)"
done
for i in "${!RIGHT_EDGES[@]}"; do
  LEDS="$LEDS,$(led_json ${RIGHT_EDGES[$i]} 255 220 150)"
done
send_frame $ORDER 400 "$LEDS"
ORDER=$((ORDER + 1))

echo ""
echo "✅ Christmas Side Lights show created with $ORDER frames!"
echo ""
echo "▶️  To play: curl '${BASE_URL}/animation/xmas_sides?repeat=true'"
