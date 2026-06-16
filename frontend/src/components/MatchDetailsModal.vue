<script setup>
import { ref, computed, watch, nextTick } from 'vue'
import { getSportImage, getPlayerAvatar } from '../utils/sportImageHelper'
import { store } from '../store'
import { t } from '../utils/i18n'

const props = defineProps({
  match: {
    type: Object,
    required: true
  },
  show: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['close', 'open-player', 'action-success'])

const match = computed(() => {
  return store.state.matches.find(m => m.id === props.match.id) || props.match
})

const isSubmitting = ref(false)
const showResultsPanel = ref(false)
const showRatingPanel = ref(false)
const isSavingResults = ref(false)
const isSavingRatings = ref(false)
const pendingResults = ref({})
const pendingRatings = ref({}) // { userId: starCount }
const existingRatings = ref(null) // ratings already submitted by this user
const hasRatedAlready = ref(false)

const slotsLeft = computed(() => {
  const maxSlots = match.value.maxSlots ?? match.value.max_slots ?? 0
  const joinedCount = match.value.joinedCount ?? match.value.joined_count ?? match.value.participants?.length ?? 0
  return Math.max(0, maxSlots - joinedCount)
})

const isJoined = computed(() => {
  if (!store.state.currentUser) return false
  const participants = match.value.participants || []
  return participants.some(p => p.id === store.state.currentUser.id)
})

const isCreator = computed(() => {
  if (!store.state.currentUser) return false
  const matchCreatorId = match.value.creatorId ?? match.value.creator_id ?? match.value.user_id
  return Number(matchCreatorId) === Number(store.state.currentUser.id)
})

const isRestricted = computed(() => {
  const womenOnly = match.value.womenOnly ?? match.value.women_only ?? match.value.is_women_only
  if (!womenOnly) return false
  return store.state.currentUser?.gender !== 'female'
})

const isPastMatch = computed(() => {
  try {
    const dateStr = match.value.dateTime || match.value.date_time || match.value.date
    if (!dateStr) return false
    const dt = new Date(dateStr.replace(' ', 'T'))
    return dt < new Date()
  } catch { return false }
})

const hasRecordedResults = computed(() => {
  const participants = match.value.participants || []
  return participants.some(p => p.pivot?.result)
})

const imageSrc = computed(() => {
  const sportType = match.value.sportType || match.value.sport_type || match.value.category || 'Football'
  const raw = getSportImage(sportType, match.value.id)
  if (!raw) return ''
  return raw.split('/').map(s => encodeURIComponent(s)).join('/')
})

// Chat history and scroll-to-bottom handlers removed as chat is disabled

const handleJoin = async () => {
  if (isRestricted.value) return
  isSubmitting.value = true
  try {
    await Promise.all([
      store.joinMatch(match.value.id),
      new Promise(resolve => setTimeout(resolve, 500))
    ])
    emit('action-success', 'Successfully joined match! 🥳')
  } catch (err) {
    console.error('Failed to join match:', err)
  } finally {
    await nextTick()
    isSubmitting.value = false
  }
}

const handleLeave = async () => {
  isSubmitting.value = true
  try {
    await Promise.all([
      store.leaveMatch(match.value.id),
      new Promise(resolve => setTimeout(resolve, 500))
    ])
    emit('action-success', 'Left the match.')
  } catch (err) {
    console.error('Failed to leave match:', err)
  } finally {
    await nextTick()
    isSubmitting.value = false
  }
}

const openResultsPanel = () => {
  const existing = {}
  const participants = match.value.participants || []
  participants.forEach(p => {
    existing[p.id] = p.pivot?.result || null
  })
  pendingResults.value = existing
  showResultsPanel.value = true
}

const setResult = (userId, result) => {
  pendingResults.value[userId] = pendingResults.value[userId] === result ? null : result
}

const saveResults = async () => {
  const results = Object.entries(pendingResults.value)
    .filter(([, r]) => r !== null)
    .map(([userId, result]) => ({ user_id: Number(userId), result }))

  if (results.length === 0) {
    emit('action-success', 'Please select at least one result.')
    return
  }

  isSavingResults.value = true
  try {
    const data = await store.recordResults(match.value.id, results)
    if (data) {
      emit('action-success', 'Match results saved! 🏆')
      showResultsPanel.value = false
    } else {
      emit('action-success', 'Failed to save results. ❌')
    }
  } catch (err) {
    emit('action-success', 'Error saving results. ❌')
  } finally {
    isSavingResults.value = false
  }
}

// sendChat removed

const handleShare = async () => {
  const shareUrl = `${window.location.origin}/?match=${match.value.id}`
  
  if (navigator.share) {
    try {
      await navigator.share({
        title: match.value.title,
        text: `Join this match: "${match.value.title}" on PlayConnect! ⚡`,
        url: shareUrl
      })
      return
    } catch (err) {
      if (err.name === 'AbortError') {
        return // User dismissed share dialog
      }
      console.warn('Native share failed, falling back to clipboard copy:', err)
    }
  }

  if (navigator.clipboard) {
    navigator.clipboard.writeText(shareUrl)
      .then(() => {
        emit('action-success', 'Share link copied to clipboard! 📋')
      })
      .catch(() => {
        emit('action-success', `Failed to copy link ❌`)
      })
  } else {
    // Fallback for browsers/environments without clipboard API
    const textArea = document.createElement("textarea")
    textArea.value = shareUrl
    document.body.appendChild(textArea)
    textArea.select()
    try {
      document.execCommand('copy')
      emit('action-success', 'Share link copied to clipboard! 📋')
    } catch (err) {
      emit('action-success', `Failed to copy link ❌`)
    }
    document.body.removeChild(textArea)
  }
}

// Player Rating Logic
const otherParticipants = computed(() => {
  if (!store.state.currentUser) return []
  const participants = match.value.participants || []
  return participants.filter(p => Number(p.id) !== Number(store.state.currentUser.id))
})

const openRatingPanel = async () => {
  // Initialize all ratings to 0 (not rated yet)
  const ratings = {}
  otherParticipants.value.forEach(p => {
    ratings[String(p.id)] = 0
  })
  pendingRatings.value = ratings
  hasRatedAlready.value = false

  // Load existing ratings by this user for this match
  try {
    const data = await store.getMatchRatings(match.value.id)
    if (data && Array.isArray(data)) {
      const myId = store.state.currentUser.id
      const myRatings = data.filter(r => Number(r.rater_id) === Number(myId))
      if (myRatings.length > 0) {
        hasRatedAlready.value = true
        myRatings.forEach(r => {
          const ratedId = String(r.rated_id)
          if (ratings[ratedId] !== undefined) {
            ratings[ratedId] = r.rating
          }
        })
        pendingRatings.value = { ...ratings }
      }
    }
  } catch (e) {
    // ignore - first time rating
  }

  showRatingPanel.value = true
}

const setPlayerRating = (userId, stars) => {
  pendingRatings.value[userId] = pendingRatings.value[userId] === stars ? 0 : stars
}

const saveRatings = async () => {
  const ratings = Object.entries(pendingRatings.value)
    .filter(([, r]) => r > 0)
    .map(([userId, rating]) => ({ user_id: Number(userId), rating }))

  if (ratings.length === 0) {
    emit('action-success', 'Please rate at least one player ⭐')
    return
  }

  isSavingRatings.value = true
  try {
    const data = await store.submitPlayerRatings(match.value.id, ratings)
    if (data) {
      const xpEarned = ratings.length * 10
      emit('action-success', `Ratings saved! You earned +${xpEarned} XP ⭐`)
      showRatingPanel.value = false
      hasRatedAlready.value = true
    } else {
      emit('action-success', 'Failed to save ratings ❌')
    }
  } catch (err) {
    emit('action-success', 'Error saving ratings ❌')
  } finally {
    isSavingRatings.value = false
  }
}
// Check if user has already rated this match
const checkUserRatingStatus = async () => {
  if (!store.state.currentUser || !match.value?.id) return
  try {
    const data = await store.getMatchRatings(match.value.id)
    if (data && Array.isArray(data)) {
      const myId = store.state.currentUser.id
      const hasRated = data.some(r => Number(r.rater_id) === Number(myId))
      hasRatedAlready.value = hasRated
    }
  } catch (e) {
    hasRatedAlready.value = false
  }
}

watch(() => props.show, (newVal) => {
  if (newVal) {
    checkUserRatingStatus()
  }
}, { immediate: true })

watch(() => match.value, () => {
  if (props.show) {
    checkUserRatingStatus()
  }
})
</script>

<template>
  <div v-if="show" class="modal-backdrop" @click="emit('close')">
    <div class="modal-sheet animate-slide-up" @click.stop>
      <!-- Cover Banner -->
      <div 
        class="cover-banner" 
        :class="[match.sportType.toLowerCase().trim(), { 'women-only': match.womenOnly }]"
        :style="{ backgroundImage: `url('${imageSrc}')` }"
      >
        <div class="banner-overlay"></div>
        <button class="back-circle-btn" @click="emit('close')">
          <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="15 18 9 12 15 6"/></svg>
        </button>
        <button class="share-circle-btn" @click="handleShare">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>
        </button>
      </div>

      <!-- Scrollable Details -->
      <div class="details-content scrollable-y">
        <div class="header-section">
          <!-- Badges -->
          <div class="badge-row">
            <span class="badge sport-badge">{{ t('sport_' + match.sportType).toUpperCase() }}</span>
            <span class="badge skill-badge">{{ t('skill_' + match.skillLevel) }}</span>
            <span v-if="match.womenOnly" class="badge women-badge">🌸 {{ t('womenOnly') }}</span>
          </div>

          <!-- Women-Only Shield Notice -->
          <div v-if="match.womenOnly" class="safety-card">
            <span class="safety-icon">
              <svg class="safety-svg" xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </span>
            <p class="safety-text">
              {{ t('womenSafetyNotice') }}
            </p>
          </div>

          <h2 class="match-title">{{ match.title }}</h2>
        </div>

        <!-- Info lines -->
        <div class="info-list">
          <div class="info-tile">
            <span class="tile-icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="tile-svg"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
            </span>
            <div class="tile-info">
              <span class="tile-title">{{ match.dateTime }}</span>
              <span class="tile-desc">{{ t('skill_' + match.skillLevel) }} {{ t('skillLevel') }}</span>
            </div>
          </div>
          <a 
            :href="`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(match.location)}`" 
            target="_blank" 
            rel="noopener noreferrer" 
            class="info-tile location-tile-link"
          >
            <span class="tile-icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="tile-svg"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
            </span>
            <div class="tile-info">
              <span class="tile-title location-title-text">
                {{ match.location }}
                <svg class="external-link-icon" xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg>
              </span>
              <span class="tile-desc">{{ slotsLeft }} {{ t('slotsOpenSuffix') }} • {{ t('clickToViewMap') }}</span>
            </div>
          </a>
        </div>

        <!-- Description -->
        <div class="section-block">
          <h3 class="section-title">{{ t('aboutMatch') }}</h3>
          <p class="section-text">
            {{ t('matchDescText') }} {{ t('sport_' + match.sportType) }} {{ t('sessionAt') }} {{ match.location }}.
            {{ t('skillLevel') }}: {{ t('skill_' + match.skillLevel) }}. {{ t('arriveEarly') }}
          </p>
        </div>

        <!-- Players List -->
        <div class="section-block">
          <h3 class="section-title">{{ t('players') }} ({{ match.joinedCount }}/{{ match.maxSlots }})</h3>
          <div class="players-list">
            <div 
              v-for="p in match.participants" 
              :key="p.id" 
              class="player-tile"
              @click="emit('open-player', p, match.sportType)"
            >
              <img :src="getPlayerAvatar(p.profilePicture, 'male')" class="player-avatar" />
              <div class="player-info">
                <span class="player-name">
                  {{ p.name }}
                  <span v-if="p.id === match.creatorId" class="org-tag">{{ t('organizer') }}</span>
                </span>
                <span class="player-level">{{ t('skill_' + match.skillLevel) }}</span>
              </div>
              <span v-if="p.pivot?.result" class="result-badge" :class="'result-' + p.pivot.result">
                {{ p.pivot.result === 'win' ? '✅ Win' : p.pivot.result === 'loss' ? '❌ Loss' : '➖ Draw' }}
              </span>
            </div>
            
            <div v-if="slotsLeft > 0 && !isCreator" class="waiting-spot">
              <span class="waiting-icon">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="waiting-svg"><path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
              </span>
              <span class="waiting-text">{{ t('waitingSpotText') }}</span>
            </div>
          </div>
        </div>

        <!-- Record Results Panel (for match creator, past matches) -->
        <div v-if="showResultsPanel" class="section-block results-panel animate-fade-in">
          <h3 class="section-title">🏆 Record Match Results</h3>
          <p class="results-hint">Tap Win, Loss, or Draw for each player. Tap again to deselect.</p>
          <div class="results-player-list">
            <div v-for="p in match.participants" :key="'res-' + p.id" class="results-player-row">
              <div class="results-player-info">
                <img :src="getPlayerAvatar(p.profilePicture, 'male')" class="results-player-avatar" />
                <span class="results-player-name">{{ p.name }}</span>
              </div>
              <div class="results-btn-group">
                <button 
                  class="result-select-btn win" 
                  :class="{ selected: pendingResults[p.id] === 'win' }"
                  @click="setResult(p.id, 'win')"
                >Win</button>
                <button 
                  class="result-select-btn loss" 
                  :class="{ selected: pendingResults[p.id] === 'loss' }"
                  @click="setResult(p.id, 'loss')"
                >Loss</button>
                <button 
                  class="result-select-btn draw" 
                  :class="{ selected: pendingResults[p.id] === 'draw' }"
                  @click="setResult(p.id, 'draw')"
                >Draw</button>
              </div>
            </div>
          </div>
          <div class="results-actions">
            <button class="results-cancel-btn" @click="showResultsPanel = false">Cancel</button>
            <button class="results-save-btn" :disabled="isSavingResults" @click="saveResults">
              <span v-if="isSavingResults" class="loader small-loader"></span>
              <span v-else>Save Results</span>
            </button>
          </div>
        </div>

        <!-- Player Rating Panel -->
        <div v-if="showRatingPanel" class="section-block results-panel animate-fade-in">
          <h3 class="section-title">⭐ Rate Players</h3>
          <p class="results-hint">
            {{ hasRatedAlready ? 'Update your ratings for each player. Tap stars to rate.' : 'Rate each player from 1 to 5 stars. You earn +10 XP per player rated!' }}
          </p>
          <div class="results-player-list">
            <div v-for="p in otherParticipants" :key="'rate-' + p.id" class="results-player-row">
              <div class="results-player-info">
                <img :src="getPlayerAvatar(p.profilePicture, 'male')" class="results-player-avatar" />
                <span class="results-player-name">{{ p.name }}</span>
              </div>
              <div class="star-rating-group">
                <button 
                  v-for="star in 5" 
                  :key="star"
                  class="star-btn"
                  :class="{ filled: pendingRatings[p.id] >= star }"
                  @click="setPlayerRating(p.id, star)"
                >
                  ★
                </button>
              </div>
            </div>
          </div>
          <div class="results-actions">
            <button class="results-cancel-btn" @click="showRatingPanel = false">Cancel</button>
            <button class="results-save-btn rating-save" :disabled="isSavingRatings" @click="saveRatings">
              <span v-if="isSavingRatings" class="loader small-loader"></span>
              <span v-else>{{ hasRatedAlready ? 'Update Ratings' : 'Submit Ratings' }}</span>
            </button>
          </div>
        </div>

        <!-- Match Chat section removed -->
      </div>

      <!-- Action Footer -->
      <div class="details-footer">
        <div v-if="isSubmitting" class="loader-wrap">
          <span class="loader"></span>
        </div>
        <div v-else>
          <!-- Past match controls -->
          <div v-if="isPastMatch && !showResultsPanel && !showRatingPanel" class="action-btn-group">
            <button v-if="isCreator" :disabled="hasRecordedResults" class="action-btn record-results-btn" @click="openResultsPanel">
              🏆 {{ hasRecordedResults ? 'Results Recorded' : 'Record Results' }}
            </button>
            <button v-if="otherParticipants.length > 0" :disabled="hasRatedAlready" class="action-btn rate-players-btn" @click="openRatingPanel">
              ⭐ {{ hasRatedAlready ? 'Ratings Submitted' : 'Rate Players' }}
            </button>
            <div v-else-if="!isCreator" class="status-indicator-box">
              ✅ Match Completed
            </div>
          </div>

          <template v-else-if="!isPastMatch">
            <!-- Joined but not creator: Leave button -->
            <button 
              v-if="isJoined && !isCreator" 
              class="action-btn leave-btn"
              @click="handleLeave"
            >
              {{ t('leaveMatch') }}
            </button>
            
            <!-- Creator indicator (future match) -->
            <div v-else-if="isCreator" class="status-indicator-box">
              {{ t('createdMatchStatus') }}
            </div>

            <!-- Joined normal user indicator -->
            <div v-else-if="isJoined" class="status-indicator-box">
              {{ t('joinedMatchStatus') }}
            </div>

            <!-- Restricted to gender -->
            <div v-else-if="isRestricted" class="restricted-box">
              {{ t('womenOnlyMatchRestricted') }}
            </div>

            <!-- Full match -->
            <div v-else-if="slotsLeft === 0" class="full-box">
              {{ t('matchFullStatus') }}
            </div>

            <!-- Available: Join button -->
            <button 
              v-else 
              class="action-btn join-btn"
              @click="handleJoin"
            >
              {{ t('joinMatchSpots') }} ({{ slotsLeft }} {{ t('spotsLeftSuffix') }})
            </button>
          </template>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.modal-backdrop {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background-color: var(--scaffold-bg);
  z-index: 1000;
  display: flex;
  flex-direction: column;
}

@media (min-width: 768px) {
  .modal-backdrop {
    left: 280px;
    width: calc(100vw - 280px);
    background-color: var(--scaffold-bg);
    backdrop-filter: none;
    align-items: stretch;
    justify-content: flex-start;
  }
}

.modal-sheet {
  width: 100%;
  height: 100%;
  background-color: var(--scaffold-bg);
  border-radius: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  box-shadow: none;
  border: none;
}

@media (min-width: 768px) {
  .modal-sheet {
    width: 100%;
    max-width: none;
    height: 100%;
    border-radius: 0;
    box-shadow: none;
    border: none;
  }
}

.cover-banner {
  width: 100%;
  height: 200px;
  background-size: cover;
  background-position: center;
  position: relative;
}

@media (min-width: 768px) {
  .cover-banner {
    height: 320px;
  }
}

/* Fallback colors for sport categories if image not loading */
.cover-banner.football { background-color: #115e59; }
.cover-banner.cricket { background-color: #9a3412; }
.cover-banner.badminton { background-color: #6b21a8; }
.cover-banner.basketball { background-color: #c2410c; }
.cover-banner.tennis { background-color: #0f766e; }
.cover-banner.padel { background-color: #0369a1; }

.banner-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(180deg, rgba(15, 23, 42, 0.35) 0%, rgba(15, 23, 42, 0) 50%, var(--scaffold-bg) 100%);
}

.cover-banner.football .banner-overlay {
  background: linear-gradient(180deg, rgba(17, 94, 89, 0.3) 0%, rgba(17, 94, 89, 0) 50%, var(--scaffold-bg) 100%);
}
.cover-banner.cricket .banner-overlay {
  background: linear-gradient(180deg, rgba(154, 52, 18, 0.3) 0%, rgba(154, 52, 18, 0) 50%, var(--scaffold-bg) 100%);
}
.cover-banner.badminton .banner-overlay {
  background: linear-gradient(180deg, rgba(107, 33, 168, 0.3) 0%, rgba(107, 33, 168, 0) 50%, var(--scaffold-bg) 100%);
}
.cover-banner.basketball .banner-overlay {
  background: linear-gradient(180deg, rgba(194, 65, 12, 0.3) 0%, rgba(194, 65, 12, 0) 50%, var(--scaffold-bg) 100%);
}
.cover-banner.tennis .banner-overlay {
  background: linear-gradient(180deg, rgba(15, 118, 110, 0.3) 0%, rgba(15, 118, 110, 0) 50%, var(--scaffold-bg) 100%);
}
.cover-banner.padel .banner-overlay {
  background: linear-gradient(180deg, rgba(3, 105, 161, 0.3) 0%, rgba(3, 105, 161, 0) 50%, var(--scaffold-bg) 100%);
}
.cover-banner.women-only .banner-overlay {
  background: linear-gradient(180deg, rgba(255, 77, 141, 0.35) 0%, rgba(255, 77, 141, 0) 50%, var(--scaffold-bg) 100%) !important;
}

.back-circle-btn, .share-circle-btn {
  position: absolute;
  top: 16px;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background-color: rgba(255, 255, 255, 0.7);
  backdrop-filter: blur(8px);
  border: 1px solid rgba(255, 255, 255, 0.5);
  cursor: pointer;
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 10;
  color: var(--on-surface);
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
  transition: all 0.2s ease;
}

.back-circle-btn:hover, .share-circle-btn:hover {
  background-color: #ffffff;
  transform: scale(1.05);
  color: var(--primary);
}

.back-circle-btn { left: 16px; }
.share-circle-btn { right: 16px; }

@media (min-width: 768px) {
  .back-circle-btn { left: max(24px, calc(50% - 476px)); }
  .share-circle-btn { right: max(24px, calc(50% - 476px)); }
}

.details-content {
  flex: 1;
  padding: 16px 20px;
  width: 100%;
  box-sizing: border-box;
}

@media (min-width: 768px) {
  .details-content {
    max-width: 1000px;
    margin: 0 auto;
    padding: 28px 24px;
  }
}

.header-section {
  margin-bottom: 24px;
}

.badge-row {
  display: flex;
  gap: 8px;
  margin-bottom: 12px;
}

.badge {
  padding: 4px 10px;
  border-radius: 20px;
  font-size: 0.65rem;
  font-weight: 700;
}

.sport-badge {
  background-color: rgba(26, 35, 126, 0.08);
  color: var(--primary);
}

.skill-badge {
  background-color: var(--surface-dim);
  color: var(--on-surface-variant);
}

.women-badge {
  background: linear-gradient(135deg, #FF4D8D 0%, #7B61FF 100%);
  color: #ffffff;
}

.safety-card {
  background: linear-gradient(135deg, rgba(255, 77, 141, 0.08) 0%, rgba(123, 97, 255, 0.04) 100%);
  border: 1px solid rgba(255, 77, 141, 0.2);
  border-radius: var(--radius-md);
  padding: 12px 16px;
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;
}

.safety-svg {
  stroke: #FF4D8D;
  fill: rgba(255, 77, 141, 0.05);
  display: flex;
  align-items: center;
}

.safety-text {
  font-size: 0.75rem;
  font-weight: 600;
  color: #FF4D8D;
  line-height: 1.35;
}

.match-title {
  font-size: 1.4rem;
  font-weight: 800;
  color: var(--on-surface);
}

.info-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-bottom: 28px;
}

.info-tile {
  display: flex;
  gap: 14px;
  align-items: center;
}

.tile-icon {
  background-color: var(--surface);
  width: 44px;
  height: 44px;
  border-radius: var(--radius-md);
  display: flex;
  justify-content: center;
  align-items: center;
  box-shadow: var(--shadow-sm);
  border: 1px solid var(--outline-variant);
  color: var(--primary);
}

.tile-svg {
  stroke: var(--primary);
}

.tile-info {
  display: flex;
  flex-direction: column;
}

.tile-title {
  font-size: 0.92rem;
  font-weight: 700;
  color: var(--on-surface);
}

.tile-desc {
  font-size: 0.78rem;
  color: var(--on-surface-variant);
}

.section-block {
  margin-bottom: 28px;
}

.section-title {
  font-size: 1rem;
  font-weight: 700;
  margin-bottom: 12px;
}

.section-text {
  font-size: 0.85rem;
  color: var(--on-surface-variant);
  line-height: 1.5;
}

.players-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.player-tile {
  background-color: var(--surface);
  border-radius: var(--radius-md);
  padding: 12px;
  display: flex;
  align-items: center;
  gap: 12px;
  cursor: pointer;
  box-shadow: var(--shadow-sm);
  border: 1px solid var(--outline-variant);
  transition: all 0.2s ease;
}

.player-tile:hover {
  transform: translateY(-2px);
  border-color: var(--primary);
  box-shadow: var(--shadow-md);
}

.player-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  object-fit: cover;
}

.player-info {
  display: flex;
  flex-direction: column;
  flex: 1;
}

.player-name {
  font-size: 0.9rem;
  font-weight: 700;
  color: var(--on-surface);
  display: flex;
  align-items: center;
  gap: 6px;
}

.org-tag {
  background-color: rgba(255, 145, 0, 0.15);
  color: var(--warm-orange);
  font-size: 0.65rem;
  font-weight: 700;
  padding: 2px 6px;
  border-radius: 4px;
}

.player-level {
  font-size: 0.75rem;
  color: var(--on-surface-variant);
}

.waiting-spot {
  background-color: rgba(26, 35, 126, 0.02);
  border: 1px dashed var(--outline);
  border-radius: var(--radius-md);
  padding: 14px;
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 8px;
  transition: all 0.2s ease;
}

.waiting-spot:hover {
  background-color: rgba(26, 35, 126, 0.04);
  border-color: var(--primary);
}

.waiting-icon {
  display: flex;
  align-items: center;
  color: var(--primary);
}

.waiting-svg {
  stroke: var(--primary);
}

.waiting-text {
  font-size: 0.8rem;
  font-weight: 700;
  color: var(--primary);
}

/* Chat system */
.chat-section {
  display: flex;
  flex-direction: column;
  background-color: var(--surface);
  border-radius: var(--radius-md);
  padding: 16px;
  border: 1px solid var(--outline-variant);
}

.chat-container {
  height: 180px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 10px 4px;
  border-bottom: 1px solid var(--outline-variant);
}

.chat-empty {
  text-align: center;
  font-size: 0.8rem;
  color: var(--on-surface-variant);
  margin-top: 40px;
}

.chat-bubble {
  align-self: flex-start;
  background-color: var(--scaffold-bg);
  border-radius: 16px 16px 16px 4px;
  padding: 10px 14px;
  max-width: 80%;
  display: flex;
  flex-direction: column;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
  border: 1px solid var(--outline-variant);
}

.chat-bubble.mine {
  align-self: flex-end;
  background: linear-gradient(135deg, var(--primary) 0%, var(--primary-container) 100%);
  color: var(--on-primary-container);
  border-radius: 16px 16px 4px 16px;
  border: none;
  box-shadow: 0 4px 12px rgba(26, 35, 126, 0.15);
}

.chat-sender {
  font-size: 0.72rem;
  font-weight: 700;
  margin-bottom: 3px;
  opacity: 0.8;
}

.chat-bubble.mine .chat-sender {
  color: rgba(255, 255, 255, 0.9);
  text-align: right;
}

.chat-text {
  font-size: 0.85rem;
  line-height: 1.4;
}

.chat-time {
  font-size: 0.6rem;
  text-align: right;
  opacity: 0.65;
  margin-top: 3px;
}

.chat-input-bar {
  display: flex;
  gap: 8px;
  padding-top: 12px;
}

.chat-input {
  flex: 1;
  border: 1px solid var(--outline-variant);
  border-radius: 24px;
  padding: 10px 18px;
  font-size: 0.88rem;
  outline: none;
  background-color: var(--scaffold-bg);
  color: var(--on-surface);
  transition: all 0.2s ease;
}

.chat-input:focus {
  border-color: var(--primary);
  background-color: var(--surface);
  box-shadow: 0 0 0 3px rgba(26, 35, 126, 0.08);
}

.chat-send-btn {
  width: 38px;
  height: 38px;
  border-radius: 50%;
  border: none;
  background: linear-gradient(135deg, var(--primary) 0%, var(--primary-container) 100%);
  color: #ffffff;
  cursor: pointer;
  display: flex;
  justify-content: center;
  align-items: center;
  box-shadow: 0 4px 10px rgba(26, 35, 126, 0.2);
  transition: all 0.2s ease;
}

.chat-send-btn:hover {
  transform: scale(1.05);
  filter: brightness(1.1);
}

/* Footer panel */
.details-footer {
  padding: 16px 20px 24px;
  background-color: var(--surface);
  border-top: 1px solid var(--outline-variant);
  width: 100%;
  box-sizing: border-box;
}

@media (min-width: 768px) {
  .details-footer {
    padding: 20px 24px 32px;
  }
  .details-footer > div {
    width: 100%;
    max-width: 952px;
    margin: 0 auto;
  }
}

.loader-wrap {
  display: flex;
  justify-content: center;
  padding: 10px 0;
}

.loader {
  width: 24px;
  height: 24px;
  border: 2.5px solid var(--primary);
  border-bottom-color: transparent;
  border-radius: 50%;
  animation: rotation 1s linear infinite;
}

.action-btn {
  width: 100%;
  padding: 14px;
  border-radius: var(--radius-md);
  font-size: 0.95rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s ease;
  border: none;
}

.action-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  filter: grayscale(0.5) brightness(0.9) !important;
  transform: none !important;
  box-shadow: none !important;
}

.join-btn {
  background: linear-gradient(135deg, var(--primary) 0%, var(--primary-container) 100%);
  color: var(--on-primary);
  box-shadow: 0 4px 15px rgba(26, 35, 126, 0.2);
}

.join-btn:hover {
  filter: brightness(1.1);
  transform: translateY(-1px);
  box-shadow: 0 6px 20px rgba(26, 35, 126, 0.3);
}

.leave-btn {
  background: none;
  border: 1px solid var(--error);
  color: var(--error);
}

.leave-btn:hover { background-color: rgba(186, 26, 26, 0.05); }

.status-indicator-box {
  background-color: rgba(46, 125, 50, 0.12);
  color: var(--sports-green);
  border-radius: var(--radius-md);
  padding: 14px;
  font-weight: 700;
  font-size: 0.92rem;
  text-align: center;
}

.restricted-box {
  background: linear-gradient(135deg, rgba(255, 77, 141, 0.1) 0%, rgba(123, 97, 255, 0.05) 100%);
  color: #FF4D8D;
  border: 1px solid rgba(255, 77, 141, 0.3);
  border-radius: var(--radius-md);
  padding: 14px;
  font-weight: 700;
  font-size: 0.9rem;
  text-align: center;
}

.full-box {
  background-color: var(--surface-dim);
  color: var(--on-surface-variant);
  border-radius: var(--radius-md);
  padding: 14px;
  font-weight: 700;
  font-size: 0.9rem;
  text-align: center;
}

@keyframes rotation {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* Result badges on player tiles */
.result-badge {
  font-size: 0.7rem;
  font-weight: 700;
  padding: 4px 10px;
  border-radius: 12px;
  flex-shrink: 0;
}

.result-badge.result-win {
  background-color: rgba(46, 125, 50, 0.12);
  color: #2e7d32;
}

.result-badge.result-loss {
  background-color: rgba(186, 26, 26, 0.1);
  color: #ba1a1a;
}

.result-badge.result-draw {
  background-color: rgba(245, 158, 11, 0.12);
  color: #b45309;
}

/* Record Results Panel */
.results-panel {
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-lg);
  padding: 20px;
  box-shadow: var(--shadow-sm);
}

.results-hint {
  font-size: 0.78rem;
  color: var(--on-surface-variant);
  margin-bottom: 16px;
  line-height: 1.4;
}

.results-player-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-bottom: 20px;
}

.results-player-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 8px 0;
  border-bottom: 1px solid var(--outline-variant);
}

.results-player-row:last-child {
  border-bottom: none;
}

.results-player-info {
  display: flex;
  align-items: center;
  gap: 10px;
  flex: 1;
  min-width: 0;
}

.results-player-avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  object-fit: cover;
  flex-shrink: 0;
}

.results-player-name {
  font-size: 0.85rem;
  font-weight: 700;
  color: var(--on-surface);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.results-btn-group {
  display: flex;
  gap: 6px;
  flex-shrink: 0;
}

.result-select-btn {
  padding: 5px 12px;
  border-radius: 16px;
  border: 1.5px solid var(--outline-variant);
  background: none;
  font-size: 0.72rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s ease;
  color: var(--on-surface-variant);
}

.result-select-btn:hover {
  transform: translateY(-1px);
}

.result-select-btn.win.selected {
  background-color: #2e7d32;
  border-color: #2e7d32;
  color: #ffffff;
  box-shadow: 0 2px 8px rgba(46, 125, 50, 0.25);
}

.result-select-btn.loss.selected {
  background-color: #ba1a1a;
  border-color: #ba1a1a;
  color: #ffffff;
  box-shadow: 0 2px 8px rgba(186, 26, 26, 0.25);
}

.result-select-btn.draw.selected {
  background-color: #b45309;
  border-color: #b45309;
  color: #ffffff;
  box-shadow: 0 2px 8px rgba(180, 83, 9, 0.25);
}

.results-actions {
  display: flex;
  gap: 12px;
}

.results-cancel-btn {
  flex: 1;
  padding: 12px;
  border-radius: var(--radius-md);
  border: 1.5px solid var(--outline-variant);
  background: none;
  font-weight: 700;
  font-size: 0.88rem;
  color: var(--on-surface-variant);
  cursor: pointer;
  transition: all 0.2s ease;
}

.results-cancel-btn:hover {
  background-color: var(--surface-dim);
}

.results-save-btn {
  flex: 1;
  padding: 12px;
  border-radius: var(--radius-md);
  border: none;
  background: linear-gradient(135deg, #2e7d32 0%, #43a047 100%);
  font-weight: 700;
  font-size: 0.88rem;
  color: #ffffff;
  cursor: pointer;
  box-shadow: 0 4px 12px rgba(46, 125, 50, 0.2);
  transition: all 0.2s ease;
  display: flex;
  justify-content: center;
  align-items: center;
}

.results-save-btn:hover {
  filter: brightness(1.1);
  transform: translateY(-1px);
}

.results-save-btn:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

.small-loader {
  width: 18px;
  height: 18px;
  border: 2px solid #ffffff;
  border-bottom-color: transparent;
  border-radius: 50%;
  animation: rotation 1s linear infinite;
}

.record-results-btn {
  background: linear-gradient(135deg, #2e7d32 0%, #43a047 100%);
  color: #ffffff;
  box-shadow: 0 4px 15px rgba(46, 125, 50, 0.2);
}

.record-results-btn:hover {
  filter: brightness(1.1);
  transform: translateY(-1px);
  box-shadow: 0 6px 20px rgba(46, 125, 50, 0.3);
}

.animate-fade-in {
  animation: fadeIn 0.3s ease forwards;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(8px); }
  to { opacity: 1; transform: translateY(0); }
}

/* Player Rating Styles */
.star-rating-group {
  display: flex;
  gap: 4px;
  flex-shrink: 0;
}

.star-btn {
  background: none;
  border: none;
  font-size: 1.4rem;
  cursor: pointer;
  color: #d1d5db;
  transition: all 0.2s ease;
  padding: 2px;
  line-height: 1;
}

.star-btn:hover {
  transform: scale(1.2);
}

.star-btn.filled {
  color: #f59e0b;
  text-shadow: 0 2px 8px rgba(245, 158, 11, 0.35);
}

.rate-players-btn {
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
  color: #ffffff;
  box-shadow: 0 4px 15px rgba(245, 158, 11, 0.25);
}

.rate-players-btn:hover {
  filter: brightness(1.1);
  transform: translateY(-1px);
  box-shadow: 0 6px 20px rgba(245, 158, 11, 0.35);
}

.action-btn-group {
  display: flex;
  gap: 10px;
}

.action-btn-group .action-btn {
  flex: 1;
  padding: 12px;
  font-size: 0.88rem;
}

.rating-save {
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%) !important;
  box-shadow: 0 4px 12px rgba(245, 158, 11, 0.25) !important;
}

.rating-save:hover {
  box-shadow: 0 6px 16px rgba(245, 158, 11, 0.35) !important;
}

/* Location Map Link Styles */
.location-tile-link {
  text-decoration: none !important;
  cursor: pointer;
  border-radius: var(--radius-md);
  transition: all 0.2s ease;
}

.location-tile-link:hover .tile-icon {
  transform: scale(1.05);
  border-color: var(--primary) !important;
  background-color: rgba(26, 35, 126, 0.04) !important;
}

.location-title-text {
  display: inline-flex;
  align-items: center;
  gap: 4px;
}

.location-tile-link:hover .location-title-text {
  color: var(--primary) !important;
  text-decoration: underline !important;
}

.external-link-icon {
  stroke: var(--primary);
  opacity: 0.5;
  transition: opacity 0.2s ease;
}

.location-tile-link:hover .external-link-icon {
  opacity: 1;
}
</style>
