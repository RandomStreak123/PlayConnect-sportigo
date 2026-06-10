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

// Custom Date-Time Picker States
const showCustomPicker = ref(false)
const tempYear = ref(new Date().getFullYear())
const tempMonth = ref(new Date().getMonth())

const selectedDay = ref(new Date().getDate())
const selectedMonth = ref(new Date().getMonth())
const selectedYear = ref(new Date().getFullYear())

const selectedHour = ref(5)
const selectedMinute = ref(2)
const selectedPeriod = ref('PM')

// Format helper to display selected datetime on the main input trigger
const formatDisplayDateTime = (dtStr) => {
  if (!dtStr) return t('chooseDateAndTime')
  try {
    const dt = new Date(dtStr.replace('T', ' '))
    if (isNaN(dt.getTime())) return dtStr
    
    const day = String(dt.getDate()).padStart(2, '0')
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    const month = monthNames[dt.getMonth()]
    const year = dt.getFullYear()
    
    let hours = dt.getHours()
    const minutes = String(dt.getMinutes()).padStart(2, '0')
    const ampm = hours >= 12 ? 'PM' : 'AM'
    hours = hours % 12
    hours = hours ? hours : 12
    const hrStr = String(hours).padStart(2, '0')
    
    return `${day} ${month} ${year}, ${hrStr}:${minutes} ${ampm}`
  } catch (e) {
    return dtStr
  }
}

// Open custom date-time picker
const openCustomPicker = () => {
  try {
    if (dateTime.value) {
      const currentVal = new Date(dateTime.value.replace('T', ' '))
      if (!isNaN(currentVal.getTime())) {
        selectedDay.value = currentVal.getDate()
        selectedMonth.value = currentVal.getMonth()
        selectedYear.value = currentVal.getFullYear()
        
        tempMonth.value = currentVal.getMonth()
        tempYear.value = currentVal.getFullYear()
        
        let hrs = currentVal.getHours()
        selectedPeriod.value = hrs >= 12 ? 'PM' : 'AM'
        hrs = hrs % 12
        selectedHour.value = hrs ? hrs : 12
        selectedMinute.value = currentVal.getMinutes()
      }
    }
  } catch (e) { /* fallback to now */ }
  showCustomPicker.value = true
}

const prevMonth = () => {
  if (tempMonth.value === 0) {
    tempMonth.value = 11
    tempYear.value--
  } else {
    tempMonth.value--
  }
}

const nextMonth = () => {
  if (tempMonth.value === 11) {
    tempMonth.value = 0
    tempYear.value++
  } else {
    tempMonth.value++
  }
}

const selectDate = (dayItem) => {
  if (dayItem.day && !dayItem.isPast) {
    selectedDay.value = dayItem.day
    selectedMonth.value = tempMonth.value
    selectedYear.value = tempYear.value
  }
}

const selectPeriod = (p) => {
  selectedPeriod.value = p
}

const sanitizeMinutes = () => {
  let val = parseInt(selectedMinute.value)
  if (isNaN(val) || val < 0) val = 0
  if (val > 59) val = 59
  selectedMinute.value = val
}

const saveCustomDateTime = () => {
  sanitizeMinutes()
  let hr = selectedHour.value
  if (selectedPeriod.value === 'PM' && hr < 12) hr += 12
  if (selectedPeriod.value === 'AM' && hr === 12) hr = 0
  
  const monthStr = String(selectedMonth.value + 1).padStart(2, '0')
  const dayStr = String(selectedDay.value).padStart(2, '0')
  const hrStr = String(hr).padStart(2, '0')
  const minStr = String(selectedMinute.value).padStart(2, '0')
  
  dateTime.value = `${selectedYear.value}-${monthStr}-${dayStr}T${hrStr}:${minStr}`
  showCustomPicker.value = false
}

const getMonthYearLabel = computed(() => {
  const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
  return `${months[tempMonth.value]}, ${tempYear.value}`
})

const daysOfWeek = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']

