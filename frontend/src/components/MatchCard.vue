<script setup>
import { computed } from 'vue'
import { getSportImage, getPlayerAvatar } from '../utils/sportImageHelper'
import { store } from '../store'

const props = defineProps({
  match: {
    type: Object,
    required: true
  },
  isHorizontal: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['open-details', 'open-player'])

const slotsLeft = computed(() => {
  return Math.max(0, props.match.maxSlots - props.match.joinedCount)
})

const isJoined = computed(() => {
  if (!store.state.currentUser) return false
  return props.match.participants.some(p => p.id === store.state.currentUser.id)
})

const isRestricted = computed(() => {
  if (!props.match.womenOnly) return false
  return store.state.currentUser?.gender !== 'female'
})

const imageSrc = computed(() => {
  return getSportImage(props.match.sportType, props.match.id) || ''
})

const getSportIcon = (sport) => {
  const lower = sport.toLowerCase().trim()
  switch (lower) {
    case 'football':
      return '⚽'
    case 'basketball':
      return '🏀'
    case 'tennis':
      return '🎾'
    case 'padel':
    case 'pedal':
      return '🎾'
    case 'badminton':
      return '🏸'
    case 'cricket':
      return '🏏'
    default:
      return '⚽'
  }
}

const displayAvatars = computed(() => {
  const pCount = props.match.participants.length
  const limit = pCount > 3 ? 3 : pCount
  return props.match.participants.slice(0, limit)
})

const remainingParticipantsCount = computed(() => {
  return props.match.participants.length - 3
})

const handleJoin = (e) => {
  e.stopPropagation()
  store.joinMatch(props.match.id)
}
</script>

<template>
  <div class="match-card" :class="{ horizontal: isHorizontal }" @click="emit('open-details', match)">
    <!-- Banner Image Header -->
    <div 
      class="card-banner" 
      :class="[match.sportType.toLowerCase().trim(), { 'women-only': match.womenOnly }]"
      :style="{ backgroundImage: `url('${imageSrc}')` }"
    >
      <div class="banner-overlay"></div>
      
      <!-- Individual Badges for cleaner positioning -->
      <div class="sport-badge badge-top-left">
        <span>{{ getSportIcon(match.sportType) }}</span>
        <span>{{ match.sportType }}</span>
      </div>
      
      <div v-if="match.womenOnly" class="women-only-badge badge-top-right">
        🌸 Women Only
      </div>
      
      <div class="slots-badge badge-bottom-right" :class="{ full: slotsLeft === 0, alert: slotsLeft === 1 }">
        {{ slotsLeft > 0 ? `${slotsLeft} slots left` : 'Match Full' }}
      </div>
    </div>

    <!-- Details Body -->
    <div class="card-body">
      <!-- Top Content Group -->
      <div class="card-top-group">
        <div class="skill-tag-row">
          <span class="skill-tag">{{ match.skillLevel }}</span>
        </div>
        <h3 class="match-title">{{ match.title }}</h3>

        <!-- Metadata section -->
        <div class="metadata-section" :class="{ stacked: isHorizontal }">
          <div class="meta-item">
            <svg class="meta-icon" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
              <line x1="16" y1="2" x2="16" y2="6"/>
              <line x1="8" y1="2" x2="8" y2="6"/>
              <line x1="3" y1="10" x2="21" y2="10"/>
            </svg>
            <span class="meta-text">{{ match.dateTime }}</span>
          </div>
          
          <div class="meta-item">
            <svg class="meta-icon" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M12 2a8 8 0 0 0-8 8c0 5.25 8 12 8 12s8-6.75 8-12a8 8 0 0 0-8-8z"/>
              <circle cx="12" cy="10" r="3"/>
            </svg>
            <span class="meta-text location">{{ match.location }}</span>
          </div>
        </div>
      </div>

      <!-- Bottom Content Group -->
      <div class="card-bottom-group">
        <!-- Social Overlap Avatars & Organizer -->
        <div class="social-row">
          <div class="avatar-overlap-stack">
            <div 
              v-for="(participant, index) in displayAvatars" 
              :key="participant.id"
              class="avatar-item"
              :style="{ left: (index * 16) + 'px', zIndex: 10 - index }"
              @click.stop="emit('open-player', participant, match.sportType)"
            >
              <img :src="getPlayerAvatar(participant.profilePicture, 'male')" class="avatar-img" />
            </div>
            
            <div 
              v-if="remainingParticipantsCount > 0"
              class="avatar-item plus-more"
              :style="{ left: (3 * 16) + 'px', zIndex: 5 }"
            >
              +{{ remainingParticipantsCount }}
            </div>
          </div>

          <span class="organizer-text" @click.stop="emit('open-player', match.participants[0] || { name: match.organizer }, match.sportType)">
            By {{ match.organizer || 'Sportigo' }}
          </span>
        </div>

        <!-- Join Match Button -->
        <button 
          v-if="slotsLeft > 0 && !isJoined && !isRestricted" 
          class="join-match-btn"
          @click="handleJoin"
        >
          Join Match
        </button>
      </div>
    </div>
  </div>
</template>
<style scoped>
.match-card {
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: 20px;
  overflow: hidden;
  box-shadow: var(--shadow-sm);
  margin-bottom: 16px;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
  display: flex;
  flex-direction: column;
}

.match-card:hover {
  transform: translateY(-4px) scale(1.01);
  box-shadow: var(--shadow-md);
  border-color: var(--primary);
}

.match-card.horizontal {
  width: 290px;
  height: 350px;
  flex-shrink: 0;
  margin-bottom: 0;
  margin-right: 0;
  scroll-snap-align: start;
}

@media (max-width: 500px) {
  .match-card.horizontal {
    width: calc(100% - 40px);
    scroll-snap-align: center;
  }
}

.card-banner {
  height: 120px;
  background-size: cover;
  background-position: center;
  position: relative;
  display: flex;
  align-items: flex-start;
  padding: 12px;
  transition: all 0.3s ease;
}

/* Fallback colors for sport categories if image not loading */
.card-banner.football { background-color: #115e59; }
.card-banner.cricket { background-color: #9a3412; }
.card-banner.badminton { background-color: #6b21a8; }
.card-banner.basketball { background-color: #c2410c; }
.card-banner.tennis { background-color: #0f766e; }
.card-banner.padel { background-color: #0369a1; }

.banner-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 1;
  background: linear-gradient(180deg, rgba(15, 23, 42, 0.35) 0%, rgba(15, 23, 42, 0.75) 100%);
}

/* Sport specific overlay visual enhancements */
.card-banner.football .banner-overlay {
  background: linear-gradient(180deg, rgba(17, 94, 89, 0.3) 0%, rgba(15, 23, 42, 0.8) 100%);
}
.card-banner.cricket .banner-overlay {
  background: linear-gradient(180deg, rgba(154, 52, 18, 0.3) 0%, rgba(15, 23, 42, 0.8) 100%);
}
.card-banner.badminton .banner-overlay {
  background: linear-gradient(180deg, rgba(107, 33, 168, 0.3) 0%, rgba(15, 23, 42, 0.8) 100%);
}
.card-banner.basketball .banner-overlay {
  background: linear-gradient(180deg, rgba(194, 65, 12, 0.3) 0%, rgba(15, 23, 42, 0.8) 100%);
}
.card-banner.tennis .banner-overlay {
  background: linear-gradient(180deg, rgba(15, 118, 110, 0.3) 0%, rgba(15, 23, 42, 0.8) 100%);
}
.card-banner.padel .banner-overlay {
  background: linear-gradient(180deg, rgba(3, 105, 161, 0.3) 0%, rgba(15, 23, 42, 0.8) 100%);
}
.card-banner.women-only .banner-overlay {
  background: linear-gradient(180deg, rgba(255, 77, 141, 0.35) 0%, rgba(30, 11, 23, 0.85) 100%) !important;
}



.badge-top-left {
  position: absolute;
  top: 12px;
  left: 12px;
  z-index: 2;
}

.badge-top-right {
  position: absolute;
  top: 12px;
  right: 12px;
  z-index: 2;
}

.badge-bottom-right {
  position: absolute;
  bottom: 12px;
  right: 12px;
  z-index: 2;
}

.sport-badge, .women-only-badge, .slots-badge {
  padding: 5px 10px;
  border-radius: 20px;
  font-size: 0.68rem;
  font-weight: 700;
  display: flex;
  align-items: center;
  gap: 4px;
  backdrop-filter: blur(4px);
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
}

.sport-badge {
  background: rgba(255, 255, 255, 0.15);
  color: #ffffff;
  border: 1px solid rgba(255, 255, 255, 0.25);
}

.women-only-badge {
  background: linear-gradient(135deg, #FF4D8D 0%, #7B61FF 100%);
  color: #ffffff;
  box-shadow: 0 2px 8px rgba(255, 77, 141, 0.4);
}

.slots-badge {
  background: linear-gradient(135deg, #10b981 0%, #059669 100%);
  color: #ffffff;
  box-shadow: 0 2px 6px rgba(16, 185, 129, 0.25);
}

.slots-badge.alert {
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
  box-shadow: 0 2px 6px rgba(245, 158, 11, 0.3);
  animation: pulseGlow 1.5s infinite;
}

.slots-badge.full {
  background: #64748b;
  box-shadow: none;
}

.card-body {
  padding: 16px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  flex: 1;
}

.card-top-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-bottom: 12px;
}

.card-bottom-group {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-top: auto;
}

.skill-tag-row {
  display: flex;
}

.skill-tag {
  background-color: var(--surface-dim);
  color: var(--text-medium);
  font-size: 0.65rem;
  font-weight: 700;
  padding: 4px 8px;
  border-radius: 8px;
  white-space: nowrap;
  border: 1px solid var(--outline-variant);
}

.match-title {
  font-family: 'Outfit', sans-serif;
  font-size: 1.05rem;
  font-weight: 700;
  color: var(--text-dark);
  line-height: 1.25;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.metadata-section {
  display: flex;
  gap: 16px;
  margin-bottom: 16px;
}

.metadata-section.stacked {
  flex-direction: column;
  gap: 6px;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 6px;
  color: var(--text-medium);
  font-size: 0.72rem;
  min-width: 0;
}

.meta-icon {
  flex-shrink: 0;
}

.meta-text {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.meta-text.location {
  white-space: normal;
  display: -webkit-box;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
}

.social-row {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-top: 0;
  margin-bottom: 0;
}

.avatar-overlap-stack {
  position: relative;
  width: 75px;
  height: 28px;
}

.avatar-item {
  position: absolute;
  top: 0;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  border: 2px solid #ffffff;
  overflow: hidden;
  cursor: pointer;
  transition: transform 0.2s;
}

.avatar-item:hover {
  transform: translateY(-2px) scale(1.05);
}

.avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.plus-more {
  background-color: var(--primary-light);
  color: var(--primary);
  font-size: 0.65rem;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 2px solid #ffffff;
}

.organizer-text {
  font-size: 0.75rem;
  font-weight: 600;
  color: var(--primary);
  cursor: pointer;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.join-match-btn {
  width: 100%;
  background: linear-gradient(135deg, var(--primary) 0%, var(--primary-container) 100%);
  color: #ffffff;
  border: none;
  font-family: var(--font-sans);
  font-weight: 700;
  font-size: 0.85rem;
  padding: 11px 0;
  border-radius: 12px;
  cursor: pointer;
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
  transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}

.join-match-btn:hover {
  filter: brightness(1.1);
  transform: translateY(-1px);
  box-shadow: 0 6px 14px rgba(0, 0, 0, 0.15);
}

.join-match-btn:active {
  transform: translateY(0);
}
</style>
