<script setup>
import { onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useScenesStore } from '@/stores/scenes'
import { useShowsStore } from '@/stores/shows'

const route = useRoute()
const router = useRouter()
const scenesStore = useScenesStore()
const showsStore = useShowsStore()

const sceneId = computed(() => parseInt(route.params.id))

async function playScene() {
  if (scenesStore.currentScene) {
    await showsStore.playAnimation(scenesStore.currentScene.name, { 
      repeat: false, 
      percentage: 100 
    })
  }
}

function goBack() {
  router.push('/scenes')
}

onMounted(() => {
  scenesStore.fetchScene(sceneId.value)
})
</script>

<template>
  <div class="scene-detail-view">
    <header class="page-header">
      <button class="btn-back" @click="goBack">← Back</button>
      <div v-if="scenesStore.currentScene" class="header-content">
        <h1>{{ scenesStore.currentScene.name }}</h1>
        <button class="btn btn-primary" @click="playScene">
          ▶️ Play Scene
        </button>
      </div>
    </header>

    <div v-if="scenesStore.loading" class="loading">
      Loading scene...
    </div>
    
    <div v-else-if="scenesStore.error" class="error">
      Error: {{ scenesStore.error }}
    </div>
    
    <div v-else-if="scenesStore.currentScene" class="scene-content">
      <section class="info-section">
        <h2>Scene Information</h2>
        <div class="info-grid">
          <div class="info-item">
            <span class="info-label">ID</span>
            <span class="info-value">{{ scenesStore.currentScene.id }}</span>
          </div>
          <div class="info-item">
            <span class="info-label">Name</span>
            <span class="info-value">{{ scenesStore.currentScene.name }}</span>
          </div>
          <div class="info-item">
            <span class="info-label">Frames</span>
            <span class="info-value">{{ scenesStore.currentFrames.length }}</span>
          </div>
        </div>
      </section>

      <section class="frames-section">
        <h2>Frames</h2>
        
        <div v-if="scenesStore.currentFrames.length === 0" class="empty-state">
          <p>No frames in this scene yet.</p>
          <p class="hint">Use the API to add frames to this scene.</p>
        </div>
        
        <div v-else class="frames-list">
          <div 
            v-for="frame in scenesStore.currentFrames" 
            :key="frame.orderNr" 
            class="frame-card"
          >
            <div class="frame-header">
              <span class="frame-order">Frame {{ frame.orderNr }}</span>
              <span class="frame-delay">{{ frame.waitTillNextFrame }}ms delay</span>
            </div>
            <div class="frame-leds">
              <span class="led-count">{{ frame.leds.length }} LEDs</span>
              <div class="led-preview">
                <div 
                  v-for="(led, idx) in frame.leds.slice(0, 10)" 
                  :key="idx"
                  class="led-dot"
                  :style="{
                    backgroundColor: `rgb(${led.colorRed}, ${led.colorGreen}, ${led.colorBlue})`
                  }"
                  :title="`LED ${led.ledNr}: RGB(${led.colorRed}, ${led.colorGreen}, ${led.colorBlue})`"
                ></div>
                <span v-if="frame.leds.length > 10" class="more-leds">
                  +{{ frame.leds.length - 10 }} more
                </span>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
  </div>
</template>

<style scoped>
.scene-detail-view {
  max-width: 900px;
  margin: 0 auto;
}

.page-header {
  margin-bottom: 2rem;
}

.btn-back {
  background: transparent;
  border: none;
  color: #a0aec0;
  font-size: 1rem;
  cursor: pointer;
  padding: 0.5rem 0;
  margin-bottom: 1rem;
  transition: color 0.2s ease;
}

.btn-back:hover {
  color: #fff;
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-content h1 {
  color: #fff;
  margin: 0;
  font-size: 1.75rem;
}

.btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: #fff;
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.scene-content {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.info-section, .frames-section {
  background: #1a1a2e;
  border-radius: 16px;
  padding: 1.5rem;
}

h2 {
  color: #fff;
  margin: 0 0 1.25rem;
  font-size: 1.25rem;
  font-weight: 600;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 1rem;
}

.info-item {
  background: #2d3748;
  border-radius: 8px;
  padding: 1rem;
}

.info-label {
  display: block;
  color: #a0aec0;
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 0.25rem;
}

.info-value {
  color: #fff;
  font-size: 1.125rem;
  font-weight: 600;
}

.frames-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.frame-card {
  background: #2d3748;
  border-radius: 12px;
  padding: 1rem 1.25rem;
}

.frame-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.75rem;
}

.frame-order {
  color: #fff;
  font-weight: 600;
}

.frame-delay {
  color: #a0aec0;
  font-size: 0.875rem;
}

.frame-leds {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.led-count {
  color: #a0aec0;
  font-size: 0.875rem;
  min-width: 80px;
}

.led-preview {
  display: flex;
  align-items: center;
  gap: 4px;
  flex-wrap: wrap;
}

.led-dot {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  border: 2px solid rgba(255, 255, 255, 0.2);
}

.more-leds {
  color: #a0aec0;
  font-size: 0.75rem;
  margin-left: 0.5rem;
}

.loading, .error, .empty-state {
  text-align: center;
  padding: 3rem;
  color: #a0aec0;
}

.error {
  color: #fc8181;
}

.empty-state p {
  margin: 0.5rem 0;
}

.hint {
  font-size: 0.875rem;
  color: #718096;
}
</style>
