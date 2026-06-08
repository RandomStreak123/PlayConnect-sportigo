<script setup>
import { ref, computed } from 'vue'
import { store } from '../store'
import { t } from '../utils/i18n'

const props = defineProps({
  show: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['close', 'match-created'])

const sports = ['Football', 'Basketball', 'Tennis', 'Padel', 'Badminton', 'Cricket']
const skills = ['Beginner', 'Intermediate', 'Advanced', 'Professional']

const selectedSport = ref('Football')
const title = ref('')
const getDefaultDateTime = () => {
  // Setup standard date string format: yyyy-MM-ddThh:mm
  const date = new Date(Date.now() + 2 * 60 * 60 * 1000)
  date.setMinutes(0)
  const tzOffset = date.getTimezoneOffset() * 60000
  return new Date(date - tzOffset).toISOString().slice(0, 16)
}
const dateTime = ref(getDefaultDateTime())
const location = ref('')
const slots = ref('')
const selectedSkill = ref('Intermediate')
const womenOnly = ref(false)

const formError = ref('')
const isSubmitting = ref(false)

const minDateTime = computed(() => {
  const date = new Date()
  const tzOffset = date.getTimezoneOffset() * 60000
  return new Date(date - tzOffset).toISOString().slice(0, 16)
})

// Autocomplete Location suggestions logic (Dynamically loaded from database matches + fallbacks)
const locationSuggestions = computed(() => {
  const fallbacks = [
    'Sportigo Arena, Madhapur',
    'Municipal Ground, Hyderabad',
    'HotFut Turf, Gachibowli',
    'AstroPark Turf, Jubilee Hills',
    'Plexus Turf, Madhapur',
    'The Pitch Turf, Kondapur',
    'Drive-In Arena, Hyderabad',
    'Game On Turf, Gachibowli',
    'Active Arena, Kadugodi',
    'Base Hyderabad Turf, Madhapur',
    'SkyZone Padel Arena, Hitec City',
    'PowerPlay Turf, Banjara Hills',
    'Matchday Turf, Madhapur',
    'Striker Turf, Kondapur',
    'SportyZone Badminton Court, Miyapur',
    'Vijay Badminton Club, Kukatpally',
    'Gachibowli Indoor Stadium, Court 1',
    'Secunderabad Club Tennis Court',
    'Yousufguda Indoor Stadium, Hyderabad',
    'Lal Bahadur Stadium Cricket Ground',
    'Central Park Tennis Court 2',
    'Olimpia Sports Complex, Jubilee Hills'
  ]
  
  // Extract unique locations from existing matches in the store
  const databaseLocations = store.state.matches
    .map(match => match.location)
    .filter(loc => typeof loc === 'string' && loc.trim().length > 0)
  
  const unique = new Set()
  const result = []
  
  // Prioritize active database locations
  for (const loc of databaseLocations) {
    const key = loc.toLowerCase().trim()
    if (!unique.has(key)) {
      unique.add(key)
      result.push(loc.trim())
    }
  }
  
  // Append fallback popular venues if not already present
  for (const loc of fallbacks) {
    const key = loc.toLowerCase().trim()
    if (!unique.has(key)) {
      unique.add(key)
      result.push(loc)
    }
  }
  
  return result
})

const showSuggestions = ref(false)
const filteredSuggestions = computed(() => {
  const allSuggestions = locationSuggestions.value
  if (!location.value) {
    return allSuggestions
  }
  const query = location.value.toLowerCase().trim()
  return allSuggestions.filter(item => item.toLowerCase().includes(query))
})

const selectSuggestion = (suggestion) => {
  location.value = suggestion
  showSuggestions.value = false
}

const hideSuggestionsWithDelay = () => {
  setTimeout(() => {
    showSuggestions.value = false
  }, 200)
}

const showWomenOnlyToggle = computed(() => {
  return store.state.currentUser?.gender === 'female'
})

const submitForm = async () => {
  if (!title.value.trim()) {
    formError.value = t('enterMatchTitle')
    return
  }
  if (!dateTime.value) {
    formError.value = t('chooseDateAndTime')
    return
  }
  
  const selectedDate = new Date(dateTime.value.replace('T', ' '))
  if (selectedDate < new Date()) {
    formError.value = t('futureDateError')
    return
  }

  if (!location.value.trim()) {
    formError.value = t('enterCourtLocation')
    return
  }
  const slotsNum = parseInt(slots.value)
  if (isNaN(slotsNum) || slotsNum <= 0) {
    formError.value = t('specifyValidSlots')
    return
  }
  
  formError.value = ''
  isSubmitting.value = true
  
  try {
    const maxSlots = slotsNum + 1 // including creator
    const created = await store.createMatch(
      selectedSport.value,
      title.value.trim(),
      dateTime.value,
      location.value.trim(),
      maxSlots,
      selectedSkill.value,
      150, // default flat price
      womenOnly.value
    )
    
    isSubmitting.value = false
    if (created) {
      emit('match-created', `Created match "${created.title}" successfully! ⚽`)
      closeModal()
    } else {
      formError.value = t('failedCreateMatch')
    }
  } catch (e) {
    formError.value = e.message || 'Failed to create match'
    isSubmitting.value = false
  }
}

const closeModal = () => {
  // Reset values
  title.value = ''
  dateTime.value = getDefaultDateTime()
  location.value = ''
  slots.value = ''
  selectedSport.value = 'Football'
  selectedSkill.value = 'Intermediate'
  womenOnly.value = false
  formError.value = ''
  emit('close')
}
</script>

<template>
  <div v-if="show" class="modal-backdrop" @click="closeModal">
    <div class="modal-sheet animate-slide-up" @click.stop>
      <!-- Sheet header -->
      <div class="modal-header">
        <h2 class="modal-title">{{ t('createNewMatch') }}</h2>
        <button class="close-btn" @click="closeModal">✕</button>
      </div>

      <!-- Scrollable Form body -->
      <div class="modal-body scrollable-y">
        <div v-if="formError" class="error-banner">{{ formError }}</div>

        <!-- Sport selection -->
        <div class="input-group">
          <label class="input-label">{{ t('sportType') }}</label>
          <div class="sport-select-grid">
            <button 
              v-for="sport in sports" 
              :key="sport"
              type="button"
              class="sport-chip"
              :class="{ active: selectedSport === sport }"
              @click="selectedSport = sport"
            >
              {{ sport }}
            </button>
          </div>
        </div>

        <!-- Title -->
        <div class="input-group">
          <label class="input-label">{{ t('matchTitle') }}</label>
          <input 
            v-model="title"
            type="text" 
            placeholder="e.g. Friday Evening 5v5"
            class="form-input"
          />
        </div>

        <!-- Date & Time -->
        <div class="input-group">
          <label class="input-label">{{ t('dateAndTime') }}</label>
          <input 
            v-model="dateTime"
            type="datetime-local" 
            :min="minDateTime"
            class="form-input"
          />
        </div>

        <!-- Location -->
        <div class="input-group location-group">
          <label class="input-label">{{ t('location') }}</label>
          <input 
            v-model="location"
            type="text" 
            placeholder="e.g. Central Park Court 2"
            class="form-input"
            @focus="showSuggestions = true"
            @blur="hideSuggestionsWithDelay"
          />
          <!-- Suggestions Dropdown -->
          <ul v-if="showSuggestions && filteredSuggestions.length" class="suggestions-list">
            <li 
              v-for="suggestion in filteredSuggestions" 
              :key="suggestion"
              class="suggestion-item"
              @mousedown="selectSuggestion(suggestion)"
            >
              📍 {{ suggestion }}
            </li>
          </ul>
        </div>

        <!-- Row slots and skill -->
        <div class="form-row">
          <div class="input-group half">
            <label class="input-label">{{ t('availableSlots') }}</label>
            <input 
              v-model="slots"
              type="number" 
              placeholder="e.g. 10"
              class="form-input"
            />
          </div>
          <div class="input-group half">
            <label class="input-label">{{ t('skillLevel') }}</label>
            <select v-model="selectedSkill" class="form-select">
              <option v-for="skill in skills" :key="skill" :value="skill">
                {{ skill }}
              </option>
            </select>
          </div>
        </div>

        <!-- Women-Only Switch -->
        <div v-if="showWomenOnlyToggle" class="switch-tile" :class="{ active: womenOnly }">
          <div class="switch-info">
            <span class="switch-title">🌸 {{ t('womenOnlyMatch') }}</span>
            <span class="switch-desc">
              {{ womenOnly ? t('onlyFemaleCanJoin') : t('enableRestrictWomen') }}
            </span>
          </div>
          <label class="toggle-control">
            <input v-model="womenOnly" type="checkbox" />
            <span class="toggle-slider"></span>
          </label>
        </div>

        <!-- Submit btn -->
        <button class="submit-btn" :disabled="isSubmitting" @click="submitForm">
          <span v-if="isSubmitting" class="loader"></span>
          <span v-else>{{ t('createMatch') }}</span>
        </button>
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
  max-height: 85%;
  background-color: var(--surface);
  border-top-left-radius: var(--radius-xl);
  border-top-right-radius: var(--radius-xl);
  display: flex;
  flex-direction: column;
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
  padding: 20px 24px;
  border-bottom: 1px solid var(--outline-variant);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.modal-title {
  font-size: 1.25rem;
  font-weight: 700;
  color: var(--primary);
}

.close-btn {
  background: none;
  border: none;
  font-size: 1.2rem;
  color: var(--outline);
  cursor: pointer;
}

.modal-body {
  padding: 24px;
  flex: 1;
}

.error-banner {
  background-color: rgba(186, 26, 26, 0.1);
  color: var(--error);
  padding: 12px;
  border-radius: var(--radius-sm);
  font-size: 0.8rem;
  font-weight: 600;
  margin-bottom: 16px;
  border: 1px solid rgba(186, 26, 26, 0.2);
}

.input-group {
  margin-bottom: 20px;
  display: flex;
  flex-direction: column;
}

.input-label {
  font-size: 0.85rem;
  font-weight: 700;
  color: var(--on-surface-variant);
  margin-bottom: 8px;
  padding-left: 2px;
}

.form-input, .form-select {
  width: 100%;
  padding: 12px 16px;
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  font-size: 0.95rem;
  color: var(--on-surface);
  outline: none;
  transition: border-color 0.2s ease;
}

.form-input:focus, .form-select:focus {
  border-color: var(--primary);
}

.sport-select-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
}

