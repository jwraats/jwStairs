import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueDevTools from 'vite-plugin-vue-devtools'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    vue(),
    vueDevTools(),
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    },
  },
  server: {
    proxy: {
      '/scenes': {
        target: 'http://localhost:5001',
        changeOrigin: true
      },
      '/shows': {
        target: 'http://localhost:5001',
        changeOrigin: true
      },
      '/animation': {
        target: 'http://localhost:5001',
        changeOrigin: true
      },
      '/leds': {
        target: 'http://localhost:5001',
        changeOrigin: true
      },
      '/simulator': {
        target: 'http://localhost:5001',
        changeOrigin: true
      }
    }
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets'
  }
})
