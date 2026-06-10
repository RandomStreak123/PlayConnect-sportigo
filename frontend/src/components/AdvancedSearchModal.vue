<script setup>
import { ref, watch, onUnmounted } from 'vue'
import { store } from '../store'
import { t } from '../utils/i18n'
import { getPlayerAvatar } from '../utils/sportImageHelper'

const props = defineProps({
  show: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['close', 'apply-filters', 'open-player', 'open-details'])

const sports = ['All', 'Football', 'Basketball', 'Tennis', 'Padel', 'Badminton', 'Cricket']
const skills = ['All', 'Beginner', 'Intermediate', 'Advanced', 'Professional']

const searchQuery = ref('')
const selectedSport = ref('All')
const selectedSkill = ref('All')
const distanceRange = ref(15) // simple range up to 50km

const isSearching = ref(false)
const searchError = ref(null)
const searchResultsPlayers = ref([])
const searchResultsMatches = ref([])

let debounceTimer = null

const performSearch = async (query) => {
  isSearching.value = true
  searchError.value = null
  try {
    const [players, matchesResult] = await Promise.all([
      store.fetchPlayers(query),
      store.fetchMatches({ search: query })
    ])
    searchResultsPlayers.value = players || []
    searchResultsMatches.value = matchesResult?.data || []
  } catch (e) {
    console.error('Unified search failed:', e)
    searchError.value = 'Search failed. Please try again.'
  } finally {
    isSearching.value = false
  }
}

watch(searchQuery, (newVal) => {
  if (debounceTimer) clearTimeout(debounceTimer)
  const query = newVal.trim()
  if (!query) {
    searchResultsPlayers.value = []
    searchResultsMatches.value = []
    isSearching.value = false
    searchError.value = null
    return
  }
  debounceTimer = setTimeout(() => {
    performSearch(query)
  }, 300)
})

onUnmounted(() => {
  if (debounceTimer) clearTimeout(debounceTimer)
})

const handleReset = () => {
  searchQuery.value = ''
  selectedSport.value = 'All'
  selectedSkill.value = 'All'
  distanceRange.value = 15
}

const handleApply = () => {
  emit('apply-filters', {
    search: searchQuery.value.trim(),
    sport: selectedSport.value,
    skill: selectedSkill.value,
    distance: distanceRange.value
  })
  emit('close')
}

const getSportIcon = (category) => {
  const icons = {
    Football: '⚽',
    Basketball: '🏀',
    Tennis: '🎾',
    Padel: '🏓',
    Badminton: '🏸',
    Cricket: '🏏'
  }
  return icons[category] || '🏆'
}

const formatMatchDate = (dateTimeStr) => {
  if (!dateTimeStr) return ''
  const date = new Date(dateTimeStr.replace(' ', 'T'))
  const now = new Date()
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  const tomorrow = new Date(today.getTime() + 24 * 60 * 60 * 1000)
  const matchDay = new Date(date.getFullYear(), date.getMonth(), date.getDate())

  if (matchDay.getTime() === today.getTime()) {
    return 'Today'
  } else if (matchDay.getTime() === tomorrow.getTime()) {
    return 'Tomorrow'
  } else {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    return `${months[date.getMonth()]} ${date.getDate()}`
  }
}

const formatMatchTime = (dateTimeStr) => {
  if (!dateTimeStr) return ''
  const parts = dateTimeStr.split(' ')
  if (parts.length > 1) {
    return parts[1].substring(0, 5) // return HH:MM
  }
  return ''
}
</script>

<template>
  <div v-if="show" class="modal-backdrop" @click="emit('close')">
    <div class="modal-sheet animate-slide-up" @click.stop>
      <!-- Header -->
      <div class="modal-header">
        <button class="back-btn" @click="emit('close')">✕</button>
        <h2 class="modal-title">{{ t('advancedSearch') }}</h2>
        <div style="width: 20px"></div> <!-- alignment helper -->
      </div>

      <!-- Content panel -->
      <div class="modal-body scrollable-y">
        <!-- Search bar input -->
        <div class="search-box">
          <span class="search-icon">🔍</span>
          <input 
            v-model="searchQuery"
            type="text" 
            placeholder="Search matches, players, or clubs..." 
            class="search-input"
            @keyup.enter="handleApply"
          />
          <button v-if="searchQuery" class="clear-search-btn" @click="searchQuery = ''">✕</button>
        </div>

        <!-- Conditional Search Results -->
        <div v-if="searchQuery.trim().length > 0">
          <div v-if="isSearching" class="loader-wrap">
            <span class="loader"></span>
          </div>
          <div v-else-if="searchError" class="error-msg">
            {{ searchError }}
          </div>
          <div v-else-if="searchResultsPlayers.length === 0 && searchResultsMatches.length === 0" class="empty-results">
            <span class="empty-icon">🔍❌</span>
            <h4>No matches or players found</h4>
            <p>Try checking your spelling or searching for something else.</p>
          </div>
          <div v-else>
            <!-- Players Results -->
            <div v-if="searchResultsPlayers.length > 0" class="results-section">
              <h3 class="filter-title">Players</h3>
              <div class="players-row scrollable-x">
                <div 
                  v-for="player in searchResultsPlayers" 
                  :key="player.id"
                  class="player-result-card"
                  @click="emit('open-player', player, player.primary_sport || 'Football'); emit('close');"
                >
                  <img :src="getPlayerAvatar(player.avatar || player.profile_photo || player.profile_picture, player.gender)" class="player-avatar" />
                  <span class="player-name">{{ player.name }}</span>
                  <span class="player-gender">{{ (player.gender || 'male').toUpperCase() }}</span>
                </div>
              </div>
            </div>

            <!-- Matches Results -->
            <div v-if="searchResultsMatches.length > 0" class="results-section" style="margin-top: 24px;">
              <h3 class="filter-title">Matches</h3>
              <div class="matches-vertical-list">
                <div 
                  v-for="match in searchResultsMatches" 
                  :key="match.id"
                  class="match-result-card"
                  @click="emit('open-details', match); emit('close');"
                >
                  <div class="match-left">
                    <span class="sport-icon-badge">{{ getSportIcon(match.sport_type || match.category) }}</span>
                    <div class="match-meta">
                      <span class="match-title">{{ match.title }}</span>
                      <span class="match-sub">{{ match.location }} · 0.0 km</span>
                    </div>
                  </div>
                  <div class="match-right">
                    <span class="match-time">{{ formatMatchTime(match.date_time || match.date) }}</span>
                    <span class="match-day">{{ formatMatchDate(match.date_time || match.date) }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Default Filters (when search query is empty) -->
        <div v-else>
          <h3 class="filter-title">{{ t('filters') }}</h3>

          <!-- Sport pills -->
          <div class="filter-section">
            <label class="section-label">{{ t('sportType') }}</label>
            <div class="pills-grid">
              <button 
                v-for="sport in sports" 
                :key="sport"
                type="button"
                class="pill-chip"
                :class="{ active: selectedSport === sport }"
                @click="selectedSport = sport"
              >
                {{ t('sport_' + sport) }}
              </button>
            </div>
          </div>

          <!-- Skill pills -->
          <div class="filter-section">
            <label class="section-label">{{ t('skillLevel') }}</label>
            <div class="pills-grid">
              <button 
                v-for="skill in skills" 
                :key="skill"
                type="button"
                class="pill-chip"
                :class="{ active: selectedSkill === skill }"
                @click="selectedSkill = skill"
              >
                {{ t('skill_' + skill) }}
              </button>
            </div>
          </div>

          <!-- Distance slider -->
          <div class="filter-section">
            <div class="slider-header">
              <label class="section-label">{{ t('distance') }}</label>
              <span class="slider-val">{{ distanceRange }} km</span>
            </div>
            <input 
              v-model="distanceRange" 
              type="range" 
              min="1" 
              max="50" 
              class="range-slider"
            />
          </div>

          <!-- Recommended list -->
          <div class="recommended-block">
            <h3 class="filter-title">{{ t('recommendedMatches') }}</h3>
            
            <div class="rec-card">
              <div class="rec-icon">🎾</div>
              <div class="rec-info">
                <span class="rec-name">Sunset Doubles Bash</span>
                <span class="rec-venue">Central Park Courts · 2.5 km</span>
              </div>
              <div class="rec-time">
                <span class="time-val">18:30</span>
                <span class="time-day">{{ t('today') }}</span>
              </div>
            </div>

            <div class="rec-card">
              <div class="rec-icon">🏓</div>
              <div class="rec-info">
                <span class="rec-name">Morning Padel Drill</span>
                <span class="rec-venue">Westside Club · 5.1 km</span>
              </div>
              <div class="rec-time">
                <span class="time-val">08:00</span>
                <span class="time-day">{{ t('today') }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Action Footer (only visible when not typing search query) -->
      <div v-if="searchQuery.trim().length === 0" class="modal-footer">
        <button class="footer-btn reset-btn" @click="handleReset">{{ t('reset') }}</button>
        <button class="footer-btn apply-btn" @click="handleApply">{{ t('applyFilters') }}</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.modal-backdrop {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(15, 23, 42, 0.45);
  backdrop-filter: blur(4px);
  z-index: 1000;
  display: flex;
  align-items: flex-end;
}

@media (min-width: 768px) {
  .modal-backdrop {
    align-items: center;
    justify-content: center;
  }
}

.modal-sheet {
  width: 100%;
  height: 85%;
  background-color: var(--scaffold-bg);
  border-top-left-radius: var(--radius-xl);
  border-top-right-radius: var(--radius-xl);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

@media (min-width: 768px) {
  .modal-sheet {
    width: 100%;
    max-width: 520px;
    height: auto;
    max-height: 80vh;
    border-radius: var(--radius-lg);
    box-shadow: var(--shadow-lg);
  }
}

.modal-header {
  padding: 16px 20px;
  border-bottom: 1px solid var(--outline-variant);
  display: flex;
  justify-content: space-between;
  align-items: center;
  background-color: var(--surface);
}

.modal-title {
  font-size: 1.15rem;
  font-weight: 700;
  color: var(--on-surface);
}

.back-btn {
  background: none;
  border: none;
  font-size: 1.1rem;
  color: var(--on-surface);
  cursor: pointer;
}

.modal-body {
  padding: 20px;
  flex: 1;
}

.search-box {
  position: relative;
  display: flex;
  align-items: center;
  margin-bottom: 24px;
}

.search-icon {
  position: absolute;
  left: 14px;
  color: var(--outline);
}

.search-input {
  width: 100%;
  padding: 12px 38px 12px 38px;
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  outline: none;
  font-size: 0.9rem;
  color: var(--on-surface);
}

.search-input:focus { border-color: var(--primary); }

.clear-search-btn {
  position: absolute;
  right: 14px;
  background: none;
  border: none;
  font-size: 0.9rem;
  color: var(--outline);
  cursor: pointer;
}

.filter-title {
  font-size: 0.95rem;
  font-weight: 700;
  margin-bottom: 14px;
  color: var(--on-surface);
}

.filter-section {
  margin-bottom: 24px;
}

.section-label {
  font-size: 0.85rem;
  font-weight: 700;
  color: var(--on-surface-variant);
  margin-bottom: 10px;
  display: block;
}

.pills-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.pill-chip {
  padding: 6px 14px;
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: 16px;
  font-size: 0.8rem;
  font-weight: 600;
  color: var(--on-surface-variant);
  cursor: pointer;
  transition: all 0.2s ease;
}

.pill-chip.active {
  background-color: var(--primary);
  color: var(--on-primary);
  border-color: var(--primary);
}

.slider-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.slider-val {
  font-size: 0.82rem;
  font-weight: 700;
  color: var(--primary);
}

.range-slider {
  width: 100%;
  height: 6px;
  background-color: var(--outline-variant);
  border-radius: 3px;
  outline: none;
  accent-color: var(--primary);
}

.recommended-block {
  margin-top: 12px;
}

.rec-card {
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  padding: 12px;
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 10px;
  cursor: pointer;
}

.rec-icon {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background-color: var(--scaffold-bg);
  display: flex;
  justify-content: center;
  align-items: center;
  font-size: 1.1rem;
}

.rec-info {
  display: flex;
  flex-direction: column;
  flex: 1;
}

.rec-name {
  font-size: 0.85rem;
  font-weight: 700;
  color: var(--on-surface);
}

.rec-venue {
  font-size: 0.72rem;
  color: var(--on-surface-variant);
}

.rec-time {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
}

.time-val {
  font-size: 0.85rem;
  font-weight: 700;
  color: var(--primary);
}

.time-day {
  font-size: 0.68rem;
  color: var(--outline);
}

/* Footer panel */
.modal-footer {
  padding: 16px 20px 24px;
  background-color: var(--surface);
  border-top: 1px solid var(--outline-variant);
  display: flex;
  gap: 16px;
}

.footer-btn {
  padding: 14px;
  border-radius: var(--radius-md);
  font-size: 0.95rem;
  font-weight: 700;
  cursor: pointer;
  border: none;
}

.reset-btn {
  background: none;
  color: var(--primary);
}

.apply-btn {
  flex: 1;
  background-color: var(--primary);
  color: var(--on-primary);
}

/* Search results styles */
.scrollable-x {
  display: flex;
  gap: 12px;
  overflow-x: auto;
  padding: 4px 0 12px;
  scrollbar-width: none;
}

.scrollable-x::-webkit-scrollbar {
  display: none;
}

.player-result-card {
  width: 100px;
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  padding: 12px 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  cursor: pointer;
  flex-shrink: 0;
  box-shadow: var(--shadow-sm);
  transition: transform 0.2s, border-color 0.2s;
}

.player-result-card:hover {
  transform: translateY(-2px);
  border-color: var(--primary);
}

.player-result-card .player-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  object-fit: cover;
  margin-bottom: 8px;
}

.player-result-card .player-name {
  font-size: 0.78rem;
  font-weight: 700;
  color: var(--on-surface);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  width: 100%;
}

.player-result-card .player-gender {
  font-size: 0.6rem;
  font-weight: 700;
  color: var(--primary);
  margin-top: 2px;
}

.matches-vertical-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.match-result-card {
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  padding: 12px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  transition: border-color 0.2s;
}

.match-result-card:hover {
  border-color: var(--primary);
}

.match-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.sport-icon-badge {
  width: 36px;
  height: 36px;
  background-color: var(--surface-dim);
  border-radius: var(--radius-sm);
  display: flex;
  justify-content: center;
  align-items: center;
  font-size: 1.1rem;
}

.match-meta {
  display: flex;
  flex-direction: column;
}

.match-title {
  font-size: 0.85rem;
  font-weight: 700;
  color: var(--on-surface);
}

.match-sub {
  font-size: 0.72rem;
  color: var(--on-surface-variant);
}

.match-right {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
}

.match-time {
  font-size: 0.85rem;
  font-weight: 700;
  color: var(--primary);
}

.match-day {
  font-size: 0.68rem;
  color: var(--outline);
}

.empty-results {
  text-align: center;
  padding: 40px 20px;
  color: var(--on-surface-variant);
}

.empty-icon {
  font-size: 2.5rem;
  margin-bottom: 12px;
  display: block;
}

.empty-results h4 {
  font-size: 0.95rem;
  font-weight: 700;
  margin-bottom: 4px;
}

.empty-results p {
  font-size: 0.8rem;
  color: var(--outline);
}

.loader-wrap {
  width: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 40px 0;
}

.loader {
  width: 28px;
  height: 28px;
  border: 3px solid var(--primary);
  border-bottom-color: transparent;
  border-radius: 50%;
  animation: rotation 1s linear infinite;
}

.error-msg {
  color: var(--error);
  font-size: 0.85rem;
  text-align: center;
  padding: 20px;
}

@keyframes rotation {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style>
