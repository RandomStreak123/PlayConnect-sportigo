<script setup>
import { ref, computed } from 'vue'
import { store } from '../store'
import { getPlayerAvatar } from '../utils/sportImageHelper'
import { supabase } from '../utils/supabase'
import { t } from '../utils/i18n'

const emit = defineEmits(['auth-logout', 'toast-message'])

const props = defineProps({
  isCurrentUser: {
    type: Boolean,
    default: true
  },
  playerName: {
    type: String,
    default: ''
  },
  profilePicture: {
    type: String,
    default: null
  }
})

const selectedSport = ref('Football')
const activeSegmentTab = ref(0) // 0: Activity, 1: Achievements, 2: Streaks

// Self-ratings dictionary
const sportRatings = ref({
  'Football': 5,
  'Cricket': 4,
  'Badminton': 4,
  'Basketball': 3,
  'Tennis': 5,
  'Padel': 4
})

const sportsList = [
  { name: 'Football', icon: '⚽' },
  { name: 'Cricket', icon: '🏏' },
  { name: 'Badminton', icon: '🏸' },
  { name: 'Basketball', icon: '🏀' },
  { name: 'Tennis', icon: '🎾' },
  { name: 'Padel', icon: '🏓' }
]

const currentUser = computed(() => {
  if (props.isCurrentUser) {
    return store.state.currentUser || { name: 'Champ', gender: 'male', profilePhotoUrl: null }
  } else {
    return {
      name: props.playerName || 'Player',
      gender: 'male',
      profilePhotoUrl: props.profilePicture
    }
  }
})

const avatarUrl = computed(() => {
  return getPlayerAvatar(currentUser.value.profilePhotoUrl, currentUser.value.gender)
})

const isLavenderTheme = computed(() => {
  return store.isWomenMode.value
})

const getSportColor = (sport) => {
  switch (sport) {
    case 'Football': return '#10b981'
    case 'Cricket': return '#3b82f6'
    case 'Basketball': return '#f97316'
    case 'Tennis': return '#06b6d4'
    case 'Padel': return '#2563eb'
    case 'Badminton': return '#8b5cf6'
    default: return '#1a237e'
  }
}

const getSportGradient = (sport) => {
  switch (sport) {
    case 'Football': return 'linear-gradient(135deg, #059669 0%, #10b981 100%)'
    case 'Cricket': return 'linear-gradient(135deg, #1d4ed8 0%, #3b82f6 100%)'
    case 'Basketball': return 'linear-gradient(135deg, #c2410c 0%, #ea580c 50%, #f97316 100%)'
    case 'Tennis': return 'linear-gradient(135deg, #0891b2 0%, #06b6d4 100%)'
    case 'Padel': return 'linear-gradient(135deg, #1e3a8a 0%, #2563eb 100%)'
    case 'Badminton': return 'linear-gradient(135deg, #6d28d9 0%, #8b5cf6 100%)'
    default: return 'linear-gradient(135deg, #1a237e 0%, #303f9f 50%, #7986cb 100%)'
  }
}

const currentSportColor = computed(() => {
  return getSportColor(selectedSport.value)
})

const currentSportGradient = computed(() => {
  return getSportGradient(currentUser.value.primary_sport || selectedSport.value)
})

const getSportEmoji = (sport) => {
  const found = sportsList.find(s => s.name === sport)
  return found ? found.icon : '🏃'
}

const handleRate = (stars) => {
  if (!props.isCurrentUser) return
  sportRatings.value[selectedSport.value] = stars
  emit('toast-message', `Rated ${selectedSport.value} as ${stars} Stars! ⭐`)
}

const handleThemeToggle = (e) => {
  const checked = e.target.checked
  store.setThemePreference(checked ? 'elegantLavender' : 'activeSteelBlue')
}

const handleLogout = () => {
  store.logout()
  emit('auth-logout')
}

const handleSettingsInfo = (msg) => {
  emit('toast-message', msg)
}

// Share profile link to clipboard
const handleShareProfile = () => {
  const userId = currentUser.value.id || 'guest'
  const shareUrl = `${window.location.origin}/?tab=profile&user=${userId}`
  
  if (navigator.clipboard) {
    navigator.clipboard.writeText(shareUrl)
      .then(() => {
        emit('toast-message', 'Profile share link copied to clipboard! 📋')
      })
      .catch(() => {
        emit('toast-message', `Share Link: ${shareUrl} 🔗`)
      })
  } else {
    emit('toast-message', `Share Link: ${shareUrl} 🔗`)
  }
}

