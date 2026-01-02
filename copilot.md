# JW Stairs LED Controller - Copilot Guide

This document helps you create LED shows and animations for your staircase lighting system.

## 📊 LED Configuration

- **Total LEDs:** 710
- **Total Steps:** 14
- **LED Range:** 0-709

## 🪜 Stair Step Mapping

Each step has LEDs running along it. The first and last LED of each step are the **edge LEDs** (side lights).

**Step 1 = Bottom (downstairs) → Step 14 = Top (upstairs)**

| Step | LED Start | LED End | LED Count | Left Edge | Right Edge | Position |
|------|-----------|---------|-----------|-----------|------------|----------|
| 1    | 0         | 47      | 48        | 0         | 47         | ⬇️ Bottom |
| 2    | 48        | 97      | 50        | 97        | 48         | |
| 3    | 98        | 147     | 50        | 98        | 147        | |
| 4    | 148       | 198     | 51        | 198       | 148        | |
| 5    | 199       | 248     | 50        | 199       | 248        | |
| 6    | 249       | 298     | 50        | 298       | 249        | |
| 7    | 299       | 347     | 49        | 299       | 347        | |
| 8    | 348       | 397     | 50        | 397       | 348        | |
| 9    | 398       | 451     | 54        | 398       | 451        | |
| 10   | 452       | 505     | 54        | 505       | 452        | |
| 11   | 506       | 559     | 54        | 506       | 559        | |
| 12   | 560       | 609     | 50        | 609       | 560        | |
| 13   | 610       | 658     | 49        | 610       | 658        | |
| 14   | 659       | 709     | 51        | 659       | 709        | ⬆️ Top |

### Quick Reference Arrays

```javascript
// All edge LEDs (both sides) - sorted by LED number
const ALL_EDGES = [0, 47, 48, 97, 98, 147, 148, 198, 199, 248, 249, 298, 299, 347, 348, 397, 398, 451, 452, 505, 506, 559, 560, 609, 610, 658, 659, 709];

// Left edge LEDs only (physical left side of staircase, step 1-14)
const LEFT_EDGES = [0, 97, 98, 198, 199, 298, 299, 397, 398, 505, 506, 609, 610, 659];

// Right edge LEDs only (physical right side of staircase, step 1-14)
const RIGHT_EDGES = [47, 48, 147, 148, 248, 249, 347, 348, 451, 452, 559, 560, 658, 709];

// Step ranges [start, end]
const STEPS = [
  [0, 47], [48, 97], [98, 147], [148, 198], [199, 248], [249, 298], [299, 347],
  [348, 397], [398, 451], [452, 505], [506, 559], [560, 609], [610, 658], [659, 709]
];
```

---

## 🌐 API Reference

**Base URL:** `http://<raspberry-pi-ip>:5001`

### Scenes

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/scenes` | List all scenes |
| GET | `/scenes/{id}` | Get a scene by ID |
| POST | `/scenes` | Create a new scene |
| PUT | `/scenes/{id}` | Update a scene |
| DELETE | `/scenes/{id}` | Delete a scene |

### Frames

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/scenes/{sceneId}/frames` | Get all frames for a scene |
| GET | `/scenes/{sceneId}/frames/{orderNr}` | Get a specific frame |
| POST | `/scenes/{sceneId}/frame` | Add a single frame |
| POST | `/scenes/{sceneId}/frames` | Add multiple frames |

### Animations (Built-in Shows)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/shows` | List all available shows |
| GET | `/animation/{show}` | Play a show |

**Animation Parameters:**
- `percentage` (int): Brightness 1-100% (default: 100)
- `repeat` (bool): Loop the animation (default: false)
- `color` (string): Hex color without `#` (e.g., `FF0000` for red)
- `blankColor` (string): Secondary color for some effects
- `colorOrder` (enum): `RGB`, `GRB`, `BGR`

---

## 📝 Data Models

### ApiScene
```json
{
  "id": 1,
  "name": "my_scene_name"
}
```

### ApiFrame
```json
{
  "orderNr": 0,
  "waitTillNextFrame": 100,
  "leds": [ /* ApiLed objects */ ]
}
```
- `orderNr`: Frame sequence number (must be unique within scene)
- `waitTillNextFrame`: Milliseconds to wait before next frame

### ApiLed
```json
{
  "ledNr": 0,
  "colorRed": 255,
  "colorGreen": 113,
  "colorBlue": 67,
  "colorAlpha": 0
}
```
- `ledNr`: LED index (0-709)
- `colorRed/Green/Blue`: Color values (0-255)
- `colorAlpha`: Transparency (0-255)

---

## 📚 Example Shows

### 1. Create a Scene

```bash
curl -X 'POST' \
  'http://192.168.178.77:5001/scenes' \
  -H 'Content-Type: application/json' \
  -d '{"name": "my_cool_show"}'
```

### 2. Light Up All Edge LEDs (Warm White)

```bash
curl -X 'POST' \
  'http://192.168.178.77:5001/scenes/1/frame' \
  -H 'Content-Type: application/json' \
  -d '{
  "orderNr": 0,
  "waitTillNextFrame": 0,
  "leds": [
    {"ledNr": 0, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 47, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 48, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 97, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 98, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 147, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 148, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 198, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 199, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 248, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 249, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 298, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 299, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 347, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 348, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 397, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 398, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 451, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 452, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 505, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 506, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 559, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 560, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 609, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 610, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 658, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 659, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0},
    {"ledNr": 709, "colorRed": 255, "colorGreen": 113, "colorBlue": 67, "colorAlpha": 0}
  ]
}'
```

