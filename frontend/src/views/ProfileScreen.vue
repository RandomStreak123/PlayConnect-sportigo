<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
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
  userId: {
    type: [Number, String],
    default: null
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

const profileUser = ref(null)
const loadingProfileUser = ref(false)

const loadUserProfile = async () => {
  if (props.isCurrentUser) {
    profileUser.value = null
    return
  }
  if (!props.userId) return

  loadingProfileUser.value = true
  try {
    const res = await fetch(`/api/users/${props.userId}`, {
      headers: {
        'Authorization': `Bearer ${localStorage.getItem('sportigo_token')}`,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    })
    if (res.ok) {
      profileUser.value = await res.json()
    }
  } catch (err) {
    console.error('Failed to load public profile:', err)
  } finally {
    loadingProfileUser.value = false
  }
}

watch(() => props.userId, () => {
  loadUserProfile()
}, { immediate: true })

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
    if (profileUser.value) {
      return {
        ...profileUser.value,
        profilePhotoUrl: profileUser.value.avatar || profileUser.value.profile_picture || profileUser.value.profile_photo || props.profilePicture
      }
    }
    return {
      name: props.playerName || 'Player',
      gender: 'male',
      profilePhotoUrl: props.profilePicture
    }
  }
})

const userMatches = computed(() => {
  const matches = props.isCurrentUser ? store.state.matches : (profileUser.value?.matches || [])
  const uid = props.isCurrentUser ? store.state.currentUser?.id : props.userId
  if (!uid) return []
  
  return matches.filter(m => {
    const isCreator = Number(m.creator_id || m.user_id) === Number(uid)
    const isParticipant = m.participants?.some(p => Number(p.id) === Number(uid))
    return isCreator || isParticipant
  })
})

// Filter to matches that have already been played (in the past)
const playedMatches = computed(() => {
  const now = new Date()
  return userMatches.value.filter(m => {
    const matchDate = new Date(m.date_time || m.date)
    return matchDate < now
  })
})

const showAllActivities = ref(false)

const visibleActivities = computed(() => {
  if (showAllActivities.value) {
    return playedMatches.value
  }
  return playedMatches.value.slice(0, 4)
})

// Determine if a match is a win for the given user
// Uses real recorded result from pivot data when available,
// falls back to deterministic formula for unrecorded matches
const isMatchWin = (match, uid) => {
  // Check for real recorded result from pivot data
  const participant = match.participants?.find(p => Number(p.id) === Number(uid))
  if (participant?.pivot?.result) {
    return participant.pivot.result === 'win'
  }
  // Fallback: deterministic formula for matches without recorded results
  const matchId = match.id || 0
  const userId = uid || 0
  return ((matchId * 7 + userId * 13) % 10) < 6
}

const hasRealResult = (match, uid) => {
  const participant = match.participants?.find(p => Number(p.id) === Number(uid))
  return !!participant?.pivot?.result
}

const profileStats = computed(() => {
  const matches = playedMatches.value
  const uid = props.isCurrentUser ? store.state.currentUser?.id : props.userId

  // XP Rules (per Sportigo Profile Feature Roadmap)
  // Join Match: 5 XP | Complete Match: 15 XP | Create Match: 20 XP | Win Match: 25 XP
  let xp = 0
  let wins = 0
  let createdCount = 0

  matches.forEach(m => {
    const isCreator = Number(m.creator_id || m.user_id) === Number(uid)
    const isWin = isMatchWin(m, uid)

    // Create Match (20 XP) or Join Match (5 XP)
    if (isCreator) {
      xp += 20
      createdCount++
    } else {
      xp += 5
    }

    // Complete Match: 15 XP (all past matches are completed)
    xp += 15

    // Win Match: 25 XP
    if (isWin) {
      xp += 25
      wins++
    }
  })

  const nextLevelXp = 1000
  const level = Math.floor(xp / nextLevelXp) + 1
  const currentLevelXp = xp % nextLevelXp
  const progressPct = Math.round((currentLevelXp / nextLevelXp) * 100)

  // Win Rate = Wins / Total Matches * 100
  const winRate = matches.length > 0 ? Math.round((wins / matches.length) * 100) : 0

  // Streaks: consecutive wins counting backwards from the most recent past match
  let streak = 0
  const sortedMatches = [...matches].sort((a, b) => new Date(b.date_time || b.date) - new Date(a.date_time || a.date))
  for (const m of sortedMatches) {
    const isWin = isMatchWin(m, uid)
    if (isWin) {
      streak++
    } else {
      break
    }
  }

  // Play Style (per Roadmap)
  // Organizer: Creates Many Matches (>= 40% created)
  // Attacker: High Scoring (win rate >= 70%)
  // Defender: Defensive Focus (plays many but win rate < 50%)
  // All-Rounder: Balanced Activity (default)
  let playStyle = 'All-Rounder'
  if (matches.length > 0) {
    const createRatio = createdCount / matches.length
    if (createRatio >= 0.4) {
      playStyle = 'Organizer'
    } else if (winRate >= 70) {
      playStyle = 'Attacker'
    } else if (winRate < 50 && matches.length >= 5) {
      playStyle = 'Defender'
    }
  }

  // Global Rank: improves as XP increases
  const rankNum = Math.max(1, 1000 - Math.floor(xp / 5))
  const globalRank = `#${rankNum} Kochi`

  return {
    xp,
    level,
    currentLevelXp,
    nextLevelXp,
    progressPct,
    winRate,
    streak,
    playStyle,
    globalRank,
    totalGames: matches.length
  }
})

