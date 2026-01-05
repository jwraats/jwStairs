# JW Stairs LED Controller - Copilot Guide

This document helps you create LED shows and animations for your staircase lighting system.

## 📊 LED Configuration

- **Total LEDs:** 710
- **Total Steps:** 14
- **LED Range:** 0-709

## 🏠 Physical Staircase Layout & Coordinate System

The staircase connects two floors with a curved/spiral section near the top.

### Coordinate System (Standing at bottom, looking up the stairs)

```
                    Z (Height/Up)
                    ↑
                    │
                    │    
                    │      ┌─────────────────┐ Step 14 (Top/Upstairs)
                    │     ╱                   │
                    │    ╱  Curved section    │ Steps 9-13
                    │   ╱   (wider steps)     │
                    │  │                      │
                    │  │   Straight section   │ Steps 1-8  
                    │  │                      │
                    └──┼──────────────────────┼────────→ Y (Depth into stairs)
                       │                      │
                       └──────────────────────┘ Step 1 (Bottom/Downstairs)
                      ╱
                     ╱
                    X (Left ← → Right)
```

### Axis Definitions

| Axis | Direction | Description |
|------|-----------|-------------|
| **X** | Left ↔ Right | Looking UP the stairs: Left = wall with handrail, Right = open side with metal railing |
| **Y** | Front ↔ Back | Depth of each step (LEDs run along Y-axis under the front edge of each step) |
| **Z** | Down ↔ Up | Height/floor level: Step 1 = ground floor, Step 14 = upstairs |

### Physical Structure

```
TOP VIEW (looking down from upstairs):
                                    
         ╭──────────────╮          
        ╱   Steps 12-14  ╲         ← Landing/top area
       │    (straight)    │        
       │                  │        
        ╲   Steps 9-11   ╱         ← Curved/wider section (54 LEDs each)
         ╲   (curved)   ╱          
          ╲            ╱           
           │ Step 8   │            
           │ Step 7   │            
           │ Step 6   │            ← Straight section
           │ Step 5   │            
           │ Step 4   │            
           │ Step 3   │            
           │ Step 2   │            
           │ Step 1   │            ← Bottom (ground floor)
           └──────────┘            
          LEFT    RIGHT            
         (Wall)  (Railing)         
```

```
FRONT VIEW (standing at bottom, looking up):

    Step 14  ════════════════════  ← Upstairs (Top)
    Step 13  ════════════════════  
    Step 12  ════════════════════  
    Step 11  ══════════════════════════  ← Wider (curved section)
    Step 10  ══════════════════════════  
    Step 9   ══════════════════════════  
    Step 8   ════════════════════  
    Step 7   ════════════════════  
    Step 6   ════════════════════  
    Step 5   ════════════════════  ← Straight section
    Step 4   ════════════════════  
    Step 3   ════════════════════  
    Step 2   ════════════════════  
    Step 1   ════════════════════  ← Downstairs (Bottom)
            │                    │
          LEFT                RIGHT
         (Wall)              (Railing)
    
    LEDs run horizontally under the front edge of each step
    Edge LEDs = first & last LED of each step (the side glow)
```

### LED Strip Orientation

- LEDs are mounted **under the front lip (nosing)** of each step
- The strip runs from one side to the other along the **Y-axis**
- **Zigzag wiring pattern**: alternating direction per step to minimize wiring
  - Odd steps (1,3,5,7,9,11,13): Left → Right
  - Even steps (2,4,6,8,10,12): Right → Left  
  - Exception: Step 14 also runs Left → Right

## 🪜 Stair Step Mapping

Each step has LEDs running along it. The first and last LED of each step are the **edge LEDs** (side lights).

**Step 1 = Bottom (downstairs) → Step 14 = Top (upstairs)**

| Step | LED Start | LED End | LED Count | Left Edge | Right Edge | Section |
|------|-----------|---------|-----------|-----------|------------|---------|
| 1    | 0         | 47      | 48        | 0         | 47         | Straight ⬇️ |
| 2    | 48        | 97      | 50        | 97        | 48         | Straight |
| 3    | 98        | 147     | 50        | 98        | 147        | Straight |
| 4    | 148       | 198     | 51        | 198       | 148        | Straight |
| 5    | 199       | 248     | 50        | 199       | 248        | Straight |
| 6    | 249       | 298     | 50        | 298       | 249        | Straight |
| 7    | 299       | 347     | 49        | 299       | 347        | Straight |
| 8    | 348       | 397     | 50        | 397       | 348        | Straight |
| 9    | 398       | 451     | 54        | 398       | 451        | Curved 🔄 |
| 10   | 452       | 505     | 54        | 505       | 452        | Curved |
| 11   | 506       | 559     | 54        | 506       | 559        | Curved |
| 12   | 560       | 609     | 50        | 609       | 560        | Top |
| 13   | 610       | 658     | 49        | 610       | 658        | Top |
| 14   | 659       | 709     | 51        | 659       | 709        | Top ⬆️ |

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

