<script setup>
import { onMounted, onUnmounted, ref, computed } from 'vue'
import { getSimulatorStatus, subscribeLedUpdates } from '@/services/api'

// Stair step LED mapping from copilot.md
// Zigzag wiring pattern:
// - Odd steps (1,3,5,7,9,11,13): Left → Right (reversed = false)
// - Even steps (2,4,6,8,10,12): Right → Left (reversed = true)
// - Exception: Step 14 also runs Left → Right (reversed = false)
const STEPS = [
  { step: 1, start: 0, end: 47, count: 48, section: 'straight', reversed: false },
  { step: 2, start: 48, end: 97, count: 50, section: 'straight', reversed: true },
  { step: 3, start: 98, end: 147, count: 50, section: 'straight', reversed: false },
  { step: 4, start: 148, end: 198, count: 51, section: 'straight', reversed: true },
  { step: 5, start: 199, end: 248, count: 50, section: 'straight', reversed: false },
  { step: 6, start: 249, end: 298, count: 50, section: 'straight', reversed: true },
  { step: 7, start: 299, end: 347, count: 49, section: 'straight', reversed: false },
  { step: 8, start: 348, end: 397, count: 50, section: 'straight', reversed: true },
  { step: 9, start: 398, end: 451, count: 54, section: 'curved', reversed: false },
  { step: 10, start: 452, end: 505, count: 54, section: 'curved', reversed: true },
  { step: 11, start: 506, end: 559, count: 54, section: 'curved', reversed: false },
  { step: 12, start: 560, end: 609, count: 50, section: 'top', reversed: true },
  { step: 13, start: 610, end: 658, count: 49, section: 'top', reversed: false },
  { step: 14, start: 659, end: 709, count: 51, section: 'top', reversed: false }
]

const simulatorStatus = ref(null)
const ledColors = ref([])
const eventSource = ref(null)
const connectionStatus = ref('connecting')
const error = ref(null)

// Computed property to organize LEDs by step
const stepLeds = computed(() => {
  if (ledColors.value.length === 0) return []
  
  return STEPS.map(step => {
    const leds = []
    // Build LEDs in display order (always left to right for visual)
    // For reversed steps (even steps), we need to reverse the LED order
    if (step.reversed) {
      // Even steps run Right → Left in wiring, so reverse for display
      for (let i = step.end; i >= step.start; i--) {
        const color = ledColors.value[i] || { r: 0, g: 0, b: 0 }
        leds.push({
          ledNr: i,
          color: `rgb(${color.r}, ${color.g}, ${color.b})`,
          isOn: color.r > 0 || color.g > 0 || color.b > 0
        })
      }
    } else {
      // Odd steps (and step 14) run Left → Right, display as-is
      for (let i = step.start; i <= step.end; i++) {
        const color = ledColors.value[i] || { r: 0, g: 0, b: 0 }
        leds.push({
          ledNr: i,
          color: `rgb(${color.r}, ${color.g}, ${color.b})`,
          isOn: color.r > 0 || color.g > 0 || color.b > 0
        })
      }
    }
    return {
      ...step,
      leds
    }
  })
})

// Get average color of a step for the glow effect
function getStepGlow(step) {
  if (!step.leds.length) return 'transparent'
  
  let totalR = 0, totalG = 0, totalB = 0
  step.leds.forEach(led => {
    const color = ledColors.value[led.ledNr] || { r: 0, g: 0, b: 0 }
    totalR += color.r
    totalG += color.g
    totalB += color.b
  })
  
  const avgR = Math.round(totalR / step.leds.length)
  const avgG = Math.round(totalG / step.leds.length)
  const avgB = Math.round(totalB / step.leds.length)
  
  if (avgR === 0 && avgG === 0 && avgB === 0) return 'transparent'
  
  return `rgba(${avgR}, ${avgG}, ${avgB}, 0.6)`
}

