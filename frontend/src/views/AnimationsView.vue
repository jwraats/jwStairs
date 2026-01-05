<script setup>
import { onMounted, ref } from 'vue'
import { useShowsStore } from '@/stores/shows'

const showsStore = useShowsStore()

// Animation options
const selectedColor = ref('#FF0000')
const blankColor = ref('#000000')
const percentage = ref(100)
const repeat = ref(false)
const colorOrder = ref('RGB')

const colorOrders = ['RGB', 'RBG', 'GRB', 'GBR', 'BRG', 'BGR']

// Built-in animations that have specific requirements
const colorAnimations = ['color', 'colorwipe']
const dualColorAnimations = ['theatrechase']

// Show icon mapping
const showIcons = {
  knightrider: '🚗',
  knightrider_green: '🚗',
  knightrider_blue: '🚗',
  theatrechase: '🎭',
  rainbow: '🌈',
  colorwipe: '🎨',
  color: '🔴'
}

function getShowIcon(show) {
  return showIcons[show] || '✨'
}

function formatShowName(show) {
  return show.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
}

function needsColor(show) {
  return colorAnimations.includes(show) || dualColorAnimations.includes(show)
}

function needsBlankColor(show) {
  return dualColorAnimations.includes(show)
}

function hexToNoHash(hex) {
  return hex.replace('#', '')
}

async function playShow(show) {
  const options = {
    percentage: percentage.value,
    repeat: repeat.value,
    colorOrder: colorOrder.value
  }
  
  if (needsColor(show)) {
    options.color = hexToNoHash(selectedColor.value)
  }
  
  if (needsBlankColor(show)) {
    options.blankColor = hexToNoHash(blankColor.value)
  }
  
  await showsStore.playAnimation(show, options)
}

async function turnOff() {
  await showsStore.playAnimation('color', { color: '000000', percentage: 100 })
}

onMounted(() => {
  showsStore.fetchShows()
})
</script>

<template>
  <div class="animations-view">
    <section class="controls-panel">
      <h2>Animation Controls</h2>
      
      <div class="control-group">
        <label>Brightness</label>
        <div class="slider-container">
          <input 
            type="range" 
            v-model.number="percentage" 
            min="1" 
            max="100" 
            class="slider"
          />
          <span class="slider-value">{{ percentage }}%</span>
        </div>
      </div>

      <div class="control-group">
        <label>Primary Color</label>
        <div class="color-picker-container">
          <input type="color" v-model="selectedColor" class="color-picker" />
          <span class="color-value">{{ selectedColor }}</span>
        </div>
      </div>

      <div class="control-group">
        <label>Secondary Color (Theatre Chase)</label>
        <div class="color-picker-container">
          <input type="color" v-model="blankColor" class="color-picker" />
          <span class="color-value">{{ blankColor }}</span>
        </div>
      </div>

      <div class="control-group">
        <label>Color Order</label>
        <select v-model="colorOrder" class="select-input">
          <option v-for="order in colorOrders" :key="order" :value="order">
            {{ order }}
          </option>
        </select>
      </div>

      <div class="control-group checkbox-group">
        <label class="checkbox-label">
          <input type="checkbox" v-model="repeat" />
          <span>Repeat Animation</span>
        </label>
      </div>

      <button class="btn btn-danger" @click="turnOff">
        🔌 Turn Off LEDs
      </button>
    </section>

    <section class="shows-panel">
      <h2>Available Shows</h2>
      
      <div v-if="showsStore.loading" class="loading">
        Loading shows...
      </div>
      
      <div v-else-if="showsStore.error" class="error">
        Error: {{ showsStore.error }}
      </div>
      
      <div v-else class="shows-grid">
        <button 
          v-for="show in showsStore.shows" 
          :key="show"
          class="show-card"
          :class="{ active: showsStore.currentShow === show }"
          @click="playShow(show)"
        >
          <span class="show-icon">{{ getShowIcon(show) }}</span>
          <span class="show-name">{{ formatShowName(show) }}</span>
        </button>
      </div>
    </section>
  </div>
</template>

<style scoped>
.animations-view {
  display: grid;
  grid-template-columns: 320px 1fr;
  gap: 2rem;
  max-width: 1400px;
  margin: 0 auto;
}

.controls-panel, .shows-panel {
  background: #1a1a2e;
  border-radius: 16px;
  padding: 1.5rem;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
}

h2 {
  margin: 0 0 1.5rem;
  color: #fff;
  font-size: 1.25rem;
  font-weight: 600;
}

.control-group {
  margin-bottom: 1.25rem;
}

.control-group label {
  display: block;
  color: #a0aec0;
  font-size: 0.875rem;
  margin-bottom: 0.5rem;
}

.slider-container {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.slider {
  flex: 1;
  height: 8px;
  border-radius: 4px;
  background: #2d3748;
  appearance: none;
  cursor: pointer;
}

.slider::-webkit-slider-thumb {
  appearance: none;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  cursor: pointer;
}

.slider-value {
  color: #fff;
  font-weight: 600;
  min-width: 48px;
}

.color-picker-container {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.color-picker {
  width: 60px;
  height: 40px;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  background: transparent;
}

.color-value {
  color: #fff;
  font-family: monospace;
}

.select-input {
  width: 100%;
  padding: 0.75rem;
  background: #2d3748;
  border: 1px solid #4a5568;
  border-radius: 8px;
  color: #fff;
  font-size: 1rem;
  cursor: pointer;
}

.checkbox-group {
  margin-top: 1.5rem;
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  cursor: pointer;
  color: #fff;
}

.checkbox-label input {
  width: 18px;
  height: 18px;
  cursor: pointer;
}

.btn {
  width: 100%;
  padding: 1rem;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  margin-top: 1rem;
}

.btn-danger {
  background: linear-gradient(135deg, #e53e3e 0%, #c53030 100%);
  color: #fff;
}

.btn-danger:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(229, 62, 62, 0.4);
}

.shows-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 1rem;
}

.show-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 1.5rem 1rem;
  background: #2d3748;
  border: 2px solid transparent;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.show-card:hover {
  background: #3d4a5c;
  transform: translateY(-2px);
}

.show-card.active {
  border-color: #667eea;
  background: linear-gradient(135deg, rgba(102, 126, 234, 0.2) 0%, rgba(118, 75, 162, 0.2) 100%);
}

.show-icon {
  font-size: 2rem;
  margin-bottom: 0.5rem;
}

.show-name {
  color: #fff;
  font-size: 0.875rem;
  text-align: center;
  word-break: break-word;
}

.loading, .error {
  color: #a0aec0;
  text-align: center;
  padding: 2rem;
}

.error {
  color: #fc8181;
}

@media (max-width: 768px) {
  .animations-view {
    grid-template-columns: 1fr;
  }
}
</style>
