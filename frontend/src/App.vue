<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { store } from './store'
import { getPlayerAvatar } from './utils/sportImageHelper'
import { t } from './utils/i18n'

// Authentication
import LoginRegister from './components/LoginRegister.vue'

// Screens
import HomeScreen from './views/HomeScreen.vue'
import ExploreScreen from './views/ExploreScreen.vue'
import MatchesScreen from './views/MatchesScreen.vue'
import ActivityFeedScreen from './views/ActivityFeedScreen.vue'
import ProfileScreen from './views/ProfileScreen.vue'

// Modal sheets overlays
import PlayerRevealCard from './components/PlayerRevealCard.vue'
import CreateMatchModal from './components/CreateMatchModal.vue'
import MatchDetailsModal from './components/MatchDetailsModal.vue'
import AdvancedSearchModal from './components/AdvancedSearchModal.vue'
import NotificationsModal from './components/NotificationsModal.vue'

// Bottom/Sidebar Tab Navigation State
const currentTab = ref('home') // 'home', 'explore', 'matches', 'activity', 'profile'
const profileTargetUser = ref(null)

// Modal States
const showPlayerCard = ref(false)
const selectedPlayer = ref(null)
const selectedPlayerSport = ref('Football')

const showCreateModal = ref(false)

const showDetailsModal = ref(false)
const selectedMatch = ref(null)

const showSearchModal = ref(false)
const showNotifications = ref(false)
const showEmailVerificationModal = ref(false)
const hasDismissedEmailWarning = ref(false)

const goToProfile = () => {
  hasDismissedEmailWarning.value = true
  showEmailVerificationModal.value = false
  switchTab('profile')
}

const dismissWarning = () => {
  hasDismissedEmailWarning.value = true
  showEmailVerificationModal.value = false
}

watch(() => store.state.currentUser, (newVal) => {
  console.log('User state changed:', newVal ? { id: newVal.id, username: newVal.username, email: newVal.email } : null)
  if (newVal && !newVal.email && !hasDismissedEmailWarning.value) {
    showEmailVerificationModal.value = true
  } else {
    showEmailVerificationModal.value = false
  }
}, { immediate: true })

// Toast Notifications state
const showSnackbar = ref(false)
const snackbarText = ref('')
let snackbarTimeout = null

const triggerSnackbar = (message) => {
  snackbarText.value = message
  showSnackbar.value = true
  if (snackbarTimeout) clearTimeout(snackbarTimeout)
  snackbarTimeout = setTimeout(() => {
    showSnackbar.value = false
  }, 3000)
}

const snackbarIcon = computed(() => {
  const text = snackbarText.value.toLowerCase()
  if (text.includes('coming soon')) return '⏳'
  if (text.includes('welcome') || text.includes('morning') || text.includes('afternoon') || text.includes('evening')) return '👋'
  if (text.includes('rated') || text.includes('star')) return '⭐'
  if (text.includes('filtered') || text.includes('search')) return '🔍'
  if (text.includes('share') || text.includes('shared')) return '🔗'
  if (text.includes('sign') || text.includes('exit') || text.includes('out')) return '🚪'
  if (text.includes('success')) return '✅'
  return '🔔'
})

// Auth state
const isAuthenticated = computed(() => {
  return store.state.currentUser !== null
})

watch(isAuthenticated, (newVal) => {
  if (!newVal) {
    currentTab.value = 'home'
  }
})

const currentUser = computed(() => {
  return store.state.currentUser || { name: 'Champ', gender: 'male', profilePhotoUrl: null }
})

const currentUserAvatar = computed(() => {
  return getPlayerAvatar(currentUser.value.profilePhotoUrl, currentUser.value.gender)
})

const switchTab = (tabName) => {
  if (tabName === 'profile') {
    profileTargetUser.value = null
  }
  currentTab.value = tabName
  showDetailsModal.value = false
  store.init() // Silently refresh matches, feeds, and profiles
}

const viewUserProfile = (player) => {
  if (player && (Number(player.id) === Number(currentUser.value.id) || player.name === currentUser.value.name)) {
    switchTab('profile')
  } else {
    profileTargetUser.value = player
    showDetailsModal.value = false
    currentTab.value = 'profile'
    store.init()
  }
}