function getStepWidth(step) {
  // Curved section has wider steps
  if (step.section === 'curved') return '110%'
  return '100%'
}

async function connect() {
  connectionStatus.value = 'connecting'
  error.value = null
  
  try {
    simulatorStatus.value = await getSimulatorStatus()
    
    if (!simulatorStatus.value.simulationMode) {
      error.value = 'Simulation mode is not enabled on the server. Set "SimulationMode": true in appsettings.json'
      connectionStatus.value = 'error'
      return
    }
    
    // Initialize LED colors array - use Array.from to create unique objects
    ledColors.value = Array.from({ length: simulatorStatus.value.ledCount }, () => ({ r: 0, g: 0, b: 0 }))
    
    // Subscribe to LED updates
    eventSource.value = subscribeLedUpdates(
      (colors) => {
        ledColors.value = colors
        connectionStatus.value = 'connected'
      },
      (err) => {
        console.error('SSE error:', err)
        connectionStatus.value = 'error'
        // Attempt to reconnect after delay
        setTimeout(connect, 3000)
      }
    )
    
    connectionStatus.value = 'connected'
  } catch (e) {
    error.value = e.message
    connectionStatus.value = 'error'
  }
}

onMounted(() => {
  connect()
})

onUnmounted(() => {
  if (eventSource.value) {
    eventSource.value.close()
  }
})
</script>

<template>
  <div class="simulator-view">
    <div class="header-section">
      <h2>🎮 Staircase Simulator</h2>
      <div class="connection-status" :class="connectionStatus">
        <span class="status-dot"></span>
        <span v-if="connectionStatus === 'connecting'">Connecting...</span>
        <span v-else-if="connectionStatus === 'connected'">Live</span>
        <span v-else>Disconnected</span>
      </div>
    </div>

    <div v-if="error" class="error-message">
      <p>{{ error }}</p>
      <p class="error-hint">Make sure the backend is running with SimulationMode enabled.</p>
    </div>

    <div v-else class="staircase-container">
      <div class="staircase">
        <!-- Floor labels -->
        <div class="floor-label top-label">⬆️ Upstairs</div>
        
        <!-- Steps rendered from top to bottom (step 14 at top, step 1 at bottom) -->
        <div 
          v-for="step in [...stepLeds].reverse()" 
          :key="step.step"
          class="step-container"
          :class="step.section"
        >
          <div class="step-number">{{ step.step }}</div>
          <div 
            class="step"
            :style="{ 
              width: getStepWidth(step),
              boxShadow: `0 0 20px 5px ${getStepGlow(step)}, 0 0 40px 10px ${getStepGlow(step)}`
            }"
          >
            <div class="step-surface">
              <div class="led-strip">
                <div 
                  v-for="led in step.leds" 
                  :key="led.ledNr"
                  class="led"
                  :class="{ on: led.isOn }"
                  :style="{ backgroundColor: led.color }"
                  :title="`LED ${led.ledNr}`"
                ></div>
              </div>
            </div>
            <div class="step-riser"></div>
          </div>
          <div class="step-info">
            <span class="led-range">LEDs {{ step.start }}-{{ step.end }}</span>
          </div>
        </div>
        
        <div class="floor-label bottom-label">⬇️ Downstairs</div>
      </div>
      
      <!-- Legend -->
      <div class="legend">
        <h3>Staircase Layout</h3>
        <div class="legend-items">
          <div class="legend-item">
            <div class="legend-color straight"></div>
            <span>Straight Section (Steps 1-8)</span>
          </div>
          <div class="legend-item">
            <div class="legend-color curved"></div>
            <span>Curved Section (Steps 9-11)</span>
          </div>
          <div class="legend-item">
            <div class="legend-color top"></div>
            <span>Top Landing (Steps 12-14)</span>
          </div>
        </div>
        <div class="stats">
          <p>Total LEDs: 710</p>
          <p>Total Steps: 14</p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.simulator-view {
  max-width: 1400px;
  margin: 0 auto;
}

