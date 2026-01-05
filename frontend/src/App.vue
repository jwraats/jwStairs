<script setup>
import { RouterLink, RouterView } from 'vue-router'
</script>

<template>
  <div class="app-container">
    <header class="app-header">
      <div class="logo-section">
        <span class="logo-icon">💡</span>
        <h1>JW Stairs</h1>
      </div>
      <nav class="main-nav">
        <RouterLink to="/">Animations</RouterLink>
        <RouterLink to="/scenes">Scenes</RouterLink>
        <RouterLink to="/simulator">Simulator</RouterLink>
      </nav>
    </header>

    <main class="main-content">
      <RouterView />
    </main>
  </div>
</template>

<style scoped>
.app-container {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.app-header {
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
  padding: 1rem 2rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.3);
}

.logo-section {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.logo-icon {
  font-size: 2rem;
}

.logo-section h1 {
  margin: 0;
  font-size: 1.5rem;
  color: #fff;
  font-weight: 600;
}

.main-nav {
  display: flex;
  gap: 1rem;
}

.main-nav a {
  color: #a0aec0;
  text-decoration: none;
  padding: 0.5rem 1rem;
  border-radius: 8px;
  transition: all 0.2s ease;
  font-weight: 500;
}

.main-nav a:hover {
  color: #fff;
  background: rgba(255, 255, 255, 0.1);
}

.main-nav a.router-link-active {
  color: #fff;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.main-content {
  flex: 1;
  padding: 2rem;
  background: #0f0f1a;
}

@media (max-width: 640px) {
  .app-header {
    flex-direction: column;
    gap: 1rem;
    padding: 1rem;
  }
  
  .main-content {
    padding: 1rem;
  }
}
</style>