// Calculate per-match XP for Activity Log display
const getMatchXp = (match) => {
  const uid = props.isCurrentUser ? store.state.currentUser?.id : props.userId
  const isCreator = Number(match.creator_id || match.user_id) === Number(uid)
  const isWin = isMatchWin(match, uid)

  let matchXp = isCreator ? 20 : 5   // Create or Join
  matchXp += 15                       // Complete
  if (isWin) matchXp += 25            // Win
  return matchXp
}

// Date Formatting Helper
const formatDate = (dateStr) => {
  if (!dateStr) return ''
  try {
    const d = new Date(dateStr)
    if (isNaN(d.getTime())) return dateStr
    return d.toLocaleDateString(store.state.language === 'hi' ? 'hi-IN' : 'en-US', {
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    })
  } catch (e) {
    return dateStr
  }
}

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
const showSettingsModal = ref(false)
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

// Instagram Account Linking
const linkingLoading = ref(false)

const handleLinkInstagram = async () => {
  if (currentUser.value.instagram_id) {
    emit('toast-message', 'Your Instagram account is already linked! 📸')
    return
  }

  linkingLoading.value = true
  try {
    const res = await fetch('/api/auth/instagram/url')
    const data = await res.json()
    if (data && data.url) {
      const width = 450
      const height = 650
      const left = (window.screen.width - width) / 2
      const top = (window.screen.height - height) / 2
      
      window.open(
        data.url,
        'InstagramLoginPopup',
        `width=${width},height=${height},left=${left},top=${top},personalbar=0,toolbar=0,scrollbars=0,resizable=0`
      )
    } else {
      throw new Error('Could not retrieve Instagram authorization URL')
    }
  } catch (err) {
    emit('toast-message', err.message || 'Failed to initialize Instagram linking ❌')
  } finally {
    linkingLoading.value = false
  }
}

const handleMessageEvent = async (event) => {
  const allowedOrigins = [
    window.location.origin,
    'https://localhost:5173',
    'https://127.0.0.1:5173'
  ]
  if (!allowedOrigins.includes(event.origin)) return
  
  if (event.data && event.data.type === 'instagram_link_success') {
    emit('toast-message', 'Instagram account linked successfully! 🎉')
    showSettingsModal.value = false
    await store.init()
  } else if (event.data && event.data.type === 'instagram_link_failed') {
    emit('toast-message', event.data.message || 'Instagram linking failed ❌')
  }
}

onMounted(() => {
  window.addEventListener('message', handleMessageEvent)
})

onUnmounted(() => {
  window.removeEventListener('message', handleMessageEvent)
})
</script>