// Edit Profile Modal States
const showEditModal = ref(false)
const isSavingProfile = ref(false)

const editName = ref('')
const editBio = ref('')
const editSport = ref('')
const editSkill = ref('')
const editGender = ref('')

const openEditModal = () => {
  editName.value = currentUser.value.name || ''
  editBio.value = currentUser.value.bio || ''
  editSport.value = currentUser.value.primary_sport || 'Football'
  editSkill.value = currentUser.value.skill_tier || 'Intermediate'
  editGender.value = currentUser.value.gender || 'male'
  showEditModal.value = true
}

const saveProfileDetails = async () => {
  if (!editName.value.trim()) {
    emit('toast-message', 'Name cannot be empty! ❌')
    return
  }
  
  try {
    isSavingProfile.value = true
    emit('toast-message', 'Updating profile details... ⏳')
    
    await store.updateProfile(
      editName.value.trim(),
      editGender.value,
      null, // keep current avatar
      editBio.value.trim(),
      editSport.value,
      editSkill.value
    )
    
    emit('toast-message', 'Profile details updated successfully! 🎉')
    showEditModal.value = false
  } catch (error) {
    emit('toast-message', `Update failed: ${error.message} ❌`)
  } finally {
    isSavingProfile.value = false
  }
}

// Supabase Avatar Upload
const fileInput = ref(null)
const isUploading = ref(false)

const onFileSelected = async (event) => {
  const files = event.target.files
  if (!files || files.length === 0) return

  const file = files[0]
  const userId = currentUser.value.id || 'guest'

  try {
    isUploading.value = true
    emit('toast-message', 'Uploading avatar to Supabase Storage... ⏳')

    // 1. Prepare file path
    const fileExt = file.name.split('.').pop()
    const filePath = `${userId}/avatar-${Date.now()}.${fileExt}`

    // 2. Upload file to avatar bucket
    const { error: uploadError } = await supabase.storage
      .from('avatar')
      .upload(filePath, file, {
        cacheControl: '3600',
        upsert: true
      })

    if (uploadError) throw uploadError

    // 3. Get public URL
    const { data: urlData } = supabase.storage
      .from('avatar')
      .getPublicUrl(filePath)

    const publicUrl = urlData.publicUrl

    // 4. Update Laravel backend database
    await store.updateProfile(currentUser.value.name, currentUser.value.gender, publicUrl)

    emit('toast-message', 'Profile picture updated successfully! 🎉')
  } catch (error) {
    console.error('Upload error:', error.message)
    emit('toast-message', `Upload failed: ${error.message} ❌`)
  } finally {
    isUploading.value = false
    if (fileInput.value) {
      fileInput.value.value = '' // reset input
    }
  }
}
</script>

