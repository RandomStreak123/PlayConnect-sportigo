<script setup>
import { computed } from 'vue'
import { store } from '../store'
import { getPlayerAvatar } from '../utils/sportImageHelper'
import { t } from '../utils/i18n'

const emit = defineEmits(['open-match-details', 'open-player'])

const activities = computed(() => {
  return store.state.activities || []
})

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

const getSportColorClass = (sport) => {
  const s = String(sport || '').toLowerCase().trim()
  switch (s) {
    case 'football': return 'football'
    case 'basketball': return 'basketball'
    case 'tennis': return 'tennis'
    case 'padel': return 'padel'
    case 'badminton': return 'badminton'
    case 'cricket': return 'cricket'
    default: return 'default'
  }
}

const handleActivityClick = (act) => {
  // Find match in store matches
  const match = store.state.matches.find(m => m.title === act.matchTitle)
  if (match) {
    emit('open-match-details', match)
  }
}

const handleLike = (e, act) => {
  e.stopPropagation()
  store.toggleLikeActivity(act.id)
}

const handleComment = (e, act) => {
  e.stopPropagation()
  store.addCommentToActivity(act.id)
}
</script>

<template>
  <div class="activity-feed-container scrollable-y animate-fade-in">
    <!-- Header -->
    <div class="feed-header">
      <h2 class="title">{{ t('activity') }}</h2>
    </div>

    <!-- Feed list -->
    <div class="feed-list">
      <div v-if="activities.length === 0" class="empty-state">
        {{ t('noActivityUpdates') }}
      </div>
      
      <div 
        v-for="act in activities" 
        :key="act.id" 
        class="activity-card"
        @click="handleActivityClick(act)"
      >
        <!-- Top row: User details -->
        <div class="card-top-row">
          <div class="user-info" @click.stop="emit('open-player', { name: act.userName, profilePicture: act.userAvatar }, act.sportType)">
            <img :src="getPlayerAvatar(act.userAvatar, 'male')" class="user-avatar" />
            <div class="name-time-wrap">
              <span class="user-name">{{ act.userName }}</span>
              <span class="activity-time">{{ act.time }}</span>
            </div>
          </div>
          <div class="sport-indicator" :class="getSportColorClass(act.sportType)">
            {{ getSportEmoji(act.sportType) }}
          </div>
        </div>

        <!-- Description body -->
        <p class="activity-msg">
          <span class="user-bold">{{ act.userName }}</span> 
          {{ act.action }}:
          <span class="match-name-highlight">"{{ act.matchTitle }}"</span>
        </p>

        <!-- Dynamic Action triggers -->
        <div class="activity-meta-bottom">
          <button 
            class="interaction-btn" 
            :class="{ active: act.likedByMe }"
            @click="handleLike($event, act)"
          >
            <span class="btn-icon">{{ act.likedByMe ? '❤️' : '🤍' }}</span>
            <span class="btn-label">{{ act.likes }} Likes</span>
          </button>

          <button class="interaction-btn" @click="handleComment($event, act)">
            <span class="btn-icon">💬</span>
            <span class="btn-label">{{ act.comments }} Comments</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.activity-feed-container {
  padding: 56px 20px 80px;
  background-color: var(--scaffold-bg);
}

.feed-header {
  margin-bottom: 24px;
}

.title {
  font-family: var(--font-display);
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--on-surface);
}

.feed-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.empty-state {
  text-align: center;
  padding: 40px;
  font-size: 0.85rem;
  color: var(--on-surface-variant);
}

.activity-card {
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  padding: 16px;
  box-shadow: var(--shadow-sm);
  cursor: pointer;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.activity-card:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-md);
}

.card-top-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.user-avatar {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  object-fit: cover;
}

.name-time-wrap {
  display: flex;
  flex-direction: column;
}

.user-name {
  font-size: 0.88rem;
  font-weight: 700;
  color: var(--on-surface);
}

.activity-time {
  font-size: 0.72rem;
  color: var(--outline);
}

.sport-indicator {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: flex;
  justify-content: center;
  align-items: center;
  font-size: 1.1rem;
}

/* Color codes */
.sport-indicator.football { background-color: rgba(46, 125, 50, 0.08); }
.sport-indicator.basketball { background-color: rgba(255, 145, 0, 0.08); }
.sport-indicator.tennis { background-color: rgba(205, 220, 57, 0.08); }
.sport-indicator.padel { background-color: rgba(0, 150, 136, 0.08); }
.sport-indicator.badminton { background-color: rgba(0, 188, 212, 0.08); }
.sport-indicator.cricket { background-color: rgba(63, 81, 181, 0.08); }
.sport-indicator.default { background-color: var(--surface-dim); }

.activity-msg {
  font-size: 0.88rem;
  color: var(--on-surface-variant);
  line-height: 1.45;
  margin-bottom: 16px;
}

.user-bold {
  font-weight: 700;
  color: var(--on-surface);
}

.match-name-highlight {
  font-weight: 600;
  color: var(--primary);
}

.activity-meta-bottom {
  display: flex;
  gap: 16px;
  border-top: 1px solid var(--outline-variant);
  padding-top: 12px;
}

.interaction-btn {
  background: none;
  border: none;
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 0.78rem;
  font-weight: 700;
  color: var(--on-surface-variant);
  cursor: pointer;
  transition: color 0.2s;
}

.interaction-btn:hover {
  color: var(--primary);
}

.interaction-btn.active {
  color: #E91E63;
}

.btn-icon {
  font-size: 0.95rem;
}
</style>
