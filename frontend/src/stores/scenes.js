import { defineStore } from 'pinia'
import { ref } from 'vue'
import { 
  getScenes, 
  getScene, 
  createScene, 
  updateScene, 
  deleteScene,
  getFrames
} from '@/services/api'

export const useScenesStore = defineStore('scenes', () => {
  const scenes = ref([])
  const currentScene = ref(null)
  const currentFrames = ref([])
  const loading = ref(false)
  const error = ref(null)

  async function fetchScenes() {
    loading.value = true
    error.value = null
    try {
      scenes.value = await getScenes()
    } catch (e) {
      error.value = e.message
    } finally {
      loading.value = false
    }
  }

  async function fetchScene(id) {
    loading.value = true
    error.value = null
    try {
      currentScene.value = await getScene(id)
      currentFrames.value = await getFrames(id)
    } catch (e) {
      error.value = e.message
    } finally {
      loading.value = false
    }
  }

  async function addScene(name) {
    loading.value = true
    error.value = null
    try {
      const newScene = await createScene(name)
      scenes.value.push(newScene)
      return newScene
    } catch (e) {
      error.value = e.message
      return null
    } finally {
      loading.value = false
    }
  }

  async function editScene(id, name) {
    loading.value = true
    error.value = null
    try {
      await updateScene(id, name)
      const index = scenes.value.findIndex(s => s.id === id)
      if (index !== -1) {
        scenes.value[index].name = name
      }
    } catch (e) {
      error.value = e.message
    } finally {
      loading.value = false
    }
  }

  async function removeScene(id) {
    loading.value = true
    error.value = null
    try {
      await deleteScene(id)
      scenes.value = scenes.value.filter(s => s.id !== id)
    } catch (e) {
      error.value = e.message
    } finally {
      loading.value = false
    }
  }

  return { 
    scenes, 
    currentScene, 
    currentFrames,
    loading, 
    error, 
    fetchScenes, 
    fetchScene,
    addScene, 
    editScene, 
    removeScene 
  }
})