<template>
  <div 
    class="profile-container scrollable-y animate-fade-in"
    :style="{ background: `linear-gradient(180deg, ${currentSportColor}2E 0%, var(--scaffold-bg) 350px, var(--scaffold-bg) 100%)` }"
  >
    <!-- Custom Header -->
    <div class="profile-header">
      <h2 class="title">{{ t('playerProfile') }}</h2>
      <button v-if="isCurrentUser" class="settings-nav-btn" @click="showSettingsModal = true">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="menu-svg"><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
      </button>
    </div>

    <!-- Profile Info Card -->
    <div class="profile-card">
      <div class="avatar-wrap">
        <img :src="avatarUrl" class="card-avatar" @error="(e) => e.target.src = '/assets/images/players/download.jpg'" />
        <span class="avatar-online-dot"></span>
        <button v-if="isCurrentUser" class="camera-btn" @click="fileInput.click()" :disabled="isUploading">
          <span v-if="isUploading">⏳</span>
          <svg v-else xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M4 4h3l2-3h6l2 3h3a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z"/><circle cx="12" cy="13" r="4"/></svg>
        </button>
        <input 
          ref="fileInput"
          type="file"
          accept="image/*"
          style="display: none"
          @change="onFileSelected"
        />
      </div>

      <div class="name-row">
        <h3 class="card-name">{{ currentUser.name }}</h3>
        <span class="verified-badge">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="#00a3ff"><path d="M23 12l-2.44-2.78.34-3.68-3.61-.82-1.89-3.18L12 3 8.6 1.54 6.71 4.72l-3.61.81.34 3.68L1 12l2.44 2.78-.34 3.69 3.61.82 1.89 3.18L12 21l3.4 1.46 1.89-3.18 3.61-.82-.34-3.68L23 12zm-13 5l-4-4 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>
        </span>
      </div>

      <div class="card-badges-row">
        <span class="badge-item-inline text-green">
          🔥 {{ currentUser.skill_tier === 'Professional' || currentUser.skill_tier === 'Advanced' ? 'PRO PLAYER' : 'PLAYER' }}
        </span>
        <span class="badge-separator">•</span>
        <span class="badge-item-inline text-gray">
          🇮🇳 {{ currentUser.location || 'Kochi, IN' }}
        </span>
      </div>
    </div>

    <!-- XP Progression Card -->
    <div class="xp-card">
      <div class="xp-header-row">
        <span class="xp-title">
          <span class="lightning-icon">⚡</span>
          {{ t('level') }} {{ profileStats.level }} Player
        </span>
        <span class="xp-fraction">{{ profileStats.currentLevelXp }} / {{ profileStats.nextLevelXp }} XP</span>
      </div>
      
      <div class="xp-progress-bar">
        <div class="xp-progress-fill" :style="{ width: profileStats.progressPct + '%' }"></div>
      </div>
      
      <div class="xp-footer-row">
        <span class="xp-progress-pct">Progress to Level {{ profileStats.level + 1 }}: {{ profileStats.progressPct }}%</span>
        <span v-if="profileStats.streak > 0" class="xp-streak-tag">🔥 {{ profileStats.streak }} Match Winning Streak</span>
        <span v-else class="xp-streak-tag">Start playing to build a streak!</span>
      </div>
    </div>

    <!-- Stats Grid (2x2) -->
    <div class="new-stats-grid">
      <!-- Card 1: Win Rate -->
      <div class="new-stat-card">
        <div class="stat-header">
          <span class="stat-card-title">{{ t('winRate') }}</span>
          <span class="stat-svg-container">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="stat-card-svg"><path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6"/><path d="M18 9h1.5a2.5 2.5 0 0 0 0-5H18"/><path d="M4 22h16"/><path d="M10 14.66V17c0 .55-.45 1-1 1H4v2h16v-2h-5c-.55 0-1-.45-1-1v-2.34"/><path d="M12 2a6 6 0 0 1 6 6v3.5a6 6 0 0 1-6 6 6 6 0 0 1-6-6V8a6 6 0 0 1 6-6z"/></svg>
          </span>
        </div>
        <div class="stat-card-value">{{ profileStats.winRate }}%</div>
      </div>
      
      <!-- Card 2: Play Style -->
      <div class="new-stat-card">
        <div class="stat-header">
          <span class="stat-card-title">{{ t('playStyle') }}</span>
          <span class="stat-svg-container">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#06b6d4" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="stat-card-svg"><polyline points="22 7 13.5 15.5 8.5 10.5 2 17"/><polyline points="16 7 22 7 22 13"/></svg>
          </span>
        </div>
        <div class="stat-card-value">{{ profileStats.playStyle }}</div>
      </div>

      <!-- Card 3: Total Games -->
      <div class="new-stat-card">
        <div class="stat-header">
          <span class="stat-card-title">{{ t('totalGames') }}</span>
          <span class="stat-svg-container">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#10b981" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="stat-card-svg"><circle cx="12" cy="12" r="10"/><path d="m12 2-1.91 3.42L6.2 5.09M12 22l1.91-3.42 3.89.33M2.05 12.5l3.82-.76-.36-3.89M21.95 11.5l-3.82.76.36 3.89M12 7.5 9 9.5v3l3 2 3-2v-3Z"/><path d="M9 9.5 6.2 5.09M9 12.5l-3.48 2.54M12 14.5v3.42M15 12.5l3.48 2.54M15 9.5l2.8-4.41"/></svg>
          </span>
        </div>
        <div class="stat-card-value">{{ profileStats.totalGames }} {{ t('played') }}</div>
      </div>

      <!-- Card 4: Global Rank -->
      <div class="new-stat-card">
        <div class="stat-header">
          <span class="stat-card-title">{{ t('globalRank') }}</span>
          <span class="stat-svg-container">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#3b82f6" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="stat-card-svg"><circle cx="12" cy="12" r="10"/><path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"/><path d="M2 12h20"/></svg>
          </span>
        </div>
        <div class="stat-card-value">{{ profileStats.globalRank }}</div>
      </div>
    </div>

    <!-- Friends & Share Card -->
    <div class="friends-card">
      <div class="friends-left">
        <div class="friends-avatars">
          <img src="/assets/images/players/download.jpg" class="friend-avatar-overlap" />
          <img src="/assets/images/players/download.jpg" class="friend-avatar-overlap" />
          <img src="/assets/images/players/download.jpg" class="friend-avatar-overlap" />
          <img src="/assets/images/players/download.jpg" class="friend-avatar-overlap" />
        </div>
        <div class="friends-info-text">
          <span class="friends-count">48 {{ t('friends') }}</span>
          <span class="friends-online">12 {{ t('onlinePlayPals') }}</span>
        </div>
      </div>
      <button class="share-pill-btn" @click="handleShareProfile">
        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="share-icon-svg"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.59" y1="13.51" x2="15.42" y2="17.49"/><line x1="15.41" y1="6.51" x2="8.59" y2="10.49"/></svg>
        {{ t('share') }}
      </button>
    </div>

    <!-- Favorite Sports Interests -->
    <div class="sports-rating-section">
      <h4 class="section-sub-title">{{ t('favoriteSportsInterests') }}</h4>
      
      <div class="chips-slider">
        <button 
          v-for="sport in sportsList" 
          :key="sport.name"
          class="sport-chip"
          :class="{ active: selectedSport === sport.name }"
          :style="selectedSport === sport.name ? { backgroundColor: '#2e7d32', borderColor: '#2e7d32', color: '#ffffff' } : { backgroundColor: '#ffffff', borderColor: '#cbd5e1', color: '#0f172a' }"
          @click="selectedSport = sport.name"
        >
          <span class="chip-emoji">{{ sport.icon }}</span>
          {{ t('sport_' + sport.name) }}
        </button>
      </div>
    </div>

    <!-- Achievements segments selector -->
    <div class="segmented-bar">
      <button 
        class="segment-btn" 
        :class="{ active: activeSegmentTab === 0 }"
        @click="activeSegmentTab = 0"
      >
        {{ t('activityLog') }}
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
      <div v-if="activeSegmentTab === 0" class="panel-content-new animate-fade-in">
        <template v-if="playedMatches.length > 0">
          <div v-for="match in visibleActivities" :key="match.id" class="activity-tile-new">
            <div class="activity-left">
              <span 
                class="activity-icon-circle"
                :class="Number(match.creator_id || match.user_id) === Number(props.isCurrentUser ? store.state.currentUser?.id : props.userId) ? 'bg-light-green' : 'bg-light-blue'"
                style="display: flex; align-items: center; justify-content: center; font-size: 1.1rem;"
              >
                <span>{{ match.sport_type === 'Football' ? '⚽' : match.sport_type === 'Cricket' ? '🏏' : match.sport_type === 'Basketball' ? '🏀' : match.sport_type === 'Tennis' ? '🎾' : match.sport_type === 'Badminton' ? '🏸' : match.sport_type === 'Padel' ? '🏓' : '🏃' }}</span>
              </span>
              <div class="activity-info-new">
                <span class="activity-title-new">
                  {{ Number(match.creator_id || match.user_id) === Number(props.isCurrentUser ? store.state.currentUser?.id : props.userId) ? 'Organized' : 'Joined' }} 
                  {{ match.sport_type || 'Sports' }} Match
                </span>
                <span class="activity-desc-new">{{ match.title }} at {{ match.location }} • {{ formatDate(match.date_time || match.date) }}</span>
              </div>
            </div>
            <span class="xp-badge-new">
              +{{ getMatchXp(match) }} XP
            </span>
          </div>
          <div v-if="playedMatches.length > 4" class="see-all-container">
            <button class="see-all-btn" @click="showAllActivities = !showAllActivities">
              {{ showAllActivities ? 'See Less' : 'See All' }}
            </button>
          </div>
        </template>
        <div v-else class="activity-empty-state" style="text-align: center; padding: 32px 16px; color: var(--outline); font-size: 0.88rem; font-weight: 500;">
          No matches played yet. Join or organize a match to get started! ⚽
        </div>
      </div>

      <!-- Achievements -->
      <div v-else-if="activeSegmentTab === 1" class="panel-content achievements animate-fade-in" style="display: flex; flex-direction: column; gap: 10px;">
        <div class="badge-item">🤝 Fair Play Badge</div>
        <div v-if="playedMatches.length > 0" class="badge-item">🏅 First Match Played</div>
        <div v-if="playedMatches.length >= 5" class="badge-item">🔥 5 Match Veteran</div>
        <div v-if="playedMatches.length >= 10" class="badge-item">🏆 Decathlete</div>
        <div v-if="playedMatches.some(m => Number(m.creator_id || m.user_id) === Number(props.isCurrentUser ? store.state.currentUser?.id : props.userId))" class="badge-item">👑 Community Host</div>
      </div>

      <!-- Streaks -->
      <div v-else class="panel-content streaks animate-fade-in">
        <div class="streak-details" style="display: flex; align-items: baseline; gap: 8px;">
          <span class="streak-large" style="font-size: 2rem; font-weight: 800; color: #f97316;">{{ profileStats.streak }}</span>
          <span class="streak-label" style="font-size: 0.9rem; font-weight: 600; color: var(--on-surface-variant);">{{ t('consecutiveWeekly') }}</span>
        </div>
      </div>
    </div>

    <!-- Settings Full-Screen Panel -->
    <Transition name="settings-slide">
      <div v-if="showSettingsModal" class="settings-fullscreen-panel" :class="{ 'theme-women': store.isWomenMode.value }">
        <div class="settings-panel-header">
          <h2 class="settings-panel-title">{{ t('settings') }}</h2>
          <button class="settings-close-btn" @click="showSettingsModal = false">
            <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
          </button>
        </div>

        <div class="settings-panel-body scrollable-y">
          <!-- Personalization section -->
          <div class="privacy-section">
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
          <div class="settings-menu-list">
            <div class="menu-tile" @click="() => { showSettingsModal = false; openEditModal(); }">
              <span class="menu-icon">✏️</span>
              <div class="menu-info">
                <span class="menu-title">{{ t('editProfile') }}</span>
                <span class="menu-subtitle">Update display name, bio, and settings</span>
              </div>
              <span class="chevron">➔</span>
            </div>

            <!-- Link Instagram -->
            <div class="menu-tile" :class="{ 'disabled': linkingLoading || currentUser.instagram_id }" @click="handleLinkInstagram">
              <span class="menu-icon">📸</span>
              <div class="menu-info">
                <span class="menu-title">{{ currentUser.instagram_id ? 'Instagram Linked' : 'Link Instagram' }}</span>
                <span class="menu-subtitle">
                  {{ currentUser.instagram_id ? `@${currentUser.username || 'Linked'}` : 'Connect your Instagram account' }}
                </span>
              </div>
              <span v-if="linkingLoading" class="loader menu-loader"></span>
              <span v-else-if="currentUser.instagram_id" class="check-icon">✓</span>
              <span v-else class="chevron">➔</span>
            </div>

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

            <div class="menu-tile destructive" @click="() => { showSettingsModal = false; handleLogout(); }">
              <span class="menu-icon">🚪</span>
              <div class="menu-info">
                <span class="menu-title">{{ t('signOut') }}</span>
                <span class="menu-subtitle">{{ t('signOutSub') }}</span>
              </div>
              <span class="chevron">➔</span>
            </div>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Edit Profile Modal -->
    <Teleport to="body">
      <div v-if="showEditModal" class="modal-backdrop" :class="{ 'theme-women': store.isWomenMode.value }" @click="showEditModal = false">
        <div class="modal-sheet animate-slide-up" @click.stop>
          <div class="modal-header">
            <h2 class="modal-title">{{ t('editProfile') }}</h2>
            <button class="close-btn" @click="showEditModal = false">✕</button>
          </div>

          <div class="modal-body scrollable-y">
            <!-- Name -->
            <div class="input-group">
              <label class="input-label">{{ t('displayName') }}</label>
              <input 
                v-model="editName"
                type="text" 
                placeholder="e.g. Champ"
                class="form-input"
              />
            </div>

            <!-- Bio -->
            <div class="input-group">
              <label class="input-label">{{ t('bioLabel') }}</label>
              <textarea 
                v-model="editBio"
                :placeholder="t('bioPlaceholder')"
                class="form-textarea"
                rows="3"
                maxlength="500"
              ></textarea>
            </div>

            <!-- Primary Sport -->
            <div class="input-group">
              <label class="input-label">{{ t('primarySport') }}</label>
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
                  <span class="chip-emoji">{{ sport.icon }}</span> {{ t('sport_' + sport.name) }}
                </button>
              </div>
            </div>

            <!-- Gender & Skill Level in a row -->
            <div class="form-row">
              <div class="input-group half">
                <label class="input-label">{{ t('gender') }}</label>
                <select v-model="editGender" class="form-select">
                  <option value="male">{{ t('genderMale') }}</option>
                  <option value="female">{{ t('genderFemale') }}</option>
                </select>
              </div>
              <div class="input-group half">
                <label class="input-label">{{ t('skillTier') }}</label>
                <select v-model="editSkill" class="form-select">
                  <option value="Beginner">{{ t('skill_Beginner') }}</option>
                  <option value="Intermediate">{{ t('skill_Intermediate') }}</option>
                  <option value="Advanced">{{ t('skill_Advanced') }}</option>
                  <option value="Professional">{{ t('skill_Professional') }}</option>
                </select>
              </div>
            </div>

            <!-- Submit Button -->
            <button class="submit-btn" :disabled="isSavingProfile" @click="saveProfileDetails">
              <span v-if="isSavingProfile" class="loader"></span>
              <span v-else>{{ t('saveChanges') }}</span>
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
  font-size: 1.6rem;
  font-weight: 800;
  color: #0f172a;
}

