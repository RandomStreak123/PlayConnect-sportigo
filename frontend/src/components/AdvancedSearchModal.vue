<script setup>
import { ref } from 'vue'
import { store } from '../store'
import { t } from '../utils/i18n'

const props = defineProps({
  show: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['close', 'apply-filters'])

const sports = ['All', 'Football', 'Basketball', 'Tennis', 'Padel', 'Badminton', 'Cricket']
const skills = ['All', 'Beginner', 'Intermediate', 'Advanced', 'Professional']

const searchQuery = ref('')
const selectedSport = ref('All')
const selectedSkill = ref('All')
const distanceRange = ref(15) // simple range up to 50km

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
            :placeholder="t('searchPlaceholder')" 
            class="search-input"
            @keyup.enter="handleApply"
          />
        </div>

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

      <!-- Action Footer -->
      <div class="modal-footer">
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
  padding: 12px 12px 12px 38px;
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  outline: none;
  font-size: 0.9rem;
  color: var(--on-surface);
}

.search-input:focus { border-color: var(--primary); }

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
</style>