const handlePendingShareMatch = async () => {
  const matchId = sessionStorage.getItem('pending_share_match')
  if (!matchId) return
  sessionStorage.removeItem('pending_share_match')
  
  try {
    await store.init()
    const match = store.state.matches.find(m => String(m.id) === String(matchId))
    if (match) {
      openMatchDetails(match)
    } else {
      const res = await fetch(`/api/matches/${matchId}`, {
        headers: {
          'Authorization': `Bearer ${sessionStorage.getItem('sportigo_token')}`,
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        }
      })
      if (res.ok) {
        const matchData = await res.json()
        openMatchDetails(matchData)
      }
    }
  } catch (e) {
    console.error('Failed to open pending shared match:', e)
  }
}

const handleAuthSuccess = () => {
  const hour = new Date().getHours()
  let greet = 'Good evening'
  if (hour < 12) greet = 'Good morning'
  else if (hour < 17) greet = 'Good afternoon'
  
  triggerSnackbar(`${greet}, ${currentUser.value.name}! 👋`)
  switchTab('home')
  handlePendingShareMatch()
}

onMounted(() => {
  const params = new URLSearchParams(window.location.search)
  const matchId = params.get('match')
  if (matchId) {
    sessionStorage.setItem('pending_share_match', matchId)
  }
  if (store.state.currentUser) {
    handlePendingShareMatch()
  }
})

// Modal actions
const openPlayerReveal = (player, sport) => {
  if (player && (Number(player.id) === Number(currentUser.value.id) || player.name === currentUser.value.name)) {
    switchTab('profile')
  } else {
    selectedPlayer.value = player
    selectedPlayerSport.value = sport || 'Football'
    showPlayerCard.value = true
  }
}

const showUnfollowConfirm = ref(false)
const playerToUnfollow = ref(null)

const handleToggleFollow = async (player) => {
  if (player.isFollowed) {
    playerToUnfollow.value = player
    showUnfollowConfirm.value = true
  } else {
    try {
      const res = await store.followPlayer(player.id)
      if (res && res.success) {
        player.isFollowed = true
        player.followersCount = res.followersCount
        triggerSnackbar(`Following ${player.name}! 🎉`)
      }
    } catch (err) {
      console.error('Follow failed in App:', err)
    }
  }
}

const confirmUnfollow = async () => {
  if (!playerToUnfollow.value) return
  showUnfollowConfirm.value = false
  const player = playerToUnfollow.value
  
  try {
    const res = await store.unfollowPlayer(player.id)
    if (res && res.success) {
      player.isFollowed = false
      player.followersCount = res.followersCount
      triggerSnackbar(`Unfollowed ${player.name}! 👥`)
    }
  } catch (err) {
    console.error('Unfollow failed in App:', err)
  }
}

const handleWaveSuccess = async (player) => {
  if (!player || !player.id) return
  triggerSnackbar(`Waved at ${player.name}! 👋`)
  try {
    await store.wavePlayer(player.id)
  } catch (err) {
    console.error('Failed to send wave:', err)
  }
}

const openMatchDetails = (match) => {
  selectedMatch.value = match
  showDetailsModal.value = true
}

const handleApplyFilters = async (filters) => {
  try {
    const backendFilters = {}
    if (filters.search) backendFilters.search = filters.search
    if (filters.sport && filters.sport !== 'All') backendFilters.sportType = filters.sport
    if (filters.skill && filters.skill !== 'All') backendFilters.skillLevel = filters.skill

    await store.fetchMatches(backendFilters)
    triggerSnackbar(`Filtered search applied!`)
  } catch (e) {
    console.error('Failed to filter matches:', e)
    triggerSnackbar(`Failed to apply filters`)
  }
}

// Theme selector
const isWomenTheme = computed(() => {
  return store.isWomenMode.value
})
</script>