.settings-nav-btn {
  background-color: #ffffff;
  border: none;
  width: 44px;
  height: 44px;
  border-radius: 50%;
  display: flex;
  justify-content: center;
  align-items: center;
  cursor: pointer;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.04);
  color: #0f172a;
  transition: all 0.2s ease;
}

.settings-nav-btn:hover {
  transform: scale(1.05);
}

.profile-card {
  background-color: #ffffff;
  border: none;
  border-radius: 32px;
  padding: 36px 24px 28px;
  display: flex;
  flex-direction: column;
  align-items: center;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.02);
  margin-bottom: 24px;
  position: relative;
  overflow: hidden;
}

.profile-card::before {
  content: '';
  position: absolute;
  top: -40px;
  right: -40px;
  width: 140px;
  height: 140px;
  border-radius: 50%;
  background-color: rgba(209, 229, 217, 0.35);
  z-index: 1;
}

.avatar-wrap {
  position: relative;
  margin-bottom: 16px;
  z-index: 2;
}

.card-avatar {
  width: 120px;
  height: 120px;
  border-radius: 50%;
  object-fit: cover;
  padding: 6px;
  border: 3px solid #00c49f;
  background-color: #ffffff;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.05);
}

.avatar-online-dot {
  position: absolute;
  top: 8px;
  right: 8px;
  width: 16px;
  height: 16px;
  background-color: #4caf50;
  border: 3px solid #ffffff;
  border-radius: 50%;
  z-index: 3;
}

