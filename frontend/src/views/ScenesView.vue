<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useScenesStore } from '@/stores/scenes'
import { useShowsStore } from '@/stores/shows'

const router = useRouter()
const scenesStore = useScenesStore()
const showsStore = useShowsStore()

const newSceneName = ref('')
const showCreateForm = ref(false)
const editingScene = ref(null)
const editName = ref('')

async function createScene() {
  if (!newSceneName.value.trim()) return
  
  await scenesStore.addScene(newSceneName.value.trim())
  newSceneName.value = ''
  showCreateForm.value = false
}

function startEdit(scene) {
  editingScene.value = scene.id
  editName.value = scene.name
}

async function saveEdit() {
  if (!editName.value.trim()) return
  
  await scenesStore.editScene(editingScene.value, editName.value.trim())
  editingScene.value = null
  editName.value = ''
}

function cancelEdit() {
  editingScene.value = null
  editName.value = ''
}

async function deleteScene(id) {
  if (confirm('Are you sure you want to delete this scene?')) {
    await scenesStore.removeScene(id)
  }
}

async function playScene(sceneName) {
  await showsStore.playAnimation(sceneName, { repeat: false, percentage: 100 })
}

function viewScene(id) {
  router.push(`/scenes/${id}`)
}

onMounted(() => {
  scenesStore.fetchScenes()
})
</script>

<template>
  <div class="scenes-view">
    <header class="page-header">
      <h1>Scenes</h1>
      <button 
        v-if="!showCreateForm" 
        class="btn btn-primary" 
        @click="showCreateForm = true"
      >
        + Create Scene
      </button>
    </header>

    <div v-if="showCreateForm" class="create-form">
      <input 
        v-model="newSceneName" 
        type="text" 
        placeholder="Scene name..."
        class="text-input"
        @keyup.enter="createScene"
      />
      <div class="form-actions">
        <button class="btn btn-success" @click="createScene">Create</button>
        <button class="btn btn-secondary" @click="showCreateForm = false">Cancel</button>
      </div>
    </div>

    <div v-if="scenesStore.loading" class="loading">
      Loading scenes...
    </div>
    
    <div v-else-if="scenesStore.error" class="error">
      Error: {{ scenesStore.error }}
    </div>
    
    <div v-else-if="scenesStore.scenes.length === 0" class="empty-state">
      <p>No scenes yet. Create your first scene!</p>
    </div>
    
    <div v-else class="scenes-list">
      <div 
        v-for="scene in scenesStore.scenes" 
        :key="scene.id" 
        class="scene-card"
      >
        <div v-if="editingScene === scene.id" class="scene-edit">
          <input 
            v-model="editName" 
            type="text" 
            class="text-input"
            @keyup.enter="saveEdit"
            @keyup.escape="cancelEdit"
          />
          <button class="btn btn-success btn-sm" @click="saveEdit">Save</button>
          <button class="btn btn-secondary btn-sm" @click="cancelEdit">Cancel</button>
        </div>
        
        <template v-else>
          <div class="scene-info" @click="viewScene(scene.id)">
            <span class="scene-icon">🎬</span>
            <span class="scene-name">{{ scene.name }}</span>
          </div>
          
          <div class="scene-actions">
            <button class="btn-icon" title="Play" @click.stop="playScene(scene.name)">
              ▶️
            </button>
            <button class="btn-icon" title="Edit" @click.stop="startEdit(scene)">
              ✏️
            </button>
            <button class="btn-icon" title="Delete" @click.stop="deleteScene(scene.id)">
              🗑️
            </button>
          </div>
        </template>
      </div>
    </div>
  </div>
</template>

<style scoped>
.scenes-view {
  max-width: 800px;
  margin: 0 auto;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.page-header h1 {
  color: #fff;
  margin: 0;
  font-size: 1.75rem;
}

.create-form {
  background: #1a1a2e;
  border-radius: 12px;
  padding: 1.5rem;
  margin-bottom: 2rem;
}

.text-input {
  width: 100%;
  padding: 0.75rem 1rem;
  background: #2d3748;
  border: 1px solid #4a5568;
  border-radius: 8px;
  color: #fff;
  font-size: 1rem;
  margin-bottom: 1rem;
}

.text-input:focus {
  outline: none;
  border-color: #667eea;
}

.form-actions {
  display: flex;
  gap: 0.75rem;
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

.btn-sm {
  padding: 0.5rem 1rem;
  font-size: 0.875rem;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: #fff;
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.btn-success {
  background: linear-gradient(135deg, #48bb78 0%, #38a169 100%);
  color: #fff;
}

.btn-secondary {
  background: #4a5568;
  color: #fff;
}

.btn-secondary:hover {
  background: #5a6578;
}

.scenes-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.scene-card {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 1.5rem;
  background: #1a1a2e;
  border-radius: 12px;
  transition: all 0.2s ease;
}

.scene-card:hover {
  background: #222240;
}

.scene-info {
  display: flex;
  align-items: center;
  gap: 1rem;
  cursor: pointer;
  flex: 1;
}

.scene-icon {
  font-size: 1.5rem;
}

.scene-name {
  color: #fff;
  font-size: 1.125rem;
  font-weight: 500;
}

.scene-actions {
  display: flex;
  gap: 0.5rem;
}

.btn-icon {
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #2d3748;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-size: 1.125rem;
  transition: all 0.2s ease;
}

.btn-icon:hover {
  background: #3d4a5c;
  transform: scale(1.1);
}

.scene-edit {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  width: 100%;
}

.scene-edit .text-input {
  margin-bottom: 0;
  flex: 1;
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
  font-size: 1.125rem;
}
</style>
