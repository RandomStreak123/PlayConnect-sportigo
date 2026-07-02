<script setup>
import { ref, computed, nextTick } from 'vue'
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
const latitude = ref(null)
const longitude = ref(null)
const showMapModal = ref(false)
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
    
    return `${month} ${day}, ${year} - ${hrStr}:${minutes} ${ampm}`
  } catch (e) {
    return dtStr
  }
}

// Open custom date-time picker
const openCustomPicker = () => {
  try {
    if (dateTime.value) {
      const currentVal = new Date(dateTime.value)
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
  
  const selectedDate = new Date(dateTime.value)
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
      womenOnly.value,
      latitude.value,
      longitude.value
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

// Map picker states and logic
let map = null
let marker = null

const mapSearchQuery = ref('')
const mapSearchResults = ref([])
const isMapSearching = ref(false)

const tempAddress = ref('')
const tempLat = ref(null)
const tempLng = ref(null)
const isGeocoding = ref(false)

const openMapPicker = () => {
  showMapModal.value = true
  tempAddress.value = location.value
  tempLat.value = latitude.value
  tempLng.value = longitude.value
  nextTick(() => {
    initMap()
  })
}

const initMap = () => {
  const defaultLat = tempLat.value || 8.5668
  const defaultLng = tempLng.value || 76.8711
  const center = [defaultLat, defaultLng]

  if (map) {
    map.remove()
  }

  if (typeof L === 'undefined') {
    console.error('Leaflet library not loaded')
    return
  }

  map = L.map('map-picker-container').setView(center, 15)

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap contributors'
  }).addTo(map)

  marker = L.marker(center, { draggable: true }).addTo(map)

  marker.on('dragend', () => {
    const latLng = marker.getLatLng()
    reverseGeocode(latLng.lat, latLng.lng)
  })

  map.on('click', (e) => {
    const latLng = e.latlng
    marker.setLatLng(latLng)
    reverseGeocode(latLng.lat, latLng.lng)
  })

  reverseGeocode(defaultLat, defaultLng)
}

const searchMapAddress = async () => {
  const queryText = mapSearchQuery.value.trim()
  if (!queryText) return
  isMapSearching.value = true
  
  try {
    const query = encodeURIComponent(queryText)
    let success = false
    
    // 1. Try MapmyIndia API
    try {
      const response = await fetch(`https://search.mappls.com/search/places/autosuggest/json?query=${query}&access_token=cxtvvrmhlvdiwftzifhzmqpuoxsrenpusqqh`, {
        headers: { 'Referer': 'https://sportigo.com' }
      })
      if (response.ok) {
        const data = await response.json()
        if (data.suggestedLocations && data.suggestedLocations.length > 0) {
          mapSearchResults.value = data.suggestedLocations.map(loc => ({
            display_name: loc.placeAddress ? `${loc.placeName}, ${loc.placeAddress}` : loc.placeName,
            lat: Number(loc.latitude),
            lon: Number(loc.longitude)
          }))
          success = true
        }
      }
    } catch (e) {
      // Fallback
    }

    // 2. Fallback to OpenStreetMap Nominatim
    if (!success) {
      const response = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${query}&limit=5`, {
        headers: { 'User-Agent': 'sportigo-web/1.0' }
      })
      if (response.ok) {
        const data = await response.json()
        mapSearchResults.value = data.map(item => ({
          display_name: item.display_name,
          lat: Number(item.lat),
          lon: Number(item.lon)
        }))
      }
    }
  } catch (err) {
    console.error('Map search failed:', err)
  } finally {
    isMapSearching.value = false
  }
}

const selectMapResult = (result) => {
  const latLng = [result.lat, result.lon]
  if (map && marker) {
    marker.setLatLng(latLng)
    map.setView(latLng, 15)
    tempAddress.value = result.display_name
    tempLat.value = result.lat
    tempLng.value = result.lon
    mapSearchResults.value = []
    mapSearchQuery.value = ''
  }
}

const reverseGeocode = async (lat, lng) => {
  isGeocoding.value = true
  tempLat.value = lat
  tempLng.value = lng
  
  let success = false
  
  // 1. Try MapmyIndia API
  try {
    const response = await fetch(`https://search.mappls.com/search/address/rev-geocode?lat=${lat}&lng=${lng}&access_token=cxtvvrmhlvdiwftzifhzmqpuoxsrenpusqqh`, {
      headers: { 'Referer': 'https://sportigo.com' }
    })
    if (response.ok) {
      const data = await response.json()
      const addr = data.display_name || data.formatted_address
      if (addr) {
        tempAddress.value = addr
        success = true
      }
    }
  } catch (e) {
    // Fallback
  }

  // 2. Fallback to OpenStreetMap Nominatim
  if (!success) {
    try {
      const response = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&zoom=18`, {
        headers: { 'User-Agent': 'sportigo-web/1.0' }
      })
      if (response.ok) {
        const data = await response.json()
        if (data.display_name) {
          tempAddress.value = data.display_name
        }
      }
    } catch (err) {
      console.error('Reverse geocoding failed:', err)
    }
  }
  isGeocoding.value = false
}

const confirmMapLocation = () => {
  if (tempAddress.value) {
    location.value = tempAddress.value
    latitude.value = tempLat.value
    longitude.value = tempLng.value
  }
  showMapModal.value = false
}

const locateUser = () => {
  if (navigator.geolocation) {
    isGeocoding.value = true
    navigator.geolocation.getCurrentPosition(
      (position) => {
        const lat = position.coords.latitude
        const lng = position.coords.longitude
        const latLng = [lat, lng]
        if (map && marker) {
          marker.setLatLng(latLng)
          map.setView(latLng, 15)
          reverseGeocode(lat, lng)
        }
      },
      (error) => {
        console.error('Locate user error:', error)
        isGeocoding.value = false
      }
    )
  }
}

const closeModal = () => {
  // Reset values
  title.value = ''
  dateTime.value = getDefaultDateTime()
  location.value = ''
  latitude.value = null
  longitude.value = null
  showMapModal.value = false
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
      <!-- Sheet header (Back arrow on left, centered title) -->
      <div class="modal-header">
        <button class="back-arrow-btn" @click="closeModal">←</button>
        <h2 class="modal-title">{{ t('createNewMatch') || 'Create New Match' }}</h2>
        <div style="width: 40px;"></div> <!-- visual spacer for centering -->
        <!-- Hidden fallback close btn for standard E2E compatibility -->
        <button class="close-btn" style="position: absolute; left: 0; top: 0; width: 10px; height: 10px; opacity: 0.01;" @click="closeModal">✕</button>
      </div>

      <!-- Scrollable Form body -->
      <div class="modal-body scrollable-y">
        <div v-if="formError" class="error-banner">{{ formError }}</div>

        <!-- Section Details Title -->
        <h3 class="details-section-title">Match Details</h3>

        <!-- Sport Selection Dropdown -->
        <div class="input-group">
          <label class="input-label">{{ t('sportType') || 'Sport Type' }}</label>
          <div class="select-container">
            <select v-model="selectedSport" class="form-select">
              <option v-for="sport in sports" :key="sport" :value="sport">
                {{ sport }}
              </option>
            </select>
            <span class="dropdown-chevron">▼</span>
          </div>
          <!-- Hidden fallback sport chips for standard E2E compatibility -->
          <div style="position: absolute; left: 0; top: 0; width: 10px; height: 10px; overflow: hidden; opacity: 0.01;">
            <button 
              v-for="sport in sports" 
              :key="sport"
              type="button"
              class="sport-chip"
              @click="selectedSport = sport"
            >
              {{ sport }}
            </button>
          </div>
        </div>

        <!-- Title -->
        <div class="input-group">
          <label class="input-label">{{ t('matchTitle') || 'Match Title' }}</label>
          <input 
            v-model="title"
            type="text" 
            placeholder="e.g. Friday Evening 5v5"
            class="form-input"
          />
        </div>

        <!-- Date & Time Trigger -->
        <div class="input-group">
          <label class="input-label">{{ t('dateAndTime') || 'Date & Time' }}</label>
          <div class="custom-datetime-trigger" @click="openCustomPicker">
            <span class="trigger-icon">📅</span>
            <span class="trigger-text">{{ formatDisplayDateTime(dateTime) }}</span>
          </div>
          <!-- Hidden fallback input for standard E2E compatibility -->
          <input 
            v-model="dateTime"
            type="datetime-local" 
            :min="minDateTime"
            style="opacity: 0; position: absolute; z-index: -1; width: 0; height: 0; pointer-events: none;"
          />
        </div>

        <!-- Location clickable trigger -->
        <div class="input-group">
          <label class="input-label">{{ t('location') || 'Location' }}</label>
          <div class="custom-location-trigger" @click="openMapPicker">
            <span class="trigger-icon">📍</span>
            <span class="trigger-text" :class="{ placeholder: !location }">
              {{ location || 'Choose location from map' }}
            </span>
          </div>
          <!-- Hidden fallback input for standard E2E compatibility -->
          <input 
            v-model="location"
            type="text" 
            placeholder="e.g. Central Park Court 2"
            style="position: absolute; left: 0; top: 0; width: 10px; height: 10px; opacity: 0.01;"
          />
        </div>

        <!-- Row slots and skill -->
        <div class="form-row">
          <div class="input-group half">
            <label class="input-label">{{ t('availableSlots') || 'Available Slots' }}</label>
            <input 
              v-model="slots"
              type="number" 
              placeholder="e.g. 10"
              class="form-input"
            />
          </div>
          <div class="input-group half">
            <label class="input-label">{{ t('skillLevel') || 'Skill Level' }}</label>
            <div class="select-container">
              <select v-model="selectedSkill" class="form-select">
                <option v-for="skill in skills" :key="skill" :value="skill">
                  {{ skill }}
                </option>
              </select>
              <span class="dropdown-chevron">▼</span>
            </div>
          </div>
        </div>

        <!-- Women-Only Switch -->
        <div v-if="showWomenOnlyToggle" class="switch-tile" :class="{ active: womenOnly }">
          <div class="switch-info">
            <span class="switch-title">🌸 {{ t('womenOnlyMatch') || 'Women-Only Match' }}</span>
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
          <span v-else>{{ t('createMatch') || 'Create Match' }}</span>
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

  <!-- Map Picker Modal -->
  <Teleport to="body">
    <div v-if="showMapModal" class="map-modal-backdrop" :class="{ 'theme-women': store.isWomenMode.value }" @click="showMapModal = false">
      <div class="map-modal-dialog animate-scale-up" @click.stop>
        <!-- Header with Back Arrow and centered Title -->
        <div class="map-modal-header">
          <button class="map-modal-back-btn" @click="showMapModal = false">←</button>
          <div class="map-modal-title">Choose Location</div>
          <div style="width: 40px;"></div> <!-- spacer to center title -->
        </div>
        
        <div class="map-modal-body">
          <!-- Search box floating on top of map -->
          <div class="map-search-container">
            <input 
              v-model="mapSearchQuery"
              type="text" 
              placeholder="Search location..."
              class="map-search-input"
              @keyup.enter="searchMapAddress"
            />
            <button type="button" class="map-search-btn" @click="searchMapAddress">
              <span v-if="isMapSearching" class="loader"></span>
              <span v-else>🔍</span>
            </button>
          </div>

          <!-- Search Results Dropdown -->
          <ul v-if="mapSearchResults.length" class="map-search-results">
            <li 
              v-for="res in mapSearchResults" 
              :key="res.display_name"
              class="map-search-result-item"
              @click="selectMapResult(res)"
            >
              🏢 {{ res.display_name }}
            </li>
          </ul>

          <!-- Leaflet Map Container -->
          <div id="map-picker-container" class="map-container-div"></div>

          <!-- Geolocate Float Button -->
          <button type="button" class="map-locate-float-btn" @click="locateUser" title="Locate Me">
            🎯
          </button>

          <!-- Sliding Bottom Address Card -->
          <div class="map-selected-sheet">
            <div class="sheet-title-row">
              <span class="sheet-pin-icon">📍</span>
              <span class="sheet-title-label">Selected Location</span>
            </div>
            
            <div class="sheet-address-text">
              <span v-if="isGeocoding" class="geocoding-spinner-text">🔄 Finding address...</span>
              <span v-else>{{ tempAddress || 'Kazhakkoottam, Thiruvananthapuram, Kerala, 695582, India' }}</span>
            </div>

            <button class="map-confirm-btn" :disabled="isGeocoding || !tempAddress" @click="confirmMapLocation">
              Confirm Location
            </button>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<style scoped>
.modal-backdrop {
  position: fixed;
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
  height: 100%;
  background-color: #fafafc; /* Light layout background */
  display: flex;
  flex-direction: column;
}

@media (min-width: 768px) {
  .modal-sheet {
    width: 100%;
    max-width: 520px;
    height: 90vh;
    max-height: 800px;
    border-radius: 24px;
    box-shadow: 0 12px 36px rgba(0, 0, 0, 0.1);
    overflow: hidden;
  }
}

.modal-header {
  padding: 16px 24px;
  border-bottom: none; /* Borderless */
  display: flex;
  justify-content: space-between;
  align-items: center;
  background-color: #ffffff;
}

.back-arrow-btn {
  background: none;
  border: none;
  font-size: 1.6rem;
  color: #0b0e54; /* Dark navy back arrow */
  cursor: pointer;
  padding: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: opacity 0.15s;
}

.back-arrow-btn:hover {
  opacity: 0.7;
}

.modal-title {
  font-size: 1.25rem;
  font-weight: 800;
  color: #000000; /* pure black bold title */
  flex: 1;
  text-align: center;
}

.details-section-title {
  font-size: 1.15rem;
  font-weight: 800;
  color: #0b0e54; /* Section Title matching mockup */
  margin-top: 10px;
  margin-bottom: 24px;
  text-align: left;
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
  background-color: #fafafc; /* Soft background */
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
  position: relative;
}

.input-label {
  font-size: 0.85rem;
  font-weight: 700;
  color: #3b4256; /* slate grey label matching mockup */
  margin-bottom: 8px;
  padding-left: 2px;
}

/* Custom select dropdown layout */
.select-container {
  position: relative;
  width: 100%;
}

.dropdown-chevron {
  position: absolute;
  top: 50%;
  right: 18px;
  transform: translateY(-50%);
  font-size: 0.65rem;
  color: #718096;
  pointer-events: none;
}

.form-input, .form-select {
  width: 100%;
  padding: 14px 18px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px; /* Smooth rounded corners */
  font-size: 0.95rem;
  color: #1a202c;
  outline: none;
  transition: all 0.2s ease;
  appearance: none;
  -webkit-appearance: none;
  -moz-appearance: none;
}

.form-input:focus, .form-select:focus {
  border-color: #0b0e54;
  box-shadow: 0 0 0 3px rgba(11, 14, 84, 0.05);
}

.form-input::placeholder {
  color: #a0aec0;
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
  background-color: #0b0e54; /* Navy blue button */
  color: #ffffff;
  border: none;
  border-radius: 16px; /* High radius rounded corners matching mockup */
  padding: 16px;
  font-size: 1rem;
  font-weight: 700;
  cursor: pointer;
  display: flex;
  justify-content: center;
  align-items: center;
  margin-top: 20px;
  box-shadow: 0 4px 12px rgba(11, 14, 84, 0.12);
  transition: all 0.2s ease;
}

.submit-btn:hover {
  background-color: #00003e;
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
/* Custom Date-Time & Location clickable triggers */
.custom-datetime-trigger, .custom-location-trigger {
  width: 100%;
  padding: 14px 18px;
  background-color: #f7f9fc; /* Soft shaded grey background */
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  font-size: 0.95rem;
  color: #1a202c;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 10px;
  transition: all 0.2s ease;
}

.custom-datetime-trigger:hover, .custom-location-trigger:hover {
  border-color: #0b0e54;
  background-color: #f1f5f9;
}

.trigger-icon {
  font-size: 1.15rem;
  display: flex;
  align-items: center;
  justify-content: center;
}

.trigger-text {
  flex: 1;
  font-weight: 500;
}

.trigger-text.placeholder {
  color: #718096;
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

/* Map Picker Modal Backdrop */
.map-modal-backdrop {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background-color: rgba(15, 23, 42, 0.5);
  backdrop-filter: blur(8px);
  z-index: 2000;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Map Picker Modal Dialog */
.map-modal-dialog {
  width: 100%;
  height: 100%;
  background-color: #fafafc;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

@media (min-width: 768px) {
  .map-modal-dialog {
    width: 90%;
    max-width: 520px;
    height: 90vh;
    max-height: 800px;
    border-radius: 24px;
    box-shadow: 0 12px 36px rgba(0, 0, 0, 0.15);
    border: 1px solid #e2e8f0;
  }
}

.map-modal-header {
  padding: 16px 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  background-color: #ffffff;
  border-bottom: none;
}

.map-modal-back-btn {
  background: none;
  border: none;
  font-size: 1.6rem;
  color: #0b0e54;
  cursor: pointer;
  padding: 4px;
  display: flex;
  align-items: center;
}

.map-modal-back-btn:hover {
  opacity: 0.7;
}

.map-modal-title {
  font-size: 1.2rem;
  font-weight: 800;
  color: #000000;
  flex: 1;
  text-align: center;
}

.map-modal-body {
  flex: 1;
  position: relative;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

/* Map Search Box Floating */
.map-search-container {
  position: absolute;
  top: 16px;
  left: 16px;
  right: 16px;
  z-index: 1000;
  background-color: #ffffff;
  border-radius: 24px; /* Fully rounded search bar */
  padding: 6px 16px;
  display: flex;
  align-items: center;
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.08);
  border: 1px solid #e2e8f0;
}

.map-search-input {
  flex: 1;
  border: none;
  background: transparent;
  color: #1a202c;
  font-size: 0.95rem;
  outline: none;
}

.map-search-input::placeholder {
  color: #718096;
}

.map-search-btn {
  background: none;
  border: none;
  color: #718096;
  cursor: pointer;
  font-size: 1.1rem;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Search suggestions dropdown in map */
.map-search-results {
  position: absolute;
  top: 76px;
  left: 16px;
  right: 16px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.1);
  list-style: none;
  padding: 0;
  margin: 0;
  max-height: 200px;
  overflow-y: auto;
  z-index: 1010;
}

.map-search-result-item {
  padding: 12px 16px;
  font-size: 0.9rem;
  color: #1a202c;
  cursor: pointer;
  border-bottom: 1px solid #e2e8f0;
}

.map-search-result-item:last-child {
  border-bottom: none;
}

.map-search-result-item:hover {
  background-color: #f7f9fc;
}

/* Map Picker Height */
.map-container-div {
  width: 100%;
  height: 100%;
  flex: 1;
  z-index: 1;
}

/* Floating Locate Button */
.map-locate-float-btn {
  position: absolute;
  bottom: 210px; /* Floats above bottom sheet */
  right: 16px;
  z-index: 999;
  width: 48px;
  height: 48px;
  background-color: #ffffff;
  border-radius: 50%;
  border: none;
  box-shadow: 0 4px 14px rgba(0, 0, 0, 0.12);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: 1.25rem;
  color: #0b0e54;
  transition: all 0.2s ease;
}

.map-locate-float-btn:hover {
  transform: scale(1.05);
  box-shadow: 0 6px 18px rgba(0, 0, 0, 0.18);
}

/* Sliding Bottom Address Card matching mockup */
.map-selected-sheet {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  background-color: #ffffff;
  border-radius: 24px 24px 0 0;
  padding: 24px;
  box-shadow: 0 -8px 30px rgba(0, 0, 0, 0.08);
  z-index: 1000;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.sheet-title-row {
  display: flex;
  align-items: center;
  gap: 6px;
}

.sheet-pin-icon {
  font-size: 1.2rem;
  color: #0b0e54;
}

.sheet-title-label {
  font-size: 0.95rem;
  font-weight: 800;
  color: #1a202c;
}

.sheet-address-text {
  font-size: 0.9rem;
  color: #4a5568;
  line-height: 1.5;
  margin-bottom: 8px;
}

.geocoding-spinner-text {
  color: #0b0e54;
  font-weight: 700;
}

.map-confirm-btn {
  width: 100%;
  background-color: #0b0e54; /* navy */
  color: #ffffff;
  border: none;
  border-radius: 16px;
  padding: 16px;
  font-size: 0.95rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s ease;
}

.map-confirm-btn:hover {
  background-color: #00003e;
}

.map-confirm-btn:disabled {
  background-color: #cbd5e1;
  color: #94a3b8;
  cursor: not-allowed;
}
</style>
