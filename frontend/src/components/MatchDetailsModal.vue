<script setup>
import { ref, computed } from 'vue'
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

const isSubmitting = ref(false)

const slotsLeft = computed(() => {
  return Math.max(0, props.match.maxSlots - props.match.joinedCount)
})

const isJoined = computed(() => {
  if (!store.state.currentUser) return false
  return props.match.participants.some(p => p.id === store.state.currentUser.id)
})

const isCreator = computed(() => {
  if (!store.state.currentUser) return false
  return props.match.creatorId === store.state.currentUser.id
})

const isRestricted = computed(() => {
  if (!props.match.womenOnly) return false
  return store.state.currentUser?.gender !== 'female'
})

const imageSrc = computed(() => {
  const raw = getSportImage(props.match.sportType, props.match.id)
  if (!raw) return ''
  return raw.split('/').map(s => encodeURIComponent(s)).join('/')
})

// Chat history and scroll-to-bottom handlers removed as chat is disabled

const handleJoin = () => {
  if (isRestricted.value) return
  isSubmitting.value = true
  setTimeout(() => {
    store.joinMatch(props.match.id)
    isSubmitting.value = false
    emit('action-success', 'Successfully joined match! 🥳')
  }, 500)
}

const handleLeave = () => {
  isSubmitting.value = true
  setTimeout(() => {
    store.leaveMatch(props.match.id)
    isSubmitting.value = false
    emit('action-success', 'Left the match.')
  }, 500)
}

// sendChat removed

const handleShare = () => {
  emit('action-success', 'Share link copied to clipboard! 📋')
}
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
          <div class="info-tile">
            <span class="tile-icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="tile-svg"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
            </span>
            <div class="tile-info">
              <span class="tile-title">{{ match.location }}</span>
              <span class="tile-desc">{{ slotsLeft }} {{ t('slotsOpenSuffix') }}</span>
            </div>
          </div>
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
            </div>
            
            <div v-if="slotsLeft > 0 && !isCreator" class="waiting-spot">
              <span class="waiting-icon">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="waiting-svg"><path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
              </span>
              <span class="waiting-text">{{ t('waitingSpotText') }}</span>
            </div>
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
          <!-- Joined but not creator: Leave button -->
          <button 
            v-if="isJoined && !isCreator" 
            class="action-btn leave-btn"
            @click="handleLeave"
          >
            {{ t('leaveMatch') }}
          </button>
          
          <!-- Creator indicator -->
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
        </div>
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
  backdrop-filter: blur(8px);
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
  height: 90%;
  background-color: var(--scaffold-bg);
  border-top-left-radius: var(--radius-xl);
  border-top-right-radius: var(--radius-xl);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  box-shadow: 0 -10px 30px rgba(15, 23, 42, 0.15);
  border: 1px solid rgba(255, 255, 255, 0.08);
}

@media (min-width: 768px) {
  .modal-sheet {
    width: 100%;
    max-width: 650px;
    height: 80vh;
    border-radius: var(--radius-lg);
    box-shadow: var(--shadow-lg);
  }
}

.cover-banner {
  height: 200px;
  background-size: cover;
  background-position: center;
  position: relative;
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

.details-content {
  flex: 1;
  padding: 16px 20px;
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
</style>