## 🎮 Simulator Mode

The simulator allows you to test animations without physical LED hardware. Enable it by setting `SimulationMode` to `true` in `appsettings.json`:

```json
{
  "JWStairs": {
    "LedCount": 710,
    "SimulationMode": true
  }
}
```

### Simulator Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/simulator/status` | GET | Check if simulation mode is enabled |
| `/leds` | GET | Get current LED state (colors for all 710 LEDs) |
| `/leds/stream` | GET | Server-Sent Events stream for real-time LED updates |

### Web Interface

When the server is running, navigate to `/simulator` in the web interface to see a visual representation of your staircase with real-time LED updates.

---

## 🎬 GIF Preview Generation

Generate animated GIF previews of LED shows for documentation and PR reviews.

### Preview Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/animation/{show}/preview` | GET | Generate GIF preview for a built-in animation |
| `/scenes/{sceneId}/preview` | GET | Generate GIF preview for a custom scene |

### Animation Preview Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `frames` | int | 60 | Number of frames to capture |
| `delay` | int | 50 | Delay between frames in milliseconds |
| `color` | string | - | Hex color code (e.g., `FF0000`) |
| `blankColor` | string | - | Secondary color for theatre chase |

### Scene Preview Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `maxFrames` | int | 100 | Maximum frames to include |
| `speed` | double | 1.0 | Speed multiplier (2.0 = 2x faster) |

### Example URLs

```bash
# Knight Rider animation preview
http://localhost:5001/animation/knightrider/preview

# Rainbow animation with 100 frames
http://localhost:5001/animation/rainbow/preview?frames=100

# Color wipe with custom color
http://localhost:5001/animation/colorwipe/preview?color=00FF00

# Custom scene preview
http://localhost:5001/scenes/1/preview?speed=1.5
```

---

## 🚀 PR Workflow: Adding New Shows

**IMPORTANT**: When creating a PR that adds new LED shows or animations, always include a GIF preview so reviewers can see how the animation looks.

### Steps for Adding a New Show

1. **Create your scene** using the API:
   ```bash
   curl -X POST 'http://localhost:5001/scenes' \
     -H 'Content-Type: application/json' \
     -d '{"name": "my_new_show"}'
   ```

2. **Add frames** to your scene (see examples above)

3. **Generate a GIF preview**:
   ```bash
   # For custom scenes:
   curl -o my_new_show.gif 'http://localhost:5001/scenes/{sceneId}/preview'
   
   # For built-in animations:
   curl -o animation_preview.gif 'http://localhost:5001/animation/{name}/preview'
   ```

4. **Include the GIF in your PR description**:
   ```markdown
   ## New Animation: My New Show
   
   This PR adds a new staircase animation called "my_new_show".
   
   ### Preview
   ![my_new_show](./previews/my_new_show.gif)
   
   ### Description
   This animation creates a wave effect from bottom to top...
   ```

5. **Store preview GIFs** in the `example-shows/` directory for reference

### Copilot Instructions

When asked to create a new LED show:

1. ✅ Create the scene and frames via API
2. ✅ Test the animation using the simulator (`/simulator`)
3. ✅ Generate a GIF preview using `/animation/{name}/preview` or `/scenes/{id}/preview`
4. ✅ Save the GIF to `example-shows/` directory
5. ✅ Include the GIF preview in the PR description
6. ✅ Document any special parameters or effects

### Embedding GIF in PR (GitHub)

You can directly reference the preview endpoint in your PR if the server is running:

```markdown
![Animation Preview](http://localhost:5001/animation/my_show/preview)
```

Or download and commit the GIF:
```bash
curl -o example-shows/my_show.gif 'http://localhost:5001/animation/my_show/preview?frames=60'
```

---

## 🔗 Quick Links

- Swagger UI: `http://<ip>:5001/docs`
- All Shows: `GET /shows`
- Stop Animation: Start a new one (it cancels the previous)
- Simulator: `http://<ip>:5001/simulator`
- GIF Preview: `http://<ip>:5001/animation/{show}/preview`