<template>
  <div 
    class="profile-container scrollable-y animate-fade-in"
    :style="{ background: `linear-gradient(180deg, ${currentSportColor}1A 0%, var(--scaffold-bg) 350px, var(--scaffold-bg) 100%)` }"
  >
    <!-- Custom Header -->
    <div class="profile-header">
      <h2 class="title">{{ t('playerProfile') }}</h2>
      <button v-if="isCurrentUser" class="settings-nav-btn" @click="handleSettingsInfo('Navigating to Settings panel... ⚙️')">
        ⚙️
      </button>
    </div>

    <!-- Profile Info Card -->
    <div class="profile-card">
      <div class="card-banner" :style="{ background: currentSportGradient }"></div>
      <div class="avatar-wrap">
        <img :src="avatarUrl" class="card-avatar" @error="(e) => e.target.src = '/assets/images/players/download.jpg'" />
        <button v-if="isCurrentUser" class="camera-btn" @click="fileInput.click()" :disabled="isUploading">
          <span v-if="isUploading">⏳</span>
          <span v-else>📷</span>
        </button>
        <input 
          ref="fileInput"
          type="file"
          accept="image/*"
          style="display: none"
          @change="onFileSelected"
        />
      </div>

      <h3 class="card-name">{{ currentUser.name }}</h3>
      <span class="card-level" :style="{ color: currentSportColor }">{{ t('level') }} 18</span>

      <p class="card-bio">{{ currentUser.bio || t('noBioYet') }}</p>

      <div class="profile-badges" v-if="currentUser.primary_sport || currentUser.skill_tier">
        <span class="profile-badge sport" v-if="currentUser.primary_sport" :style="{ backgroundColor: getSportColor(currentUser.primary_sport) + '20', color: getSportColor(currentUser.primary_sport) }">
          {{ getSportEmoji(currentUser.primary_sport) }} {{ currentUser.primary_sport }}
        </span>
        <span class="profile-badge skill" v-if="currentUser.skill_tier">
          🏆 {{ currentUser.skill_tier }}
        </span>
      </div>

      <!-- Action tags -->
      <div class="action-badges-row">
        <button class="badge-btn" @click="handleShareProfile">
          📤 {{ t('shareProfile') }}
        </button>
        <button v-if="isCurrentUser" class="badge-btn edit" @click="openEditModal">
          ✏️ {{ t('editProfile') }}
        </button>
      </div>
    </div>

    <!-- XP system -->
    <div class="xp-container">
      <div class="xp-row">
        <span class="xp-lbl">{{ t('levelProgression') }}</span>
        <span class="xp-val">4,250 / 5,000 XP</span>
      </div>
      <div class="progress-track">
        <div class="progress-fill" :style="{ width: '85%', backgroundColor: currentSportColor }"></div>
      </div>
      <span class="xp-sub-lbl">750 XP to Level 19</span>
    </div>

    <!-- Stats Grid -->
    <div class="stats-grid">
      <div class="stat-box">
        <span class="stat-val">142</span>
        <span class="stat-lbl">{{ t('matches') }}</span>
      </div>
      <div class="stat-box">
        <span class="stat-val">98%</span>
        <span class="stat-lbl">{{ t('reliability') }}</span>
      </div>
      <div class="stat-box">
        <span class="stat-val">4.8</span>
        <span class="stat-lbl">{{ t('rating') }}</span>
      </div>
      <div class="stat-box">
        <span class="stat-val">7 🔥</span>
        <span class="stat-lbl">{{ t('streak') }}</span>
      </div>
    </div>

    <!-- Achievements segments selector -->
    <div class="segmented-bar">
      <button 
        class="segment-btn" 
        :class="{ active: activeSegmentTab === 0 }"
        @click="activeSegmentTab = 0"
      >
        {{ t('activity') }}
      </button>
      <button 
        class="segment-btn" 
        :class="{ active: activeSegmentTab === 1 }"
        @click="activeSegmentTab = 1"
      >
        {{ t('achievements') }}
      </button>
      <button 
        class="segment-btn" 
        :class="{ active: activeSegmentTab === 2 }"
        @click="activeSegmentTab = 2"
      >
        {{ t('streaks') }}
      </button>
    </div>

    <!-- Active Segment panels -->
    <div class="segment-panel">
      <!-- Activity -->
      <div v-if="activeSegmentTab === 0" class="panel-content animate-fade-in">
        <div class="activity-history-tile">
          <span class="act-emoji">⚽</span>
          <div class="act-details">
            <span class="act-title">Played Friday 5v5 Turf Friendly</span>
            <span class="act-date">3 days ago · Sportego Arena</span>
          </div>
        </div>
        <div class="activity-history-tile">
          <span class="act-emoji">🏏</span>
          <div class="act-details">
            <span class="act-title">Organized Weekend T10 Practice</span>
            <span class="act-date">1 week ago · Municipal Ground</span>
          </div>
        </div>
      </div>

      <!-- Achievements -->
      <div v-else-if="activeSegmentTab === 1" class="panel-content achievements animate-fade-in">
        <div class="badge-item">🏅 MVP Match Player</div>
        <div class="badge-item">🔥 5 Match Streak Hero</div>
        <div class="badge-item">🤝 Fair Play Badge</div>
      </div>

      <!-- Streaks -->
      <div v-else class="panel-content streaks animate-fade-in">
        <div class="streak-details">
          <span class="streak-large">7</span>
          <span class="streak-label">{{ t('consecutiveWeekly') }}</span>
        </div>
      </div>
    </div>

    <!-- Sports ratings selection -->
    <div class="sports-rating-section">
      <h4 class="section-sub-title">{{ t('sportsSkillProfile') }}</h4>
      
      <div class="chips-slider">
        <button 
          v-for="sport in sportsList" 
          :key="sport.name"
          class="sport-chip"
          :class="{ active: selectedSport === sport.name }"
          :style="selectedSport === sport.name ? { backgroundColor: currentSportColor, borderColor: currentSportColor } : {}"
          @click="selectedSport = sport.name"
        >
          <span class="chip-emoji">{{ sport.icon }}</span>
          {{ sport.name }}
        </button>
      </div>

      <!-- Rating stars display -->
      <div class="stars-card">
        <span class="stars-title">{{ t('rateSkillIn') }} {{ selectedSport }}</span>
        <div class="stars-row">
          <span 
            v-for="star in 5" 
            :key="star"
            class="star-item"
            @click="handleRate(star)"
          >
            {{ star <= (sportRatings[selectedSport] || 0) ? '⭐' : '☆' }}
          </span>
        </div>
        <span class="stars-helper-text">
          {{ isCurrentUser ? t('tapStarsToRate') : t('selfAssessment') }}
        </span>
      </div>
    </div>

    <!-- Settings options -->
    <div v-if="isCurrentUser" class="privacy-section">
      <h4 class="section-sub-title">{{ t('personalization') }}</h4>
      
      <!-- Language Selector -->
      <div class="setting-switch-tile">
        <div class="setting-switch-info">
          <span class="tile-title">🌐 {{ t('selectLanguage') }}</span>
          <span class="tile-desc">Choose interface language</span>
        </div>
        <select 
          :value="store.state.language" 
          class="language-select-dropdown" 
          @change="(e) => store.setLanguage(e.target.value)"
        >
          <option value="en">English / अंग्रेज़ी</option>
          <option value="hi">Hindi / हिंदी</option>
        </select>
      </div>

      <!-- Theme Switch -->
      <div class="setting-switch-tile">
        <div class="setting-switch-info">
          <span class="tile-title">🌸 {{ t('elegantLavender') }}</span>
          <span class="tile-desc">
            {{ isLavenderTheme ? t('lavenderActive') : t('switchLavender') }}
          </span>
        </div>
        <label class="toggle-control">
          <input :checked="isLavenderTheme" type="checkbox" @change="handleThemeToggle" />
          <span class="toggle-slider"></span>
        </label>
      </div>
    </div>

    <!-- Menu settings lists -->
    <div v-if="isCurrentUser" class="settings-menu-list">
      <div class="menu-tile" @click="handleSettingsInfo('Sportigo platform game guide coming soon! 📑')">
        <span class="menu-icon">🛡️</span>
        <div class="menu-info">
          <span class="menu-title">{{ t('gameRules') }}</span>
          <span class="menu-subtitle">{{ t('gameRulesSub') }}</span>
        </div>
        <span class="chevron">➔</span>
      </div>

      <div class="menu-tile" @click="handleSettingsInfo('Tournament logs coming soon! 🏆')">
        <span class="menu-icon">📊</span>
        <div class="menu-info">
          <span class="menu-title">{{ t('statsHistory') }}</span>
          <span class="menu-subtitle">{{ t('statsHistorySub') }}</span>
        </div>
        <span class="chevron">➔</span>
      </div>

      <div class="menu-tile destructive" @click="handleLogout">
        <span class="menu-icon">🚪</span>
        <div class="menu-info">
          <span class="menu-title">{{ t('signOut') }}</span>
          <span class="menu-subtitle">{{ t('signOutSub') }}</span>
        </div>
        <span class="chevron">➔</span>
      </div>
    </div>

    <!-- Edit Profile Modal -->
    <Teleport to="body">
      <div v-if="showEditModal" class="modal-backdrop" @click="showEditModal = false">
        <div class="modal-sheet animate-slide-up" @click.stop>
          <div class="modal-header">
            <h2 class="modal-title">Edit Profile</h2>
            <button class="close-btn" @click="showEditModal = false">✕</button>
          </div>

          <div class="modal-body scrollable-y">
            <!-- Name -->
            <div class="input-group">
              <label class="input-label">Display Name</label>
              <input 
                v-model="editName"
                type="text" 
                placeholder="e.g. Champ"
                class="form-input"
              />
            </div>

            <!-- Bio -->
            <div class="input-group">
              <label class="input-label">Bio (Tell others about yourself)</label>
              <textarea 
                v-model="editBio"
                placeholder="e.g. Football enthusiast. Always down for a friendly match."
                class="form-textarea"
                rows="3"
                maxlength="500"
              ></textarea>
            </div>

            <!-- Primary Sport -->
            <div class="input-group">
              <label class="input-label">Primary Sport</label>
              <div class="sport-select-grid">
                <button 
                  v-for="sport in sportsList" 
                  :key="sport.name"
                  type="button"
                  class="sport-chip"
                  :class="{ active: editSport === sport.name }"
                  :style="editSport === sport.name ? { backgroundColor: getSportColor(sport.name), borderColor: getSportColor(sport.name), color: '#ffffff' } : {}"
                  @click="editSport = sport.name"
                >
                  <span class="chip-emoji">{{ sport.icon }}</span> {{ sport.name }}
                </button>
              </div>
            </div>

            <!-- Gender & Skill Level in a row -->
            <div class="form-row">
              <div class="input-group half">
                <label class="input-label">Gender</label>
                <select v-model="editGender" class="form-select">
                  <option value="male">Male</option>
                  <option value="female">Female</option>
                </select>
              </div>
              <div class="input-group half">
                <label class="input-label">Skill Tier</label>
                <select v-model="editSkill" class="form-select">
                  <option value="Beginner">Beginner</option>
                  <option value="Intermediate">Intermediate</option>
                  <option value="Advanced">Advanced</option>
                  <option value="Professional">Professional</option>
                </select>
              </div>
            </div>

            <!-- Submit Button -->
            <button class="submit-btn" :disabled="isSavingProfile" @click="saveProfileDetails">
              <span v-if="isSavingProfile" class="loader"></span>
              <span v-else>Save Changes</span>
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.profile-container {
  padding: 56px 20px 80px;
  transition: background 0.6s ease;
}