<template>
  <div class="web-layout-root" :class="{ 'theme-women': isWomenTheme }">
    <!-- Unauthenticated layout -->
    <div v-if="!isAuthenticated" class="auth-viewport">
      <!-- Left decorative hero split (visible on desktop) -->
      <div class="auth-hero-split">
        <div class="hero-overlay"></div>
        <div class="hero-content">
          <div class="hero-logo">
            <span class="hero-logo-icon">⚡</span>
            <span class="hero-logo-text">PlayConnect</span>
          </div>
          <h1 class="hero-title">Your Next Match Is Just a Click Away</h1>
          <p class="hero-desc">
            Join the ultimate sports matchmaking community. Discover local friendly games, book slots, coordinate with players, and get on the court today.
          </p>
          <div class="hero-stats">
            <div class="stat-card">
              <span class="stat-num">5,000+</span>
              <span class="stat-lbl">Active Players</span>
            </div>
            <div class="stat-card">
              <span class="stat-num">120+</span>
              <span class="stat-lbl">Matches Daily</span>
            </div>
            <div class="stat-card">
              <span class="stat-num">15+</span>
              <span class="stat-lbl">Venues Mapped</span>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Right auth form split -->
      <div class="auth-form-split">
        <div class="auth-form-container">
          <LoginRegister @auth-success="handleAuthSuccess" />
        </div>
      </div>
    </div>

    <!-- Authenticated layout -->
    <div v-else class="app-layout">
      <!-- Desktop Sidebar Navigation -->
      <aside class="desktop-sidebar">
        <div class="sidebar-logo">
          <span class="logo-icon">⚡</span>
          <span class="logo-text">PlayConnect</span>
        </div>
        
        <nav class="sidebar-nav">
          <button 
            class="sidebar-link" 
            :class="{ active: currentTab === 'home' }"
            @click="switchTab('home')"
          >
            <span class="link-icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="nav-svg"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
            </span>
            <span class="link-label">{{ t('home') }}</span>
          </button>

          <button 
            class="sidebar-link" 
            :class="{ active: currentTab === 'explore' }"
            @click="switchTab('explore')"
          >
            <span class="link-icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="nav-svg"><circle cx="12" cy="12" r="10"/><polygon points="16.24 7.76 14.12 14.12 7.76 16.24 9.88 9.88 16.24 7.76"/></svg>
            </span>
            <span class="link-label">{{ t('explore') }}</span>
          </button>

          <button 
            class="sidebar-link" 
            :class="{ active: currentTab === 'matches' }"
            @click="switchTab('matches')"
          >
            <span class="link-icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="nav-svg"><path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6"/><path d="M18 9h1.5a2.5 2.5 0 0 0 0-5H18"/><path d="M4 22h16"/><path d="M10 14.66V17c0 .55-.45 1-1 1H4v2h16v-2h-5c-.55 0-1-.45-1-1v-2.34"/><path d="M12 2a6 6 0 0 1 6 6v3.5a6 6 0 0 1-6 6 6 6 0 0 1-6-6V8a6 6 0 0 1 6-6z"/></svg>
            </span>
            <span class="link-label">{{ t('matches') }}</span>
          </button>

          <button 
            class="sidebar-link" 
            :class="{ active: currentTab === 'activity' }"
            @click="switchTab('activity')"
          >
            <span class="link-icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="nav-svg"><path d="m18 8-6 3V5c0-1.1-.9-2-2-2h-3c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h3c1.1 0 2-.9 2-2v-6l6 3Z"/><path d="M2 10h3v4H2z"/></svg>
            </span>
            <span class="link-label">{{ t('activity') }}</span>
          </button>

          <button 
            class="sidebar-link" 
            :class="{ active: currentTab === 'profile' }"
            @click="switchTab('profile')"
          >
            <span class="link-icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="nav-svg"><path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
            </span>
            <span class="link-label">{{ t('profile') }}</span>
          </button>
        </nav>

        <!-- Sidebar footer/user widget -->
        <div class="sidebar-footer" @click="switchTab('profile')" style="cursor: pointer;">
          <div class="footer-avatar-wrap">
            <img :src="currentUserAvatar" class="footer-avatar" @error="(e) => e.target.src = '/assets/images/players/download.jpg'" />
            <span class="online-indicator-dot"></span>
          </div>
          <div class="footer-user-details">
            <span class="footer-username">{{ currentUser.name }}</span>
            <span class="footer-user-lvl">Level 18 Player</span>
          </div>
        </div>
      </aside>

      <!-- Main screen layout viewport -->
      <div class="main-viewport-content">
        <!-- Render page based on current tab state -->
        <div class="screen-scroller">
          <div v-if="currentTab !== 'profile'" class="desktop-content-container">
            <HomeScreen 
              v-if="currentTab === 'home'"
              @open-details="openMatchDetails"
              @open-player="openPlayerReveal"
              @open-search="showSearchModal = true"
              @open-notifications="showNotifications = true"
              @open-create="showCreateModal = true"
            />
            <ExploreScreen 
              v-else-if="currentTab === 'explore'"
              @open-details="openMatchDetails"
              @open-player="openPlayerReveal"
            />
            <MatchesScreen 
              v-else-if="currentTab === 'matches'"
              @open-details="openMatchDetails"
              @open-player="openPlayerReveal"
              @open-create="showCreateModal = true"
            />
            <ActivityFeedScreen 
              v-else-if="currentTab === 'activity'"
              @open-match-details="openMatchDetails"
              @open-player="openPlayerReveal"
            />
          </div>
          <ProfileScreen 
            v-else-if="currentTab === 'profile'"
            :is-current-user="!profileTargetUser || Number(profileTargetUser.id) === Number(currentUser.id)"
            :user-id="profileTargetUser ? profileTargetUser.id : null"
            :player-name="profileTargetUser ? profileTargetUser.name : ''"
            :profile-picture="profileTargetUser ? (profileTargetUser.profilePicture || profileTargetUser.profilePhotoUrl || profileTargetUser.avatar) : null"
            @auth-logout="triggerSnackbar('Successfully signed out.')"
            @toast-message="triggerSnackbar"
            @view-profile="viewUserProfile"
          />
        </div>

        <!-- Mobile Bottom bar Navigation (Visible only on mobile screen widths) -->
        <nav class="mobile-bottom-nav">
          <button 
            class="nav-item" 
            :class="{ active: currentTab === 'home' }"
            @click="switchTab('home')"
          >
            <span class="nav-icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="nav-svg"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
            </span>
            <span class="nav-label">{{ t('home') }}</span>
          </button>

          <button 
            class="nav-item" 
            :class="{ active: currentTab === 'explore' }"
            @click="switchTab('explore')"
          >
            <span class="nav-icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="nav-svg"><circle cx="12" cy="12" r="10"/><polygon points="16.24 7.76 14.12 14.12 7.76 16.24 9.88 9.88 16.24 7.76"/></svg>
            </span>
            <span class="nav-label">{{ t('explore') }}</span>
          </button>

          <button 
            class="nav-item" 
            :class="{ active: currentTab === 'matches' }"
            @click="switchTab('matches')"
          >
            <span class="nav-icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="nav-svg"><path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6"/><path d="M18 9h1.5a2.5 2.5 0 0 0 0-5H18"/><path d="M4 22h16"/><path d="M10 14.66V17c0 .55-.45 1-1 1H4v2h16v-2h-5c-.55 0-1-.45-1-1v-2.34"/><path d="M12 2a6 6 0 0 1 6 6v3.5a6 6 0 0 1-6 6 6 6 0 0 1-6-6V8a6 6 0 0 1 6-6z"/></svg>
            </span>
            <span class="nav-label">{{ t('matches') }}</span>
          </button>

          <button 
            class="nav-item" 
            :class="{ active: currentTab === 'activity' }"
            @click="switchTab('activity')"
          >
            <span class="nav-icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="nav-svg"><path d="m18 8-6 3V5c0-1.1-.9-2-2-2h-3c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h3c1.1 0 2-.9 2-2v-6l6 3Z"/><path d="M2 10h3v4H2z"/></svg>
            </span>
            <span class="nav-label">{{ t('activity') }}</span>
          </button>

          <button 
            class="nav-item" 
            :class="{ active: currentTab === 'profile' }"
            @click="switchTab('profile')"
          >
            <span class="nav-icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="nav-svg"><path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
            </span>
            <span class="nav-label">{{ t('profile') }}</span>
          </button>
        </nav>
      </div>
    </div>

    <!-- Global Simulated Overlays -->
    
    <!-- Player Reveal Sheet -->
    <PlayerRevealCard 
      :show="showPlayerCard"
      :player="selectedPlayer || {}"
      :sport-type="selectedPlayerSport"
      @close="showPlayerCard = false"
      @wave-success="handleWaveSuccess"
      @view-profile="(p) => { 
        viewUserProfile(p);
      }"
    />

    <!-- Create Match Modal -->
    <CreateMatchModal 
      :show="showCreateModal"
      @close="showCreateModal = false"
      @match-created="triggerSnackbar"
    />

    <!-- Match Details Modal -->
    <MatchDetailsModal 
      v-if="selectedMatch"
      :show="showDetailsModal"
      :match="selectedMatch"
      @close="showDetailsModal = false"
      @open-player="openPlayerReveal"
      @action-success="triggerSnackbar"
    />

    <!-- Advanced Search Filter panel -->
    <AdvancedSearchModal 
      :show="showSearchModal"
      @close="showSearchModal = false"
      @apply-filters="handleApplyFilters"
      @open-player="openPlayerReveal"
      @open-details="openMatchDetails"
    />

    <!-- Notifications modal list -->
    <NotificationsModal 
      :show="showNotifications"
      @close="showNotifications = false"
      @open-match-details="openMatchDetails"
    />

    <!-- Toast message box -->
    <div v-if="showSnackbar" class="snackbar-container">
      <div class="snackbar-content">
        <span class="snackbar-icon">{{ snackbarIcon }}</span>
        <span class="snackbar-text">{{ snackbarText }}</span>
      </div>
      <button class="snackbar-btn" @click="showSnackbar = false">DISMISS</button>
    </div>

    <!-- Unfollow Confirmation Modal -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="showUnfollowConfirm" class="logout-confirm-backdrop" @click="showUnfollowConfirm = false">
          <div class="logout-confirm-card animate-slide-up" @click.stop>
            <div class="logout-confirm-handle"></div>
            <div class="logout-confirm-icon-wrap" style="background-color: #fee2e2;">
              <span style="font-size: 1.5rem;">💔</span>
            </div>
            <h3 class="logout-confirm-title">Unfollow {{ playerToUnfollow?.name }}?</h3>
            <p class="logout-confirm-desc">Are you sure you want to unfollow this player? You will stop seeing their match activities.</p>
            <div class="logout-confirm-actions">
              <button class="logout-btn-no" @click="showUnfollowConfirm = false">Cancel</button>
              <button class="logout-btn-yes" style="background-color: #dc2626;" @click="confirmUnfollow">Unfollow</button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- Email Verification Mandatory Popup -->
    <Transition name="fade">
      <div v-if="showEmailVerificationModal" class="email-warning-backdrop">
        <div class="email-warning-modal">
          <div class="email-warning-icon-container">
            <span class="email-warning-icon">📧</span>
          </div>
          <h3 class="email-warning-title">
            {{ store.state.language === 'hi' ? 'ईमेल सत्यापन अनिवार्य है' : 'Email Verification Mandatory' }}
          </h3>
          <p class="email-warning-message">
            {{ store.state.language === 'hi' 
              ? 'पासवर्ड भूल जाने की स्थिति में सुरक्षित खाता पुनर्प्राप्ति और प्रमाणीकरण के लिए आपके प्रोफ़ाइल में ईमेल पंजीकरण अनिवार्य है।' 
              : 'Email registration in profile is mandatory. We require a registered email address to assist with password recovery and verify your identity.' }}
          </p>
          <div class="email-warning-actions">
            <button class="email-warning-btn primary" @click="goToProfile">
              {{ store.state.language === 'hi' ? 'प्रोफ़ाइल पर जाएं' : 'Go to Profile' }}
            </button>
            <button class="email-warning-btn secondary" @click="dismissWarning">
              {{ store.state.language === 'hi' ? 'बाद में' : 'Later' }}
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Grand+Hotel&display=swap');

