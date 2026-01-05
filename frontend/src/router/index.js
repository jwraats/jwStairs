import { createRouter, createWebHistory } from 'vue-router'
import AnimationsView from '../views/AnimationsView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'animations',
      component: AnimationsView,
    },
    {
      path: '/scenes',
      name: 'scenes',
      component: () => import('../views/ScenesView.vue'),
    },
    {
      path: '/scenes/:id',
      name: 'scene-detail',
      component: () => import('../views/SceneDetailView.vue'),
    },
    {
      path: '/simulator',
      name: 'simulator',
      component: () => import('../views/SimulatorView.vue'),
    },
  ],
})

export default router
