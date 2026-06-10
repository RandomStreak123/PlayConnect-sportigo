<script setup>
import { ref, computed, onMounted } from 'vue'
import { getPlayerAvatar } from '../utils/sportImageHelper'
import { store } from '../store'
import MatchCard from '../components/MatchCard.vue'
import { t } from '../utils/i18n'

const emit = defineEmits(['open-details', 'open-player'])

const isLoadingPlayers = ref(false)

const loadPlayers = async () => {
  isLoadingPlayers.value = true
  try {
    await store.fetchPlayers()
  } catch (e) {
    console.error('Failed to fetch players:', e)
  } finally {
    isLoadingPlayers.value = false
  }
}

onMounted(() => {
  loadPlayers()
})

const upcomingMatches = computed(() => {
  const now = new Date()
  let filtered = store.state.matches.filter(match => {
    const matchTime = new Date(match.dateTime.replace(' ', 'T'))
    return matchTime >= now
  })
  
  // Sort chronologically (closest first)
  return filtered.sort((a, b) => {
    return new Date(a.dateTime.replace(' ', 'T')) - new Date(b.dateTime.replace(' ', 'T'))
  })
})

const handleWheelScroll = (e) => {
  if (e.deltaY !== 0) {
    e.preventDefault()
    e.currentTarget.scrollLeft += e.deltaY * 1.2
  }
}

let isDragging = false
let startX = 0
let scrollLeft = 0
let dragMoved = false

const handleDragStart = (e) => {
  isDragging = true
  dragMoved = false
  const container = e.currentTarget
  container.classList.add('grabbing')
  startX = e.pageX - container.offsetLeft
  scrollLeft = container.scrollLeft
}

const handleDragMove = (e) => {
  if (!isDragging) return
  e.preventDefault()
  const container = e.currentTarget
  const x = e.pageX - container.offsetLeft
  const walk = (x - startX) * 1.5
  if (Math.abs(x - startX) > 5) {
    dragMoved = true
  }
  container.scrollLeft = scrollLeft - walk
}

const handleDragEnd = (e) => {
  if (!isDragging) return
  isDragging = false
  const container = e.currentTarget
  container.classList.remove('grabbing')
  
  if (dragMoved) {
    const preventClick = (clickEvent) => {
      clickEvent.stopImmediatePropagation()
      clickEvent.preventDefault()
      container.removeEventListener('click', preventClick, true)
    }
    container.addEventListener('click', preventClick, true)
  }
}
</script>

<template>
  <div class="explore-container scrollable-y animate-fade-in">
    <!-- Header -->
    <div class="explore-header">
      <h2 class="title">{{ t('explore') }}</h2>
      <button class="refresh-btn" :disabled="isLoadingPlayers" @click="loadPlayers">
        <svg v-if="isLoadingPlayers" class="spinner-svg" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
        <svg v-else class="refresh-svg" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"/><path d="M3 21v-5h5"/></svg>
      </button>
    </div>

    <!-- Nearby Players -->
    <div class="section-row">
      <h3 class="section-title">{{ t('nearbyPlayers') }}</h3>
      <button class="refresh-txt-btn" @click="loadPlayers">{{ t('refreshList') }}</button>
    </div>

    <div 
      class="players-slider" 
      @wheel.prevent="handleWheelScroll"
      @mousedown="handleDragStart"
      @mousemove="handleDragMove"
      @mouseup="handleDragEnd"
      @mouseleave="handleDragEnd"
    >
      <div v-if="isLoadingPlayers" class="loader-wrap">
        <span class="loader"></span>
      </div>
      <div v-else-if="store.state.players.length === 0" class="empty-state">
        {{ t('noPlayersRegistered') }}
      </div>
      <div 
        v-else
        v-for="player in store.state.players"
        :key="player.id"
        class="player-card"
        @click="emit('open-player', player, player.primary_sport || 'Football')"
      >
        <img :src="getPlayerAvatar(player.avatar || player.profile_photo || player.profile_picture, player.gender)" class="player-avatar" />
        <span class="player-name">{{ player.name }}</span>
        <span class="player-sport">{{ (player.primary_sport || 'Football').toUpperCase() }}</span>
        <span class="player-distance">Proximity Enabled</span>
      </div>
    </div>

    <!-- Trending matches -->
    <div class="section-row trending-header">
      <h3 class="section-title">{{ t('trendingMatches') }}</h3>
    </div>

    <div class="matches-list">
      <div v-if="upcomingMatches.length === 0" class="empty-matches">
        {{ t('noMatchesFound') }}
      </div>
      <MatchCard 
        v-for="match in upcomingMatches" 
        :key="match.id"
        :match="match"
        @open-details="emit('open-details', match)"
        @open-player="(p, s) => emit('open-player', p, s)"
      />
    </div>
  </div>