.camera-btn {
  position: absolute;
  bottom: 6px;
  right: 6px;
  background-color: #00c49f;
  border: 3px solid #ffffff;
  width: 34px;
  height: 34px;
  border-radius: 50%;
  color: #ffffff;
  display: flex;
  justify-content: center;
  align-items: center;
  cursor: pointer;
  z-index: 3;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  transition: all 0.2s ease;
}

.camera-btn:hover {
  transform: scale(1.05);
}

.name-row {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 8px;
  z-index: 2;
}

.card-name {
  font-size: 1.4rem;
  font-weight: 800;
  color: #0f172a;
}

.verified-badge {
  display: flex;
  align-items: center;
}

.card-badges-row {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.78rem;
  font-weight: 700;
  letter-spacing: 0.5px;
  margin-bottom: 12px;
  z-index: 2;
}

.badge-item-inline.text-green {
  color: #2e7d32;
}

.badge-item-inline.text-gray {
  color: #64748b;
}

.badge-separator {
  color: #cbd5e1;
}

/* XP Progression Card */
.xp-card {
  background-color: #ffffff;
  border-radius: 24px;
  padding: 24px;
  margin-bottom: 24px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.02);
}

.xp-header-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.xp-title {
  font-size: 0.95rem;
  font-weight: 800;
  color: #0f172a;
  display: flex;
  align-items: center;
  gap: 4px;
}