.sport-chip {
  padding: 10px 4px;
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  background-color: var(--surface);
  font-size: 0.78rem;
  font-weight: 700;
  color: var(--on-surface-variant);
  cursor: pointer;
  text-align: center;
  transition: all 0.2s ease;
}

.sport-chip.active {
  background-color: var(--primary-container);
  color: var(--on-primary-container);
  border-color: var(--primary);
}

.form-row {
  display: flex;
  gap: 16px;
}

.form-row .half {
  flex: 1;
}

/* Switch card tile */
.switch-tile {
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  padding: 16px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 28px;
  transition: all 0.3s ease;
}

.switch-tile.active {
  border-color: var(--primary);
  background: linear-gradient(135deg, rgba(255, 77, 141, 0.08) 0%, rgba(123, 97, 255, 0.04) 100%);
}

.switch-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.switch-title {
  font-size: 0.9rem;
  font-weight: 700;
  color: var(--on-surface);
}

.switch-desc {
  font-size: 0.72rem;
  color: var(--on-surface-variant);
}

.switch-tile.active .switch-desc {
  color: var(--primary);
}

/* Custom toggler styling */
.toggle-control {
  position: relative;
  display: inline-block;
  width: 44px;
  height: 24px;
}

.toggle-control input {
  opacity: 0;
  width: 0;
  height: 0;
}

