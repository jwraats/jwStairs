import { defineStore } from 'pinia'
import { ref } from 'vue'
import { getShows, playAnimation as playAnimationApi } from '@/services/api'

export const useShowsStore = defineStore('shows', () => {
  const shows = ref([])
  const loading = ref(false)
  const error = ref(null)
  const currentShow = ref(null)

  async function fetchShows() {
    loading.value = true
    error.value = null
    try {
      shows.value = await getShows()
    } catch (e) {
      error.value = e.message
    } finally {
      loading.value = false
    }
  }

  async function playAnimation(show, options = {}) {
    loading.value = true
    error.value = null
    try {
      await playAnimationApi(show, options)
      currentShow.value = show
    } catch (e) {
      error.value = e.message
    } finally {
      loading.value = false
    }
  }

  return { shows, loading, error, currentShow, fetchShows, playAnimation }
})