.profile-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.title {
  font-family: var(--font-display);
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--on-surface);
}

.settings-nav-btn {
  background: none;
  border: none;
  font-size: 1.2rem;
  cursor: pointer;
}

.profile-card {
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-lg);
  padding: 0 16px 24px;
  display: flex;
  flex-direction: column;
  align-items: center;
  box-shadow: var(--shadow-sm);
  margin-bottom: 24px;
  overflow: hidden;
  position: relative;
}

.card-banner {
  width: 100%;
  height: 120px;
  margin-left: -16px;
  margin-right: -16px;
  width: calc(100% + 32px);
  margin-bottom: 16px;
  transition: background 0.6s ease;
  position: relative;
  overflow: hidden;
}

.card-banner::after {
  content: '';
  position: absolute;
  inset: 0;
  background-image: radial-gradient(circle at 80% 20%, rgba(255, 255, 255, 0.18) 0%, transparent 60%),
                    linear-gradient(rgba(0, 0, 0, 0) 30%, rgba(0, 0, 0, 0.2) 100%);
  opacity: 0.8;
  pointer-events: none;
}

.language-select-dropdown {
  padding: 8px 12px;
  border-radius: var(--radius-sm);
  border: 1px solid var(--outline-variant);
  background-color: var(--surface);
  color: var(--on-surface);
  font-family: var(--font-sans);
  font-weight: 700;
  font-size: 0.8rem;
  outline: none;
  cursor: pointer;
  transition: border-color 0.2s ease;
}