.web-layout-root {
  width: 100%;
  height: 100vh;
  display: flex;
  background-color: var(--scaffold-bg);
  overflow: hidden;
}

/* Auth viewport split layout */
.auth-viewport {
  width: 100%;
  height: 100vh;
  display: flex;
  background-color: var(--surface);
  overflow: hidden;
}

.auth-hero-split {
  flex: 1.2;
  height: 100%;
  position: relative;
  background-image: url('/assets/images/match_bg.png');
  background-size: cover;
  background-position: center;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 60px;
  background-color: var(--primary-container);
}

.auth-hero-split h1, 
.auth-hero-split h2, 
.auth-hero-split h3 {
  color: #ffffff !important;
}

.theme-women .auth-hero-split {
  background-color: #2d0c24;
}

.hero-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, rgba(15, 23, 42, 0.7) 0%, rgba(26, 35, 126, 0.6) 100%);
  z-index: 1;
}

.theme-women .hero-overlay {
  background: linear-gradient(135deg, rgba(255, 77, 141, 0.5) 0%, rgba(45, 12, 36, 0.7) 100%);
}

.hero-content {
  position: relative;
  z-index: 2;
  color: #ffffff;
  max-width: 600px;
  background: rgba(15, 23, 42, 0.55);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  padding: 48px;
  border-radius: var(--radius-xl);
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.35);
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.hero-logo {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 24px;
}