.lightning-icon {
  color: #0e906c;
}

.xp-fraction {
  font-size: 0.82rem;
  font-weight: 700;
  color: #475569;
}

.xp-progress-bar {
  height: 12px;
  background-color: #f1f5f9;
  border-radius: 6px;
  overflow: hidden;
  margin-bottom: 12px;
}

.xp-progress-fill {
  height: 100%;
  background-color: #00c49f;
  border-radius: 6px;
}

.xp-footer-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.72rem;
  font-weight: 700;
}

.xp-progress-pct {
  color: #64748b;
}

.xp-streak-tag {
  color: #f97316;
}

/* Stats grid */
.new-stats-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
  margin-bottom: 24px;
}

.new-stat-card {
  background-color: #ffffff;
  border-radius: 20px;
  padding: 20px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.02);
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  min-height: 100px;
}

.stat-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.stat-card-title {
  font-size: 0.78rem;
  font-weight: 700;
  color: #64748b;
}

.stat-card-icon {
  font-size: 1.1rem;
}

.stat-card-value {
  font-size: 1.25rem;
  font-weight: 800;
  color: #0f172a;
}

/* Friends & Share Card */
.friends-card {
  background-color: #ffffff;
  border-radius: 24px;
  padding: 16px 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.02);
  margin-bottom: 28px;
}