.language-select-dropdown:focus {
  border-color: var(--primary);
}

.avatar-wrap {
  position: relative;
  margin-top: -64px;
  margin-bottom: 12px;
  z-index: 2;
}

.card-avatar {
  width: 88px;
  height: 88px;
  border-radius: 50%;
  object-fit: cover;
  border: 4px solid var(--surface);
  box-shadow: var(--shadow-md);
}

.camera-btn {
  position: absolute;
  bottom: 0;
  right: 0;
  background-color: var(--primary);
  border: none;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  color: #ffffff;
  display: flex;
  justify-content: center;
  align-items: center;
  cursor: pointer;
  font-size: 0.8rem;
  box-shadow: var(--shadow-sm);
}

.card-name {
  font-size: 1.25rem;
  font-weight: 800;
  color: var(--on-surface);
  margin-bottom: 4px;
}

.card-level {
  font-size: 0.75rem;
  font-weight: 700;
  letter-spacing: 0.5px;
  margin-bottom: 16px;
}

.action-badges-row {
  display: flex;
  gap: 10px;
}

.badge-btn {
  background-color: var(--scaffold-bg);
  border: 1px solid var(--outline-variant);
  padding: 8px 14px;
  border-radius: var(--radius-md);
  font-size: 0.78rem;
  font-weight: 700;
  color: var(--on-surface-variant);
  cursor: pointer;
}