.hero-logo-icon {
  font-size: 1.8rem;
  background: linear-gradient(135deg, #ffffff 0%, rgba(255, 255, 255, 0.7) 100%);
  width: 50px;
  height: 50px;
  border-radius: 14px;
  display: flex;
  justify-content: center;
  align-items: center;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.15);
  color: var(--primary);
  font-weight: bold;
}

.hero-logo-text {
  font-family: var(--font-display);
  font-size: 1.6rem;
  font-weight: 800;
  letter-spacing: -0.5px;
}

.hero-title {
  font-family: var(--font-display);
  font-size: 2.8rem;
  font-weight: 800;
  line-height: 1.15;
  margin-bottom: 8px;
  letter-spacing: -1px;
}

.hero-desc {
  font-size: 1.05rem;
  line-height: 1.5;
  opacity: 0.85;
  margin-bottom: 24px;
  font-weight: 500;
}

.hero-stats {
  display: flex;
  gap: 16px;
  margin-top: 16px;
  width: 100%;
}

.stat-card {
  flex: 1;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: var(--radius-md);
  padding: 14px 8px;
  text-align: center;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  transition: all 0.25s ease;
}

.stat-card:hover {
  transform: translateY(-2px);
  background: rgba(255, 255, 255, 0.1);
  border-color: rgba(255, 255, 255, 0.2);
}