const calendarDays = computed(() => {
  const year = tempYear.value
  const month = tempMonth.value
  
  const firstDayOfWeek = new Date(year, month, 1).getDay()
  const totalDays = new Date(year, month + 1, 0).getDate()
  
  const days = []
  
  // Padding
  for (let i = 0; i < firstDayOfWeek; i++) {
    days.push({ day: null, isPast: true })
  }
  
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  
  for (let d = 1; d <= totalDays; d++) {
    const dateObj = new Date(year, month, d)
    dateObj.setHours(0, 0, 0, 0)
    const isPast = dateObj < today
    const isSelected = d === selectedDay.value && month === selectedMonth.value && year === selectedYear.value
    
    days.push({
      day: d,
      isPast,
      isSelected
    })
  }
  
  return days
})

const getClockNumberStyle = (h) => {
  const angle = (h * 30 - 90) * (Math.PI / 180)
  const radius = 72
  const x = Math.round(90 + radius * Math.cos(angle) - 13)
  const y = Math.round(90 + radius * Math.sin(angle) - 13)
  return {
    left: `${x}px`,
    top: `${y}px`
  }
}

const clockHandStyle = computed(() => {
  const angle = selectedHour.value * 30
  return {
    transform: `rotate(${angle}deg)`
  }
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

        <!-- Date & Time Trigger -->
        <div class="input-group">
          <label class="input-label">{{ t('dateAndTime') }}</label>
          <div class="custom-datetime-trigger" @click="openCustomPicker">
            <span>📅 {{ formatDisplayDateTime(dateTime) }}</span>
          </div>
          <!-- Hidden fallback input for standard E2E compatibility -->
          <input 
            v-model="dateTime"
            type="datetime-local" 
            :min="minDateTime"
            style="opacity: 0; position: absolute; z-index: -1; width: 0; height: 0; pointer-events: none;"
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

  <!-- Custom Date Time Picker Modal -->
  <Teleport to="body">
    <div v-if="showCustomPicker" class="custom-picker-backdrop" :class="{ 'theme-women': store.isWomenMode.value }" @click="showCustomPicker = false">
      <div class="custom-picker-dialog animate-scale-up" @click.stop>
        <div class="picker-header-title">Select Date & Time</div>
        
        <!-- Selected Time Header Visual Display (Matches mockup) -->
        <div class="time-header-row">
          <div class="time-box hour-box active-picker-bg">
            {{ String(selectedHour).padStart(2, '0') }}
          </div>
          <div class="time-separator">:</div>
          <div class="time-box minute-box">
            <input 
              type="number" 
              v-model="selectedMinute" 
              min="0" 
              max="59" 
              class="time-header-input"
              @blur="sanitizeMinutes"
            />
          </div>
          <div class="ampm-vertical-stack">
            <button 
              class="ampm-btn" 
              :class="{ active: selectedPeriod === 'AM' }"
              @click="selectPeriod('AM')"
            >
              AM
            </button>
            <button 
              class="ampm-btn" 
              :class="{ active: selectedPeriod === 'PM' }"
              @click="selectPeriod('PM')"
            >
              PM
            </button>
          </div>
        </div>
        
        <!-- Picker Body content split -->
        <div class="picker-split-body">
          <!-- Calendar part -->
          <div class="picker-calendar-pane">
            <div class="calendar-month-nav">
              <button class="nav-arrow" @click="prevMonth">◀</button>
              <span class="month-lbl">{{ getMonthYearLabel }}</span>
              <button class="nav-arrow" @click="nextMonth">▶</button>
            </div>
            
            <div class="calendar-weekdays">
              <span v-for="day in daysOfWeek" :key="day" class="weekday-item">{{ day }}</span>
            </div>
            
            <div class="calendar-days-grid">
              <div 
                v-for="(dayItem, idx) in calendarDays" 
                :key="idx"
                class="day-grid-cell"
                :class="{ 
                  empty: !dayItem.day, 
                  past: dayItem.isPast, 
                  selected: dayItem.isSelected 
                }"
                @click="selectDate(dayItem)"
              >
                <span v-if="dayItem.day" class="day-number">{{ dayItem.day }}</span>
              </div>
            </div>
          </div>
          
          <!-- Clock part -->
          <div class="picker-clock-pane">
            <div class="clock-title">Select Hour</div>
            <div class="clock-face">
              <div class="clock-center-dot"></div>
              <div class="clock-hand" :style="clockHandStyle"></div>
              
              <div 
                v-for="h in 12" 
                :key="h" 
                class="clock-number"
                :class="{ active: selectedHour === h }"
                :style="getClockNumberStyle(h)"
                @click="selectedHour = h"
              >
                {{ h }}
              </div>
            </div>
          </div>
        </div>
        
        <!-- Dialog Footer Actions -->
        <div class="picker-footer-actions">
          <button class="picker-action-btn cancel" @click="showCustomPicker = false">Cancel</button>
          <button class="picker-action-btn ok" @click="saveCustomDateTime">OK</button>
        </div>
      </div>
    </div>
  </Teleport>
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

/* Custom Date-Time Picker Layout */
.custom-datetime-trigger {
  width: 100%;
  padding: 12px 16px;
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  font-size: 0.95rem;
  color: var(--on-surface);
  cursor: pointer;
  display: flex;
  align-items: center;
  transition: border-color 0.2s ease;
}

.custom-datetime-trigger:hover {
  border-color: var(--primary);
}

.custom-picker-backdrop {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(15, 23, 42, 0.45);
  backdrop-filter: blur(4px);
  z-index: 2000;
  display: flex;
  justify-content: center;
  align-items: center;
}

.custom-picker-dialog {
  width: 95%;
  max-width: 520px;
  background-color: var(--surface);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-lg);
  padding: 24px;
  display: flex;
  flex-direction: column;
  animation: scaleUp 0.2s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

@keyframes scaleUp {
  from { transform: scale(0.95); opacity: 0; }
  to { transform: scale(1); opacity: 1; }
}

.picker-header-title {
  font-family: var(--font-display);
  font-size: 1.1rem;
  font-weight: 700;
  color: var(--on-surface-variant);
  margin-bottom: 12px;
  text-align: center;
}

/* Time Selection Header (matches mockup) */
.time-header-row {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 12px;
  margin-bottom: 24px;
}

.time-box {
  width: 72px;
  height: 56px;
  border-radius: var(--radius-sm);
  background-color: var(--surface-dim);
  border: 1px solid var(--outline-variant);
  display: flex;
  justify-content: center;
  align-items: center;
  font-family: var(--font-display);
  font-size: 1.8rem;
  font-weight: 700;
  color: var(--on-surface);
}

.time-box.hour-box.active-picker-bg {
  background-color: var(--picker-accent);
  border-color: var(--picker-accent);
  color: #ffffff;
}

.time-separator {
  font-family: var(--font-display);
  font-size: 1.8rem;
  font-weight: 700;
  color: var(--on-surface-variant);
}

.time-header-input {
  width: 100%;
  height: 100%;
  background: transparent;
  border: none;
  text-align: center;
  font-family: inherit;
  font-size: inherit;
  font-weight: inherit;
  color: inherit;
  outline: none;
}

/* Remove spin arrows from number input */
.time-header-input::-webkit-outer-spin-button,
.time-header-input::-webkit-inner-spin-button {
  -webkit-appearance: none;
  margin: 0;
}
.time-header-input[type=number] {
  -moz-appearance: textfield;
}

.ampm-vertical-stack {
  display: flex;
  flex-direction: column;
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-sm);
  overflow: hidden;
}