.badge-btn.edit {
  background-color: rgba(26, 35, 126, 0.05);
  color: var(--primary);
  border-color: rgba(26, 35, 126, 0.15);
}

/* XP progressions */
.xp-container {
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  padding: 16px;
  margin-bottom: 20px;
  box-shadow: var(--shadow-sm);
}

.xp-row {
  display: flex;
  justify-content: space-between;
  font-size: 0.85rem;
  font-weight: 700;
  margin-bottom: 8px;
}

.xp-lbl { color: var(--on-surface-variant); }
.xp-val { color: var(--on-surface); }

.progress-track {
  height: 8px;
  background-color: var(--surface-dim);
  border-radius: 4px;
  overflow: hidden;
  margin-bottom: 6px;
}

.progress-fill {
  height: 100%;
  border-radius: 4px;
}

.xp-sub-lbl {
  font-size: 0.7rem;
  color: var(--outline);
  font-weight: 600;
}

/* Stats grid */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 10px;
  margin-bottom: 24px;
}

.stat-box {
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  padding: 12px 4px;
  display: flex;
  flex-direction: column;
  align-items: center;
  box-shadow: var(--shadow-sm);
}

.stat-val {
  font-family: var(--font-display);
  font-size: 1.1rem;
  font-weight: 700;
  color: var(--on-surface);
  margin-bottom: 2px;
}

.stat-lbl {
  font-size: 0.65rem;
  font-weight: 700;
  color: var(--outline);
  text-transform: uppercase;
}

/* Segmented selector */
.segmented-bar {
  display: flex;
  background-color: var(--surface-dim);
  border-radius: var(--radius-md);
  padding: 4px;
  margin-bottom: 16px;
}

.segment-btn {
  flex: 1;
  border: none;
  background: none;
  padding: 8px;
  font-size: 0.8rem;
  font-weight: 700;
  border-radius: 12px;
  color: var(--on-surface-variant);
  cursor: pointer;
}

.segment-btn.active {
  background-color: var(--surface);
  color: var(--primary);
  box-shadow: var(--shadow-sm);
}

.segment-panel {
  margin-bottom: 28px;
}

.panel-content {
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  padding: 16px;
  min-height: 120px;
  box-shadow: var(--shadow-sm);
}

.activity-history-tile {
  display: flex;
  gap: 12px;
  align-items: center;
  padding-bottom: 12px;
  margin-bottom: 12px;
  border-bottom: 1px solid var(--outline-variant);
}

.activity-history-tile:last-child {
  border-bottom: none;
  padding-bottom: 0;
  margin-bottom: 0;
}

.act-emoji { font-size: 1.25rem; }

.act-details {
  display: flex;
  flex-direction: column;
}

.act-title {
  font-size: 0.85rem;
  font-weight: 700;
  color: var(--on-surface);
}

.act-date {
  font-size: 0.72rem;
  color: var(--outline);
}