.stat-num {
  font-family: var(--font-display);
  font-size: 1.6rem;
  font-weight: 800;
  color: #ffffff;
  display: block;
  margin-bottom: 2px;
}

.stat-lbl {
  font-size: 0.72rem;
  opacity: 0.8;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: #94a3b8;
}

.auth-form-split {
  flex: 1;
  height: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 40px;
  background-color: var(--scaffold-bg);
  overflow-y: auto;
}

.auth-form-container {
  width: 100%;
  max-width: 440px;
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-lg);
  padding: 40px 32px;
  box-shadow: var(--shadow-md);
}

@media (max-width: 480px) {
  .auth-form-container {
    padding: 24px 16px;
    border: none;
    box-shadow: none;
    background-color: transparent;
  }
}

@media (max-width: 1024px) {
  .auth-hero-split {
    display: none;
  }
  .auth-viewport {
    justify-content: center;
  }
  .auth-form-split {
    padding: 20px;
  }
}

/* Master grid app layout */
.app-layout {
  width: 100%;
  height: 100%;
  display: flex;
  overflow: hidden;
  position: relative;
}

/* Sidebar navigation */
.desktop-sidebar {
  width: 280px;
  height: 100%;
  background: linear-gradient(180deg, var(--sidebar-bg) 0%, rgba(15, 23, 42, 0.9) 100%), var(--sidebar-bg);
  border-right: 1px solid rgba(255, 255, 255, 0.05);
  display: flex;
  flex-direction: column;
  padding: 32px 20px;
  flex-shrink: 0;
  z-index: 10;
  transition: all 0.3s ease;
}

.sidebar-logo {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 36px;
  padding-left: 8px;
}