</template>

<style scoped>
.explore-container {
  padding: 56px 20px 80px;
  background-color: var(--scaffold-bg);
}

.explore-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.title {
  font-family: var(--font-display);
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--on-surface);
}

.refresh-btn {
  background: none;
  border: none;
  cursor: pointer;
  color: var(--on-surface);
  display: flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  transition: background-color 0.2s;
}

.refresh-btn:hover {
  background-color: var(--surface-dim);
}

.refresh-svg, .spinner-svg {
  stroke: var(--on-surface);
  transition: transform 0.3s ease;
}

.refresh-btn:hover .refresh-svg {
  transform: rotate(45deg);
}

.spinner-svg {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.section-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.section-title {
  font-family: var(--font-display);
  font-size: 1.25rem;
  font-weight: 800;
  color: var(--on-surface);
  letter-spacing: -0.2px;
}

.refresh-txt-btn {
  background: none;
  border: none;
  font-size: 0.85rem;
  font-weight: 700;
  color: var(--primary);
  cursor: pointer;
}

.players-slider {
  display: flex;
  gap: 12px;
  overflow-x: auto;
  padding: 4px 20px 16px;
  margin: 0 -20px 28px;
  scroll-snap-type: x mandatory;
  -webkit-overflow-scrolling: touch;
  scrollbar-width: thin;
  scrollbar-color: var(--outline-variant) transparent;
  min-height: 140px;
  cursor: grab;
  user-select: none;
}

.players-slider.grabbing {
  cursor: grabbing;
  scroll-snap-type: none !important;
  scroll-behavior: auto !important;
}

.players-slider::-webkit-scrollbar {
  height: 6px;
  display: block;
}

.players-slider::-webkit-scrollbar-track {
  background: transparent;
}

.players-slider::-webkit-scrollbar-thumb {
  background: var(--outline-variant);
  border-radius: 10px;
}

.players-slider::-webkit-scrollbar-thumb:hover {
  background: var(--outline);
}

.loader-wrap {
  width: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
}

.loader {
  width: 24px;
  height: 24px;
  border: 2.5px solid var(--primary);
  border-bottom-color: transparent;
  border-radius: 50%;
  animation: rotation 1s linear infinite;
}

.player-card {
  width: 110px;
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  padding: 14px 10px;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  cursor: pointer;
  flex-shrink: 0;
  box-shadow: var(--shadow-sm);
  transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
  scroll-snap-align: start;
}

.player-card:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-md);
  border-color: var(--primary);
}

.player-avatar {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  object-fit: cover;
  margin-bottom: 10px;
}

.player-name {
  font-size: 0.8rem;
  font-weight: 700;
  color: var(--on-surface);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  width: 100%;
  margin-bottom: 2px;
}

.player-sport {
  font-size: 0.62rem;
  font-weight: 700;
  color: var(--primary);
  letter-spacing: 0.5px;
  margin-bottom: 2px;
}

.player-distance {
  font-size: 0.65rem;
  color: var(--on-surface-variant);
}

.trending-header {
  margin-top: 12px;
}

.matches-list {
  display: grid;
  grid-template-columns: 1fr;
  gap: 20px;
}

@media (min-width: 640px) {
  .matches-list {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (min-width: 1024px) {
  .matches-list {
    grid-template-columns: repeat(3, 1fr);
  }
}

.empty-matches, .empty-state {
  text-align: center;
  padding: 24px;
  font-size: 0.85rem;
  color: var(--on-surface-variant);
  width: 100%;
}

@keyframes rotation {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style>
