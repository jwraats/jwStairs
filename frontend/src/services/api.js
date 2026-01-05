// API service for JW.Stairs LED Controller
const API_BASE = import.meta.env.VITE_API_BASE || ''

async function handleResponse(response) {
  if (!response.ok) {
    const errorText = await response.text()
    throw new Error(errorText || `HTTP error ${response.status}`)
  }
  const text = await response.text()
  return text ? JSON.parse(text) : null
}

// Scenes API
export async function getScenes() {
  const response = await fetch(`${API_BASE}/scenes`)
  return handleResponse(response)
}

export async function getScene(id) {
  const response = await fetch(`${API_BASE}/scenes/${id}`)
  return handleResponse(response)
}

export async function createScene(name) {
  const response = await fetch(`${API_BASE}/scenes`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name })
  })
  return handleResponse(response)
}

export async function updateScene(id, name) {
  const response = await fetch(`${API_BASE}/scenes/${id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id, name })
  })
  return handleResponse(response)
}

export async function deleteScene(id) {
  const response = await fetch(`${API_BASE}/scenes/${id}`, {
    method: 'DELETE'
  })
  return handleResponse(response)
}

// Frames API
export async function getFrames(sceneId) {
  const response = await fetch(`${API_BASE}/scenes/${sceneId}/frames`)
  return handleResponse(response)
}

export async function getFrame(sceneId, orderNr) {
  const response = await fetch(`${API_BASE}/scenes/${sceneId}/frames/${orderNr}`)
  return handleResponse(response)
}

export async function addFrame(sceneId, frame) {
  const response = await fetch(`${API_BASE}/scenes/${sceneId}/frame`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(frame)
  })
  return handleResponse(response)
}

export async function addFrames(sceneId, frames) {
  const response = await fetch(`${API_BASE}/scenes/${sceneId}/frames`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(frames)
  })
  return handleResponse(response)
}

// Shows API
export async function getShows() {
  const response = await fetch(`${API_BASE}/shows`)
  return handleResponse(response)
}

export async function playAnimation(show, options = {}) {
  const params = new URLSearchParams()
  if (options.color) params.append('color', options.color)
  if (options.blankColor) params.append('blankColor', options.blankColor)
  if (options.percentage !== undefined) params.append('percentage', options.percentage)
  if (options.repeat !== undefined) params.append('repeat', options.repeat)
  if (options.colorOrder) params.append('colorOrder', options.colorOrder)

  const queryString = params.toString()
  const url = `${API_BASE}/animation/${show}${queryString ? '?' + queryString : ''}`
  const response = await fetch(url)
  return handleResponse(response)
}

// Simulator API
export async function getSimulatorStatus() {
  const response = await fetch(`${API_BASE}/simulator/status`)
  return handleResponse(response)
}

export async function getLeds() {
  const response = await fetch(`${API_BASE}/leds`)
  return handleResponse(response)
}

export function subscribeLedUpdates(onUpdate, onError) {
  const eventSource = new EventSource(`${API_BASE}/leds/stream`)
  
  eventSource.onmessage = (event) => {
    try {
      const colors = JSON.parse(event.data)
      onUpdate(colors)
    } catch (e) {
      console.error('Failed to parse LED data:', e)
    }
  }
  
  eventSource.onerror = (error) => {
    if (onError) onError(error)
  }
  
  return eventSource
}