.logo-icon {
  font-size: 1.3rem;
  background: linear-gradient(135deg, var(--primary) 0%, var(--secondary, #7B61FF) 100%);
  width: 40px;
  height: 40px;
  border-radius: 12px;
  display: flex;
  justify-content: center;
  align-items: center;
  box-shadow: 0 4px 14px rgba(0, 0, 0, 0.25);
  border: 1.5px solid rgba(255, 255, 255, 0.15);
  animation: pulseGlow 3s infinite;
}

.logo-text {
  font-family: var(--font-display);
  font-size: 1.35rem;
  font-weight: 800;
  color: #ffffff;
  letter-spacing: -0.5px;
  background: linear-gradient(180deg, #ffffff 0%, #cbd5e1 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.sidebar-nav {
  display: flex;
  flex-direction: column;
  gap: 8px;
  flex: 1;
}

.sidebar-link {
  display: flex;
  align-items: center;
  gap: 14px;
  background: none;
  border: none;
  padding: 12px 18px;
  border-radius: var(--radius-md);
  font-family: var(--font-sans);
  font-size: 0.92rem;
  font-weight: 700;
  color: var(--sidebar-text);
  cursor: pointer;
  text-align: left;
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
  position: relative;
}

.sidebar-link:hover {
  background-color: var(--sidebar-hover-bg);
  color: #ffffff;
  padding-left: 22px;
}

.sidebar-link .nav-svg {
  stroke: var(--sidebar-text);
  transition: stroke 0.3s ease, transform 0.3s ease;
}

.sidebar-link:hover .nav-svg {
  stroke: #ffffff;
  transform: scale(1.1);
}

.sidebar-link.active {
  background-color: var(--sidebar-hover-bg);
  color: #ffffff;
  box-shadow: inset 4px 0 0 var(--primary), 0 4px 15px rgba(0, 0, 0, 0.15);
}

.sidebar-link.active .nav-svg {
  stroke: var(--primary);
  transform: scale(1.05);
}

.theme-women .sidebar-link.active .nav-svg {
  stroke: var(--primary);
}

.link-icon {
  display: flex;
  align-items: center;
  justify-content: center;
}

.sidebar-footer {
  display: flex;
  align-items: center;
  gap: 14px;
  padding-top: 20px;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
}

.footer-avatar-wrap {
  position: relative;
  width: 44px;
  height: 44px;
  flex-shrink: 0;
}

.footer-avatar {
  width: 100%;
  height: 100%;
  border-radius: 50%;
  object-fit: cover;
  border: 2px solid var(--primary);
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.15);
}

.online-indicator-dot {
  position: absolute;
  bottom: 0;
  right: 0;
  width: 12px;
  height: 12px;
  background-color: #22c55e;
  border: 2px solid var(--sidebar-bg);
  border-radius: 50%;
  box-shadow: 0 0 0 2px rgba(34, 197, 94, 0.2);
}

.footer-user-details {
  display: flex;
  flex-direction: column;
}

.footer-username {
  font-size: 0.92rem;
  font-weight: 700;
  color: #ffffff;
}

.footer-user-lvl {
  font-size: 0.72rem;
  color: var(--sidebar-text);
  font-weight: 600;
}

/* Contents layout pane */
.main-viewport-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  height: 100%;
  overflow: hidden;
  position: relative;
  background-color: var(--scaffold-bg);
}

.screen-scroller {
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
}

.desktop-content-container {
  width: 100%;
  max-width: 1000px;
  margin: 0 auto;
  min-height: 100%;
  position: relative;
}

/* Navigation bar only visible on mobile screen sizes */
.mobile-bottom-nav {
  display: none;
}

@media (max-width: 768px) {
  .desktop-sidebar {
    display: none;
  }
  
  .mobile-bottom-nav {
    height: 68px;
    background-color: var(--surface);
    border-top: 1px solid var(--outline-variant);
    display: flex;
    justify-content: space-around;
    align-items: center;
    padding: 8px 12px 14px;
    box-shadow: 0 -4px 10px rgba(0, 0, 0, 0.03);
    position: absolute;
    bottom: 0;
    left: 0;
    width: 100%;
    z-index: 100;
  }

  .nav-item {
    background: none;
    border: none;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 2px;
    cursor: pointer;
    padding: 4px 12px;
    border-radius: 16px;
    transition: all 0.2s ease;
    color: var(--on-surface-variant);
  }

  .nav-icon {
    font-size: 1.15rem;
    opacity: 0.75;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .nav-label {
    font-size: 0.65rem;
    font-weight: 700;
  }

  .nav-item .nav-svg {
    stroke: var(--on-surface-variant);
    transition: stroke 0.2s ease;
  }

  .nav-item.active {
    background-color: rgba(26, 35, 126, 0.06);
    color: var(--primary);
  }

  .nav-item.active .nav-svg {
    stroke: var(--primary);
  }

  .theme-women .nav-item.active {
    background-color: rgba(255, 77, 141, 0.08);
    color: var(--primary);
  }

  .theme-women .nav-item.active .nav-svg {
    stroke: var(--primary);
  }
}

.logout-confirm-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.45);
  backdrop-filter: blur(6px);
  -webkit-backdrop-filter: blur(6px);
  display: flex;
  align-items: flex-end;
  justify-content: center;
  z-index: 9999;
}

