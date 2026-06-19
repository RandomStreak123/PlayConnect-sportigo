<script setup>
import { computed } from 'vue'
import { store } from '../store'
import { getPlayerAvatar, getSportIconUrl } from '../utils/sportImageHelper'
import { t } from '../utils/i18n'

const emit = defineEmits(['open-match-details', 'open-player'])

// Use the dedicated my-match activities (join/leave on current user's matches by others)
const feedActivities = computed(() => store.state.myMatchActivities || [])

const getSportColorClass = (sport) => {
  const s = String(sport || '').toLowerCase().trim()
  switch (s) {
    case 'football':   return 'football'
    case 'basketball': return 'basketball'
    case 'tennis':     return 'tennis'
    case 'padel':      return 'padel'
    case 'badminton':  return 'badminton'
    case 'cricket':    return 'cricket'
    default:           return 'default'
  }
}

const getActionLabel = (act) => {
  if (act.type === 'match_joined') return 'joined your match'
  if (act.type === 'match_left')   return 'left your match'
  return act.action || act.type
}

const handleActivityClick = (act) => {
  const matchId = act.meta?.match_id
  const match = matchId
    ? store.state.matches.find(m => m.id === matchId)
    : store.state.matches.find(m => m.title === act.matchTitle)
  if (match) emit('open-match-details', match)
}
</script>

<template>
  <div class="activity-feed-container scrollable-y animate-fade-in">
    <!-- Header -->
    <div class="feed-header">
      <h2 class="title">{{ t('sportsFeed') }}</h2>
    </div>

    <!-- Feed list -->
    <div class="feed-list">
      <!-- Empty state -->
      <div v-if="feedActivities.length === 0" class="empty-state">
        <div class="empty-icon">🏟️</div>
        <p class="empty-title">No activity yet</p>
        <p class="empty-subtitle">When players join or leave your matches, it will appear here.</p>
      </div>

      <div
        v-for="act in feedActivities"
        :key="act.id"
        class="activity-card"
        :class="act.type === 'match_left' ? 'left-card' : 'joined-card'"
        @click="handleActivityClick(act)"
      >
        <!-- Top row -->
        <div class="card-top-row">
          <div
            class="user-info"
            @click.stop="emit('open-player', { id: act.user_id || act.userId, name: act.userName, profilePicture: act.userAvatar }, act.sportType)"
          >
            <img :src="getPlayerAvatar(act.userAvatar, 'male')" class="user-avatar" />
            <div class="name-time-wrap">
              <span class="user-name">{{ act.userName }}</span>
              <span class="activity-time">{{ act.time }}</span>
            </div>
          </div>

          <div class="sport-indicator" :class="getSportColorClass(act.sportType)">
            <img :src="getSportIconUrl(act.sportType)" class="sport-icon-img" alt="" />
          </div>
        </div>

        <!-- Activity message -->
        <p class="activity-msg">
          <span class="user-bold">{{ act.userName }}</span>&nbsp;
          <span :class="act.type === 'match_left' ? 'action-left' : 'action-joined'">
            {{ getActionLabel(act) }}:
          </span>
          <span class="match-name-highlight">"{{ act.matchTitle || act.meta?.title }}"</span>
        </p>


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
  margin: 0 0 4px;
}

.subtitle {
  font-size: 0.8rem;
  color: var(--outline);
  margin: 0;
}

.feed-list {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

/* Empty state */
.empty-state {
  text-align: center;
  padding: 60px 20px;
}

.empty-icon {
  font-size: 3rem;
  margin-bottom: 12px;
}

.empty-title {
  font-size: 1rem;
  font-weight: 700;
  color: var(--on-surface);
  margin: 0 0 6px;
}

.empty-subtitle {
  font-size: 0.82rem;
  color: var(--outline);
  margin: 0;
  line-height: 1.5;
}

/* Cards */
.activity-card {
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  padding: 16px;
  box-shadow: var(--shadow-sm);
  cursor: pointer;
  transition: transform 0.18s ease, box-shadow 0.18s ease;
  border-left: 3px solid transparent;
}

.activity-card:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-md);
}

.joined-card {
  border-left-color: #4caf50;
}

.left-card {
  border-left-color: #f44336;
}

.card-top-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
  cursor: pointer;
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
  flex-shrink: 0;
}

.sport-icon-img {
  width: 20px;
  height: 20px;
  object-fit: contain;
}

/* Sport color backgrounds */
.sport-indicator.football   { background-color: rgba(46, 125, 50, 0.08); }
.sport-indicator.basketball { background-color: rgba(255, 145, 0, 0.08); }
.sport-indicator.tennis     { background-color: rgba(205, 220, 57, 0.08); }
.sport-indicator.padel      { background-color: rgba(0, 150, 136, 0.08); }
.sport-indicator.badminton  { background-color: rgba(0, 188, 212, 0.08); }
.sport-indicator.cricket    { background-color: rgba(63, 81, 181, 0.08); }
.sport-indicator.default    { background-color: var(--surface-dim); }

.activity-msg {
  font-size: 0.88rem;
  color: var(--on-surface-variant);
  line-height: 1.45;
  margin: 0 0 10px;
}

.user-bold {
  font-weight: 700;
  color: var(--on-surface);
}

.action-joined {
  font-weight: 600;
  color: #4caf50;
}

.action-left {
  font-weight: 600;
  color: #f44336;
}

.match-name-highlight {
  font-weight: 600;
  color: var(--primary);
}

/* Meta row chips */
.match-meta-row {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.meta-chip {
  font-size: 0.72rem;
  font-weight: 500;
  color: var(--on-surface-variant);
  background: var(--surface-dim, rgba(0,0,0,0.04));
  border-radius: 20px;
  padding: 3px 10px;
}

.sport-chip {
  color: var(--primary);
  background: color-mix(in srgb, var(--primary) 10%, transparent);
}
</style>
