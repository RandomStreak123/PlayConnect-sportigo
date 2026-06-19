<script setup>
import { ref, computed } from 'vue'
import { store } from '../store'
import MatchCard from '../components/MatchCard.vue'
import { t } from '../utils/i18n'

const emit = defineEmits(['open-details', 'open-player', 'open-create'])

const activeSubTab = ref('upcoming') // 'upcoming' or 'past'

const myMatches = computed(() => {
  if (!store.state.currentUser) return []
  const userId = store.state.currentUser.id
  
  return store.state.matches.filter(match => {
    // User is creator or participant
    const isCreator = match.creatorId === userId
    const isParticipant = match.participants.some(p => p.id === userId)
    return isCreator || isParticipant
  })
})

const filteredMatches = computed(() => {
  const now = new Date()
  let list = myMatches.value.filter(match => {
    const matchTime = new Date(match.dateTime.replace(' ', 'T'))
    const isFuture = matchTime >= now
    return activeSubTab.value === 'upcoming' ? isFuture : !isFuture
  })
  
  // Sort
  if (activeSubTab.value === 'upcoming') {
    // nearest first
    return list.sort((a, b) => new Date(a.dateTime.replace(' ', 'T')) - new Date(b.dateTime.replace(' ', 'T')))
  } else {
    // most recent past match first
    return list.sort((a, b) => new Date(b.dateTime.replace(' ', 'T')) - new Date(a.dateTime.replace(' ', 'T')))
  }
})
</script>

<template>
  <div class="my-matches-container scrollable-y animate-fade-in">
    <!-- Header with Background Gradient -->
    <div class="matches-header">
      <h2 class="title">{{ t('myMatches') }}</h2>
      
      <!-- Custom tabs bar -->
      <div class="sub-tabs-bar">
        <button 
          class="sub-tab-btn" 
          :class="{ active: activeSubTab === 'upcoming' }"
          @click="activeSubTab = 'upcoming'"
        >
          📅 {{ t('upcoming') }}
        </button>
        <button 
          class="sub-tab-btn" 
          :class="{ active: activeSubTab === 'past' }"
          @click="activeSubTab = 'past'"
        >
          ⏳ {{ t('pastMatches') }}
        </button>
      </div>
    </div>

    <!-- Listings -->
    <div class="matches-list-panel">
      <div v-if="filteredMatches.length === 0" class="empty-state">
        <div class="empty-icon-wrap">
          {{ activeSubTab === 'upcoming' ? '⚽' : '👟' }}
        </div>
        <h4 class="empty-title">
          {{ activeSubTab === 'upcoming' ? t('noUpcomingMatches') : t('noMatchHistory') }}
        </h4>
        <p class="empty-desc">
          {{ activeSubTab === 'upcoming' ? t('noUpcomingDesc') : t('noPastDesc') }}
        </p>
        
        <button 
          v-if="activeSubTab === 'upcoming'" 
          class="create-match-btn"
          @click="emit('open-create')"
        >
          {{ t('createNewMatch') }}
        </button>
      </div>

      <div v-else class="list-wrap">
        <MatchCard 
          v-for="match in filteredMatches" 
          :key="match.id"
          :match="match"
          @open-details="emit('open-details', match)"
          @open-player="(p, s) => emit('open-player', p, s)"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
.my-matches-container {
  padding: 56px 20px 80px;
  background-color: var(--scaffold-bg);
}

.matches-header {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-bottom: 24px;
}

.title {
  font-family: var(--font-display);
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--on-surface);
}

.sub-tabs-bar {
  display: flex;
  background-color: var(--surface-dim);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  padding: 4px;
  width: 100%;
  max-width: 380px;
  margin: 0 auto;
}

.sub-tab-btn {
  flex: 1;
  border: none;
  background: none;
  outline: none;
  padding: 10px;
  color: var(--on-surface-variant);
  font-weight: 700;
  font-size: 0.85rem;
  border-radius: 12px;
  cursor: pointer;
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 6px;
  transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}

.sub-tab-btn.active {
  background-color: var(--surface);
  color: var(--primary);
  box-shadow: var(--shadow-sm);
}

.matches-list-panel {
  padding: 0;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  padding: 40px 16px;
}

.empty-icon-wrap {
  width: 100px;
  height: 100px;
  border-radius: 50%;
  background-color: rgba(26, 35, 126, 0.04);
  display: flex;
  justify-content: center;
  align-items: center;
  font-size: 3rem;
  margin-bottom: 24px;
}

.empty-title {
  font-size: 1.15rem;
  font-weight: 700;
  color: var(--on-surface);
  margin-bottom: 10px;
}

.empty-desc {
  font-size: 0.85rem;
  color: var(--on-surface-variant);
  line-height: 1.5;
  margin-bottom: 28px;
  max-width: 320px;
}

.create-match-btn {
  background-color: var(--primary);
  color: var(--on-primary);
  border: none;
  border-radius: var(--radius-md);
  padding: 14px 28px;
  font-weight: 700;
  font-size: 0.9rem;
  cursor: pointer;
  box-shadow: var(--shadow-sm);
}

.create-match-btn:hover {
  filter: brightness(1.1);
}

.list-wrap {
  display: grid;
  grid-template-columns: 1fr;
  gap: 20px;
  padding-bottom: 60px;
}

@media (min-width: 640px) {
  .list-wrap {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (min-width: 1024px) {
  .list-wrap {
    grid-template-columns: repeat(3, 1fr);
  }
}
</style>
