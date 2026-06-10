<script setup>
import { computed } from 'vue'
import { getPlayerAvatar } from '../utils/sportImageHelper'

const props = defineProps({
  player: {
    type: Object,
    required: true
  },
  sportType: {
    type: String,
    default: 'Sport'
  },
  show: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['close', 'view-profile', 'wave-success'])

const avatarUrl = computed(() => {
  return getPlayerAvatar(props.player.profilePicture, props.player.gender || 'male')
})

const getGradientForSport = (sport) => {
  const s = String(sport || '').toLowerCase().trim()
  switch (s) {
    case 'football':
      return 'linear-gradient(135deg, #2E7D32 0%, #1B5E20 100%)'
    case 'basketball':
      return 'linear-gradient(135deg, #FF9100 0%, #DD2C00 100%)'
    case 'tennis':
    case 'padel':
    case 'badminton':
      return 'linear-gradient(135deg, #AEEA00 0%, #006064 100%)'
    case 'cricket':
      return 'linear-gradient(135deg, #00B0FF 0%, #0A2240 100%)'
    default:
      return 'linear-gradient(135deg, #1E3C72 0%, #2A5298 100%)'
  }
}

const getSportEmoji = (sport) => {
  const s = String(sport || '').toLowerCase().trim()
  switch (s) {
    case 'football': return '⚽'
    case 'basketball': return '🏀'
    case 'tennis': return '🎾'
    case 'padel': return '🏓'
    case 'badminton': return '🏸'
    case 'cricket': return '🏏'
    default: return '🏆'
  }
}

const bannerStyle = computed(() => {
  return {
    background: getGradientForSport(props.sportType)
  }
})

const handleWave = () => {
  emit('wave-success', `Waved at ${props.player.name}! 👋`)
}

const handleViewProfile = () => {
  emit('view-profile', props.player)
  emit('close')
}
</script>

<template>
  <div v-if="show" class="reveal-backdrop" @click="emit('close')">
    <div class="reveal-sheet animate-slide-up" @click.stop>
      <!-- Visual pull bar -->
      <div class="pull-bar"></div>
      
      <!-- Top banner block -->
      <div class="reveal-banner" :style="bannerStyle">
        <div class="watermark-emoji">{{ getSportEmoji(sportType) }}</div>
        
        <button class="close-btn" @click="emit('close')">✕</button>
      </div>

      <!-- Avatar overlap -->
      <div class="avatar-container">
        <div class="avatar-circle">
          <img :src="avatarUrl" class="avatar-img" />
        </div>
      </div>

      <!-- Details block -->
      <div class="reveal-body">
        <h2 class="player-name">{{ player.name }}</h2>
        
        <!-- Badges -->
        <div class="badge-row">
          <div class="sport-badge">
            <span class="badge-icon">{{ getSportEmoji(sportType) }}</span>
            <span class="badge-label">{{ sportType.toUpperCase() }}</span>
          </div>
          <div class="status-badge">
            MATCH PLAYER
          </div>
        </div>

        <!-- Bio block -->
        <div class="bio-card">
          <span class="bio-emoji">🔥</span>
          <p class="bio-text">
            "Game on! See you at the match. Let's play a legendary session!"
          </p>
        </div>

        <!-- Action panel -->
        <div class="action-buttons">
          <button class="action-btn wave-btn pulse-glow" @click="handleWave">
            <span class="wave-emoji wave-shake">👋</span>
            Send a Quick Wave
          </button>
          
          <button class="action-btn profile-btn" @click="handleViewProfile">
            View Full Profile
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.reveal-backdrop {
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
  .reveal-backdrop {
    align-items: center;
    justify-content: center;
  }
}

.reveal-sheet {
  width: 100%;
  background-color: var(--surface);
  border-top-left-radius: var(--radius-xl);
  border-top-right-radius: var(--radius-xl);
  position: relative;
  display: flex;
  flex-direction: column;
  padding-bottom: 24px;
}

@media (min-width: 768px) {
  .reveal-sheet {
    width: 100%;
    max-width: 460px;
    border-radius: var(--radius-lg);
    box-shadow: var(--shadow-lg);
    overflow: hidden;
  }
}

.pull-bar {
  position: absolute;
  top: 10px;
  left: 50%;
  transform: translateX(-50%);
  width: 40px;
  height: 4px;
  background-color: rgba(255, 255, 255, 0.45);
  border-radius: 2px;
  z-index: 20;
}

.reveal-banner {
  height: 120px;
  border-top-left-radius: var(--radius-xl);
  border-top-right-radius: var(--radius-xl);
  position: relative;
  overflow: hidden;
}

.watermark-emoji {
  position: absolute;
  right: -20px;
  top: -20px;
  font-size: 8rem;
  opacity: 0.15;
  user-select: none;
}

.close-btn {
  position: absolute;
  top: 16px;
  right: 16px;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  border: none;
  background-color: rgba(0, 0, 0, 0.3);
  color: #ffffff;
  font-weight: 700;
  font-size: 0.9rem;
  cursor: pointer;
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 10;
  transition: background-color 0.2s;
}

.close-btn:hover {
  background-color: rgba(0, 0, 0, 0.5);
}

.avatar-container {
  display: flex;
  justify-content: center;
  margin-top: -50px;
  position: relative;
  z-index: 5;
}

.avatar-circle {
  width: 100px;
  height: 100px;
  border-radius: 50%;
  background-color: #ffffff;
  padding: 4px;
  box-shadow: var(--shadow-md);
}

.avatar-img {
  width: 100%;
  height: 100%;
  border-radius: 50%;
  object-fit: cover;
}

.reveal-body {
  padding: 16px 24px 0;
  text-align: center;
  display: flex;
  flex-direction: column;
}

.player-name {
  font-size: 1.5rem;
  font-weight: 800;
  color: var(--on-surface);
  margin-bottom: 8px;
}

.badge-row {
  display: flex;
  justify-content: center;
  gap: 8px;
  margin-bottom: 20px;
}

.sport-badge {
  background-color: rgba(26, 35, 126, 0.08);
  border: 1px solid rgba(26, 35, 126, 0.15);
  padding: 6px 12px;
  border-radius: 20px;
  display: flex;
  align-items: center;
  gap: 6px;
}

.badge-icon {
  font-size: 0.85rem;
}

.badge-label {
  font-size: 0.72rem;
  font-weight: 700;
  color: var(--primary);
  letter-spacing: 0.5px;
}

.status-badge {
  background-color: rgba(255, 145, 0, 0.08);
  border: 1px solid rgba(255, 145, 0, 0.15);
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 0.72rem;
  font-weight: 700;
  color: var(--warm-orange);
  letter-spacing: 0.5px;
}

.bio-card {
  background-color: var(--scaffold-bg);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  padding: 16px;
  display: flex;
  gap: 12px;
  text-align: left;
  margin-bottom: 28px;
}

.bio-emoji {
  font-size: 1.4rem;
}

.bio-text {
  font-size: 0.85rem;
  color: var(--on-surface-variant);
  font-style: italic;
  line-height: 1.4;
}

.action-buttons {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.action-btn {
  width: 100%;
  padding: 16px;
  border-radius: var(--radius-md);
  font-size: 0.95rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s ease;
}

.wave-btn {
  background-color: var(--primary);
  color: #ffffff;
  border: none;
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 8px;
}

.wave-emoji {
  font-size: 1.1rem;
}

.profile-btn {
  background: none;
  border: 1px solid var(--outline-variant);
  color: var(--on-surface);
}

.profile-btn:hover {
  background-color: var(--scaffold-bg);
}
</style>