.ampm-btn {
  border: none;
  background: var(--surface-dim);
  padding: 6px 12px;
  font-size: 0.8rem;
  font-weight: 700;
  color: var(--on-surface-variant);
  cursor: pointer;
  transition: all 0.2s;
}

.ampm-btn:first-child {
  border-bottom: 1px solid var(--outline-variant);
}

.ampm-btn.active {
  background-color: var(--picker-accent);
  color: #ffffff;
}

/* Split Pane: Left Calendar, Right Clock */
.picker-split-body {
  display: flex;
  gap: 20px;
  border-top: 1px solid var(--outline-variant);
  border-bottom: 1px solid var(--outline-variant);
  padding: 20px 0;
}

@media (max-width: 480px) {
  .picker-split-body {
    flex-direction: column;
    align-items: center;
    gap: 16px;
  }
}

.picker-calendar-pane {
  flex: 1.2;
}

.picker-clock-pane {
  flex: 0.8;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  border-left: 1px solid var(--outline-variant);
  padding-left: 20px;
}

@media (max-width: 480px) {
  .picker-clock-pane {
    border-left: none;
    border-top: 1px solid var(--outline-variant);
    padding-left: 0;
    padding-top: 16px;
    width: 100%;
  }
}

.calendar-month-nav {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.nav-arrow {
  background: none;
  border: none;
  cursor: pointer;
  color: var(--picker-accent);
  font-size: 0.9rem;
  padding: 4px 8px;
}

.month-lbl {
  font-weight: 700;
  font-size: 0.9rem;
  color: var(--on-surface);
}

.calendar-weekdays {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  text-align: center;
  margin-bottom: 8px;
}

.weekday-item {
  font-size: 0.72rem;
  font-weight: 700;
  color: var(--outline);
}

.calendar-days-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 4px;
}