.toggle-slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: var(--outline-variant);
  transition: .3s;
  border-radius: 24px;
}

.toggle-slider:before {
  position: absolute;
  content: "";
  height: 18px;
  width: 18px;
  left: 3px;
  bottom: 3px;
  background-color: white;
  transition: .3s;
  border-radius: 50%;
}

input:checked + .toggle-slider {
  background-color: var(--primary);
}

input:checked + .toggle-slider:before {
  transform: translateX(20px);
}

.submit-btn {
  width: 100%;
  background-color: var(--primary);
  color: var(--on-primary);
  border: none;
  border-radius: var(--radius-md);
  padding: 16px;
  font-size: 1rem;
  font-weight: 700;
  cursor: pointer;
  display: flex;
  justify-content: center;
  align-items: center;
  margin-top: 10px;
}

.submit-btn:hover {
  filter: brightness(1.1);
}

.loader {
  width: 20px;
  height: 20px;
  border: 2px solid var(--on-primary);
  border-bottom-color: transparent;
  border-radius: 50%;
  animation: rotation 1s linear infinite;
}

@keyframes rotation {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* Location suggestions dropdown */
.location-group {
  position: relative;
}

.suggestions-list {
  position: absolute;
  top: calc(100% - 10px);
  left: 0;
  width: 100%;
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-lg);
  z-index: 100;
  list-style: none;
  padding: 8px 0;
  margin: 0;
  max-height: 280px;
  overflow-y: auto;
  text-align: left;
}

.suggestions-list::-webkit-scrollbar {
  width: 5px;
}

.suggestions-list::-webkit-scrollbar-track {
  background: transparent;
}

.suggestions-list::-webkit-scrollbar-thumb {
  background: var(--outline-variant);
  border-radius: 10px;
}

.suggestion-item {
  padding: 12px 16px;
  font-size: 0.88rem;
  color: var(--on-surface);
  cursor: pointer;
  transition: background-color 0.2s ease, color 0.2s ease;
}

.suggestion-item:hover {
  background-color: var(--surface-dim);
  color: var(--primary);
}
</style>