.achievements {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.badge-item {
  background-color: var(--scaffold-bg);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  padding: 10px;
  font-size: 0.8rem;
  font-weight: 700;
  color: var(--on-surface);
}

.streak-details {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding-top: 14px;
}

.streak-large {
  font-size: 2.2rem;
  font-weight: 800;
  color: var(--primary);
}

.streak-label {
  font-size: 0.78rem;
  color: var(--on-surface-variant);
  font-weight: 600;
}

/* Sports ratings selection */
.sports-rating-section {
  margin-bottom: 28px;
}

.section-sub-title {
  font-size: 0.95rem;
  font-weight: 700;
  margin-bottom: 14px;
  color: var(--on-surface);
}

.chips-slider {
  display: flex;
  gap: 8px;
  overflow-x: auto;
  padding-bottom: 12px;
  margin-bottom: 12px;
}

.chips-slider::-webkit-scrollbar {
  display: none;
}

.sport-chip {
  padding: 8px 16px;
  border-radius: 20px;
  border: 1px solid var(--outline-variant);
  background-color: var(--surface);
  color: var(--on-surface-variant);
  font-size: 0.78rem;
  font-weight: 700;
  cursor: pointer;
  white-space: nowrap;
  display: flex;
  align-items: center;
  gap: 6px;
}

.sport-chip.active {
  color: #ffffff;
}

.stars-card {
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  padding: 16px;
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  box-shadow: var(--shadow-sm);
}

.stars-title {
  font-size: 0.88rem;
  font-weight: 700;
  margin-bottom: 12px;
}

.stars-row {
  display: flex;
  gap: 8px;
  font-size: 2rem;
  margin-bottom: 8px;
}

.star-item {
  cursor: pointer;
  user-select: none;
  transition: transform 0.1s ease;
}

.star-item:active {
  transform: scale(1.2);
}

.stars-helper-text {
  font-size: 0.7rem;
  color: var(--outline);
}

/* Toggle settings style */
.privacy-section {
  margin-bottom: 28px;
}

.setting-switch-tile {
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  padding: 16px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: var(--shadow-sm);
}

.setting-switch-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.tile-title {
  font-size: 0.88rem;
  font-weight: 700;
  color: var(--on-surface);
}

.tile-desc {
  font-size: 0.72rem;
  color: var(--outline);
}

/* Custom toggler styling */
.toggle-control {
  position: relative;
  display: inline-block;
  width: 44px;
  height: 24px;
  flex-shrink: 0;
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

/* Settings Menu items list */
.settings-menu-list {
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-lg);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  box-shadow: var(--shadow-sm);
}

.menu-tile {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 16px 20px;
  border-bottom: 1px solid var(--outline-variant);
  cursor: pointer;
  transition: background-color 0.2s ease;
}

.menu-tile:hover {
  background-color: var(--scaffold-bg);
}

.menu-tile:last-child {
  border-bottom: none;
}

.menu-icon {
  width: 38px;
  height: 38px;
  border-radius: 50%;
  background-color: var(--scaffold-bg);
  display: flex;
  justify-content: center;
  align-items: center;
  font-size: 1.1rem;
}

.menu-tile.destructive .menu-icon {
  background-color: rgba(186, 26, 26, 0.08);
}

.menu-info {
  display: flex;
  flex-direction: column;
  flex: 1;
}

.menu-title {
  font-size: 0.88rem;
  font-weight: 700;
  color: var(--on-surface);
}

.menu-tile.destructive .menu-title {
  color: var(--error);
}

.menu-subtitle {
  font-size: 0.72rem;
  color: var(--outline);
}

.chevron {
  font-size: 0.82rem;
  color: var(--outline-variant);
}

/* Card bio & badges */
.card-bio {
  font-size: 0.88rem;
  color: var(--on-surface-variant);
  text-align: center;
  margin: 8px 16px 12px;
  line-height: 1.4;
  word-break: break-word;
}

.profile-badges {
  display: flex;
  gap: 8px;
  margin-bottom: 16px;
}

.profile-badge {
  font-size: 0.75rem;
  font-weight: 700;
  padding: 4px 10px;
  border-radius: 12px;
  background-color: var(--surface-dim);
  color: var(--on-surface-variant);
  border: 1px solid var(--outline-variant);
  display: flex;
  align-items: center;
  gap: 4px;
}

/* Modal styles (matching CreateMatchModal layout) */
.modal-backdrop {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background-color: rgba(15, 23, 42, 0.45);
  backdrop-filter: blur(4px);
  z-index: 1500;
  display: flex;
  align-items: flex-end;
  justify-content: center;
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
  overflow-y: auto;
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
  text-align: left;
}

.form-input, .form-select, .form-textarea {
  width: 100%;
  padding: 12px 16px;
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  font-size: 0.95rem;
  color: var(--on-surface);
  outline: none;
  transition: border-color 0.2s ease;
  font-family: inherit;
}

.form-input:focus, .form-select:focus, .form-textarea:focus {
  border-color: var(--primary);
}

.form-textarea {
  resize: none;
}

.form-row {
  display: flex;
  gap: 16px;
}

.form-row .half {
  flex: 1;
}

.sport-select-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
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

.animate-slide-up {
  animation: slideUp 0.3s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

@keyframes slideUp {
  from {
    transform: translateY(100%);
  }
  to {
    transform: translateY(0);
  }
}
</style>