.friends-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.friends-avatars {
  display: flex;
  align-items: center;
}

.friend-avatar-overlap {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  object-fit: cover;
  border: 2px solid #ffffff;
  margin-left: -10px;
}

.friend-avatar-overlap:first-child {
  margin-left: 0;
}

.friends-info-text {
  display: flex;
  flex-direction: column;
}

.friends-count {
  font-size: 0.88rem;
  font-weight: 800;
  color: #0f172a;
}

.friends-online {
  font-size: 0.72rem;
  color: #0e906c;
  font-weight: 700;
}

.share-pill-btn {
  background-color: #2e7d32;
  border: none;
  padding: 10px 20px;
  border-radius: 24px;
  color: #ffffff;
  font-size: 0.82rem;
  font-weight: 700;
  display: flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  box-shadow: 0 4px 12px rgba(46, 125, 50, 0.15);
  transition: all 0.2s ease;
}

.share-pill-btn:hover {
  filter: brightness(1.1);
  transform: translateY(-1px);
}

.share-icon-svg {
  display: flex;
  align-items: center;
}

/* Sports ratings selection */
.sports-rating-section {
  margin-bottom: 28px;
}

/* Segmented selector */
.segmented-bar {
  display: flex;
  gap: 16px;
  background-color: transparent;
  border-radius: 0;
  padding: 0;
  margin-bottom: 20px;
}