@media (min-width: 768px) {
  .logout-confirm-backdrop {
    align-items: center;
    padding: 24px;
  }
}

.logout-confirm-card {
  background: #ffffff;
  border-top-left-radius: var(--radius-xl);
  border-top-right-radius: var(--radius-xl);
  padding: 16px 24px 32px;
  width: 100%;
  text-align: center;
  box-shadow: 0 -8px 32px rgba(0, 0, 0, 0.08);
}

@media (min-width: 768px) {
  .logout-confirm-card {
    border-radius: var(--radius-lg);
    max-width: 380px;
    padding: 24px 28px 32px;
    box-shadow: var(--shadow-lg);
  }
}

.logout-confirm-handle {
  width: 40px;
  height: 4px;
  background-color: var(--outline-variant);
  border-radius: 2px;
  margin: 0 auto 16px;
}

.logout-confirm-icon-wrap {
  width: 56px;
  height: 56px;
  background-color: #fee2e2;
  border-radius: 50%;
  display: flex;
  justify-content: center;
  align-items: center;
  margin: 0 auto 16px;
}

.logout-confirm-title {
  font-family: var(--font-display);
  font-size: 1.35rem;
  font-weight: 700;
  color: var(--on-surface);
  margin-bottom: 8px;
}

.logout-confirm-desc {
  font-size: 0.95rem;
  color: var(--on-surface-variant);
  margin-bottom: 24px;
}

.logout-confirm-actions {
  display: flex;
  gap: 16px;
  width: 100%;
}

.logout-btn-no {
  flex: 1;
  padding: 14px;
  border-radius: var(--radius-md);
  border: 1px solid var(--outline-variant);
  background: #ffffff;
  color: var(--on-surface-variant);
  font-size: 0.95rem;
  font-weight: 700;
  cursor: pointer;
  transition: background-color 0.2s;
}

.logout-btn-no:hover {
  background-color: var(--surface-dim);
}

.logout-btn-yes {
  flex: 1;
  padding: 14px;
  border-radius: var(--radius-md);
  border: none;
  background: #b91c1c;
  color: #ffffff;
  font-size: 0.95rem;
  font-weight: 700;
  cursor: pointer;
  transition: background-color 0.2s;
  box-shadow: var(--shadow-sm);
}

.logout-btn-yes:hover {
  background: #991b1b;
}

/* Email Verification Warning Modal */
.email-warning-backdrop {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background-color: rgba(15, 23, 42, 0.6);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 9999;
}

.email-warning-modal {
  width: 90%;
  max-width: 440px;
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: 24px;
  padding: 32px;
  text-align: center;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  animation: scaleUp 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
}

.email-warning-icon-container {
  width: 64px;
  height: 64px;
  background-color: rgba(26, 35, 126, 0.08);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 20px;
  font-size: 2rem;
}

.theme-women .email-warning-icon-container {
  background-color: rgba(255, 77, 141, 0.1);
}

.email-warning-title {
  font-family: var(--font-display);
  font-size: 1.35rem;
  font-weight: 800;
  color: var(--on-surface);
  margin: 0 0 12px 0;
}

.email-warning-message {
  font-size: 0.92rem;
  color: var(--on-surface-variant);
  line-height: 1.5;
  margin: 0 0 24px 0;
}

.email-warning-actions {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.email-warning-btn {
  width: 100%;
  padding: 14px;
  border-radius: 14px;
  font-family: var(--font-sans);
  font-size: 0.9rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s ease;
  border: none;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.email-warning-btn.primary {
  background-color: var(--primary);
  color: #ffffff;
}

.email-warning-btn.primary:hover {
  filter: brightness(1.1);
}

.email-warning-btn.secondary {
  background-color: transparent;
  color: var(--on-surface-variant);
  border: 1px solid var(--outline-variant);
}

.email-warning-btn.secondary:hover {
  background-color: var(--surface-container-low);
  color: var(--on-surface);
}

@keyframes scaleUp {
  from {
    transform: scale(0.9);
    opacity: 0;
  }
  to {
    transform: scale(1);
    opacity: 1;
  }
}

/* Transition fades */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.25s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>