### 3. Light Up a Full Step (Step 1 = Red)

```bash
curl -X 'POST' \
  'http://192.168.178.77:5001/scenes/1/frame' \
  -H 'Content-Type: application/json' \
  -d '{
  "orderNr": 0,
  "waitTillNextFrame": 0,
  "leds": [
    {"ledNr": 0, "colorRed": 255, "colorGreen": 0, "colorBlue": 0, "colorAlpha": 0},
    {"ledNr": 1, "colorRed": 255, "colorGreen": 0, "colorBlue": 0, "colorAlpha": 0},
    ... (LEDs 2-46)
    {"ledNr": 47, "colorRed": 255, "colorGreen": 0, "colorBlue": 0, "colorAlpha": 0}
  ]
}'
```

### 4. Play Built-in Animation

```bash
# Knight Rider effect at 50% brightness
curl 'http://192.168.178.77:5001/animation/knightrider?percentage=50'

# Rainbow effect
curl 'http://192.168.178.77:5001/animation/rainbow?percentage=75'

# Solid color (blue)
curl 'http://192.168.178.77:5001/animation/color?color=0000FF'

# Color wipe with custom color
curl 'http://192.168.178.77:5001/animation/colorwipe?color=00FF00'

# Theatre chase with two colors
curl 'http://192.168.178.77:5001/animation/theatrechase?color=FF0000&blankColor=000000&percentage=80'

# Play a saved scene with repeat
curl 'http://192.168.178.77:5001/animation/my_cool_show?repeat=true&percentage=100'
```

---

## 🎨 Common Color Values (RGB)

| Color | Red | Green | Blue | Hex |
|-------|-----|-------|------|-----|
| Warm White | 255 | 113 | 67 | `#FF7143` |
| Cool White | 255 | 255 | 255 | `#FFFFFF` |
| Red | 255 | 0 | 0 | `#FF0000` |
| Green | 0 | 255 | 0 | `#00FF00` |
| Blue | 0 | 0 | 255 | `#0000FF` |
| Yellow | 255 | 255 | 0 | `#FFFF00` |
| Cyan | 0 | 255 | 255 | `#00FFFF` |
| Magenta | 255 | 0 | 255 | `#FF00FF` |
| Orange | 255 | 165 | 0 | `#FFA500` |
| Purple | 128 | 0 | 128 | `#800080` |
| Off | 0 | 0 | 0 | `#000000` |

---

## 💡 Animation Ideas

### Stair Climb Effect
Create frames that light up each step sequentially from bottom to top:
- Frame 0: Light step 1 (LEDs 0-47)
- Frame 1: Light step 2 (LEDs 48-97)
- ... continue for all 14 steps
- Set `waitTillNextFrame` to control speed (e.g., 200ms)

### Breathing Effect
Create multiple frames with the same LEDs but varying brightness:
- Use lower RGB values for dimmer frames
- Cycle: dim → bright → dim

### Edge Runner
Light edges in sequence:
- Frame 0: LED 0
- Frame 1: LED 47
- Frame 2: LED 48
- ... continue through all edges

### Alternating Steps
- Even steps: One color
- Odd steps: Another color

---

## 🔧 Helper Script Template

Here's a template for generating LED data programmatically:

```javascript
// Generate LED data for a step
function generateStepLeds(stepNumber, r, g, b) {
  const steps = [
    [0, 47], [48, 97], [98, 147], [148, 198], [199, 248], [249, 298], [299, 347],
    [348, 397], [398, 451], [452, 505], [506, 559], [560, 609], [610, 658], [659, 709]
  ];
  const [start, end] = steps[stepNumber - 1];
  const leds = [];
  for (let i = start; i <= end; i++) {
    leds.push({
      ledNr: i,
      colorRed: r,
      colorGreen: g,
      colorBlue: b,
      colorAlpha: 0
    });
  }
  return leds;
}

// Generate edge LEDs only
function generateEdgeLeds(r, g, b) {
  const edges = [0, 47, 48, 97, 98, 147, 148, 198, 199, 248, 249, 298, 299, 347, 
                 348, 397, 398, 451, 452, 505, 506, 559, 560, 609, 610, 658, 659, 709];
  return edges.map(ledNr => ({
    ledNr,
    colorRed: r,
    colorGreen: g,
    colorBlue: b,
    colorAlpha: 0
  }));
}

// Generate a frame
function createFrame(orderNr, waitTillNextFrame, leds) {
  return {
    orderNr,
    waitTillNextFrame,
    leds
  };
}
```

---

## 📋 Troubleshooting

- **Error: "LedNr is less than 0 or greater than 709"** - LED numbers must be 0-709
- **Error: "Scene already has ordernr X"** - Each frame needs a unique `orderNr`
- **Animation not playing** - Check if scene name matches exactly (case-sensitive)
- **Colors look wrong** - Try different `colorOrder` (RGB, GRB, BGR)

---

## 🔗 Quick Links

- Swagger UI: `http://<ip>:5001/docs`
- All Shows: `GET /shows`
- Stop Animation: Start a new one (it cancels the previous)