.segment-btn {
  border: none;
  background: none;
  padding: 8px 16px;
  font-size: 0.88rem;
  font-weight: 700;
  border-radius: 20px;
  color: #64748b;
  cursor: pointer;
  transition: all 0.2s ease;
}

.segment-btn.active {
  background-color: #e2f0e9;
  color: #2e7d32;
  box-shadow: none;
}

.segment-panel {
  margin-bottom: 28px;
}

.panel-content-new {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.activity-tile-new {
  background-color: #ffffff;
  border-radius: 20px;
  padding: 16px 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.02);
}

.activity-left {
  display: flex;
  align-items: center;
  gap: 14px;
}

.activity-icon-circle {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  display: flex;
  justify-content: center;
  align-items: center;
  font-size: 1.2rem;
}

.activity-icon-circle.bg-light-green {
  background-color: #e8f5e9;
}

.activity-icon-circle.bg-light-blue {
  background-color: #e3f2fd;
}

.activity-icon-circle.bg-light-yellow {
  background-color: #fffde7;
}

.activity-info-new {
  display: flex;
  flex-direction: column;
}

.activity-title-new {
  font-size: 0.88rem;
  font-weight: 800;
  color: #0f172a;
}

.activity-desc-new {
  font-size: 0.72rem;
  color: #64748b;
  font-weight: 600;
}

.xp-badge-new {
  background-color: #e8f5e9;
  color: #2e7d32;
  font-size: 0.75rem;
  font-weight: 800;
  padding: 6px 12px;
  border-radius: 12px;
}

.see-all-container {
  display: flex;
  justify-content: center;
  margin-top: 8px;
  margin-bottom: 8px;
}

.see-all-btn {
  background-color: transparent;
  border: 1.5px solid var(--primary);
  color: var(--primary);
  padding: 8px 24px;
  border-radius: 24px;
  font-size: 0.82rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s ease;
}

.see-all-btn:hover {
  background-color: var(--primary);
  color: var(--on-primary);
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(46, 125, 50, 0.1);
}

.see-all-btn:active {
  transform: translateY(0);
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

.menu-tile.disabled {
  cursor: default;
}

.menu-tile.disabled:hover {
  background-color: var(--surface);
}

.menu-loader {
  border-color: var(--primary);
  border-bottom-color: transparent;
}

.check-icon {
  color: #4caf50;
  font-weight: bold;
  font-size: 1.1rem;
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

/* Settings Full-Screen Panel */
.settings-fullscreen-panel {
  position: fixed;
  top: 0;
  right: 0;
  width: calc(100% - 280px);
  height: 100vh;
  background-color: var(--scaffold-bg);
  z-index: 1200;
  display: flex;
  flex-direction: column;
  box-shadow: -8px 0 40px rgba(0, 0, 0, 0.08);
}

@media (max-width: 768px) {
  .settings-fullscreen-panel {
    width: 100%;
    left: 0;
  }
}

.settings-panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 28px 40px 20px;
  border-bottom: 1px solid var(--outline-variant);
  background-color: var(--surface);
  flex-shrink: 0;
}

.settings-panel-title {
  font-family: var(--font-display);
  font-size: 1.6rem;
  font-weight: 800;
  color: var(--on-surface);
  letter-spacing: -0.5px;
}

.settings-close-btn {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: 1px solid var(--outline-variant);
  background-color: var(--surface);
  color: var(--on-surface-variant);
  display: flex;
  justify-content: center;
  align-items: center;
  cursor: pointer;
  transition: all 0.2s ease;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
}

.settings-close-btn:hover {
  background-color: var(--scaffold-bg);
  color: var(--error, #ba1a1a);
  border-color: var(--error, #ba1a1a);
  transform: rotate(90deg);
}

.settings-panel-body {
  flex: 1;
  overflow-y: auto;
  padding: 32px 40px;
  max-width: 640px;
}

/* Slide-in transition for settings panel */
.settings-slide-enter-active {
  animation: settingsSlideIn 0.35s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

.settings-slide-leave-active {
  animation: settingsSlideOut 0.25s ease-in forwards;
}

@keyframes settingsSlideIn {
  from {
    transform: translateX(100%);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

@keyframes settingsSlideOut {
  from {
    transform: translateX(0);
    opacity: 1;
  }
  to {
    transform: translateX(100%);
    opacity: 0;
  }
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