.header-section {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

h2 {
  margin: 0;
  color: #fff;
  font-size: 1.5rem;
}

.connection-status {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-size: 0.875rem;
  font-weight: 500;
}

.connection-status.connecting {
  background: rgba(234, 179, 8, 0.2);
  color: #eab308;
}

.connection-status.connected {
  background: rgba(34, 197, 94, 0.2);
  color: #22c55e;
}

.connection-status.error {
  background: rgba(239, 68, 68, 0.2);
  color: #ef4444;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: currentColor;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.error-message {
  background: rgba(239, 68, 68, 0.1);
  border: 1px solid rgba(239, 68, 68, 0.3);
  border-radius: 12px;
  padding: 2rem;
  text-align: center;
  color: #ef4444;
}

.error-hint {
  color: #a0aec0;
  font-size: 0.875rem;
  margin-top: 0.5rem;
}

.staircase-container {
  display: grid;
  grid-template-columns: 1fr 280px;
  gap: 2rem;
}

.staircase {
  background: linear-gradient(180deg, #1a1a2e 0%, #0f0f1a 100%);
  border-radius: 16px;
  padding: 2rem;
  position: relative;
  overflow: hidden;
}

.floor-label {
  text-align: center;
  padding: 1rem;
  font-size: 1rem;
  font-weight: 600;
  color: #a0aec0;
}

.step-container {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 4px;
  padding-left: 2rem;
}

.step-container.curved {
  padding-left: 0;
}

.step-number {
  width: 24px;
  text-align: center;
  font-size: 0.75rem;
  color: #64748b;
  font-weight: 600;
}

.step {
  flex: 1;
  position: relative;
  transition: box-shadow 0.1s ease;
}

.step-surface {
  background: linear-gradient(90deg, #2d3748 0%, #3d4a5c 50%, #2d3748 100%);
  border-radius: 4px 4px 0 0;
  padding: 6px 8px;
  position: relative;
  z-index: 1;
}

.step-riser {
  height: 12px;
  background: linear-gradient(180deg, #1a1a2e 0%, #0f0f1a 100%);
  border-radius: 0 0 2px 2px;
  margin-top: -1px;
}

.led-strip {
  display: flex;
  gap: 1px;
  justify-content: center;
}

.led {
  width: 4px;
  height: 4px;
  border-radius: 50%;
  background: #1a1a2e;
  transition: all 0.05s ease;
  flex-shrink: 0;
}

.led.on {
  box-shadow: 0 0 4px 1px currentColor;
}

.step-info {
  width: 100px;
  text-align: right;
}

.led-range {
  font-size: 0.625rem;
  color: #4a5568;
}

.legend {
  background: #1a1a2e;
  border-radius: 16px;
  padding: 1.5rem;
}

.legend h3 {
  margin: 0 0 1rem;
  color: #fff;
  font-size: 1rem;
}

.legend-items {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.legend-color {
  width: 24px;
  height: 12px;
  border-radius: 2px;
}

.legend-color.straight {
  background: #3d4a5c;
}

.legend-color.curved {
  background: linear-gradient(90deg, #4a5568 0%, #667eea 100%);
}

.legend-color.top {
  background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
}

.legend-item span {
  font-size: 0.875rem;
  color: #a0aec0;
}

.stats {
  margin-top: 1.5rem;
  padding-top: 1rem;
  border-top: 1px solid #2d3748;
}

.stats p {
  margin: 0.25rem 0;
  font-size: 0.875rem;
  color: #64748b;
}

@media (max-width: 1024px) {
  .staircase-container {
    grid-template-columns: 1fr;
  }
  
  .legend {
    order: -1;
  }
}

@media (max-width: 640px) {
  .step-info {
    display: none;
  }
  
  .led {
    width: 3px;
    height: 3px;
  }
}
</style>