.day-grid-cell {
  aspect-ratio: 1;
  display: flex;
  justify-content: center;
  align-items: center;
  cursor: pointer;
  border-radius: 50%;
  font-size: 0.82rem;
  font-weight: 600;
  color: var(--on-surface);
  transition: all 0.2s;
}

.day-grid-cell:hover:not(.empty):not(.past) {
  background-color: var(--surface-dim);
}

.day-grid-cell.past {
  color: var(--outline-variant);
  cursor: not-allowed;
}

.day-grid-cell.empty {
  cursor: default;
}

.day-grid-cell.selected {
  background-color: var(--picker-accent) !important;
  color: #ffffff !important;
}

/* Clock styling */
.clock-title {
  font-size: 0.75rem;
  font-weight: 700;
  color: var(--outline);
  text-transform: uppercase;
  margin-bottom: 12px;
}

.clock-face {
  width: 180px;
  height: 180px;
  border-radius: 50%;
  background-color: var(--surface-dim);
  position: relative;
  box-shadow: inset 0 2px 5px rgba(0,0,0,0.05);
}

.clock-center-dot {
  position: absolute;
  top: calc(50% - 4px);
  left: calc(50% - 4px);
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: var(--picker-accent);
}

.clock-hand {
  position: absolute;
  width: 2px;
  background-color: var(--picker-accent);
  bottom: 50%;
  left: calc(50% - 1px);
  transform-origin: bottom center;
  height: 72px;
  transition: transform 0.2s cubic-bezier(0.175, 0.885, 0.32, 1.275);
}

.clock-hand::after {
  content: '';
  position: absolute;
  top: -13px;
  left: -13px;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background-color: var(--picker-accent);
  box-shadow: 0 2px 6px rgba(0,0,0,0.15);
}

.clock-number {
  position: absolute;
  width: 26px;
  height: 26px;
  display: flex;
  justify-content: center;
  align-items: center;
  font-family: var(--font-display);
  font-size: 0.82rem;
  font-weight: 700;
  color: var(--on-surface-variant);
  cursor: pointer;
  border-radius: 50%;
  user-select: none;
  z-index: 10;
  transition: color 0.15s;
}

.clock-number.active {
  color: #ffffff;
}

.picker-footer-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 20px;
}

.picker-action-btn {
  background: none;
  border: none;
  padding: 8px 16px;
  font-weight: 700;
  font-size: 0.9rem;
  color: var(--picker-accent);
  cursor: pointer;
  border-radius: var(--radius-sm);
  transition: background-color 0.2s;
}

.picker-action-btn:hover {
  background-color: var(--surface-dim);
}
</style>
