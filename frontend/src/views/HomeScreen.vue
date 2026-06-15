<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { store } from '../store'
import { getPlayerAvatar } from '../utils/sportImageHelper'
import MatchCard from '../components/MatchCard.vue'
import { t } from '../utils/i18n'

const emit = defineEmits(['open-details', 'open-player', 'open-search', 'open-notifications', 'open-create'])

const selectedCategory = ref('All')
const categories = ['All', 'Football', 'Cricket', 'Badminton', 'Basketball', 'Tennis', 'Padel']

const currentUser = computed(() => {
  return store.state.currentUser || { name: 'Champ', gender: 'male', profilePhotoUrl: null }
})

const avatarUrl = computed(() => {
  return getPlayerAvatar(currentUser.value.profilePhotoUrl, currentUser.value.gender)
})

// Dynamic greeting based on time
const greeting = computed(() => {
  const hour = new Date().getHours()
  if (hour < 12) return t('goodMorning')
  if (hour < 17) return t('goodAfternoon')
  return t('goodEvening')
})

// Hero banner carousel
const heroSlides = [
  {
    sport: 'Football',
    title: 'Find Your Game',
    subtitle: 'Join local football matches near you',
    image: '/assets/images/football/images (4).jpg',
    gradient: 'linear-gradient(90deg, rgba(2, 44, 34, 0.95) 15%, rgba(2, 44, 34, 0.75) 45%, rgba(2, 44, 34, 0.1) 100%)',
    icon: '⚽',
    tag: 'Active Leagues'
  },
  {
    sport: 'Cricket',
    title: 'Play Cricket',
    subtitle: 'Join weekend cricket tournaments',
    image: '/assets/images/cricket/images (3).jpg',
    gradient: 'linear-gradient(90deg, rgba(69, 26, 3, 0.95) 15%, rgba(69, 26, 3, 0.75) 45%, rgba(69, 26, 3, 0.1) 100%)',
    icon: '🏏',
    tag: 'Weekend Special'
  },
  {
    sport: 'Badminton',
    title: 'Smash It',
    subtitle: 'Book badminton courts & find partners',
    image: '/assets/images/badminton/download (6).jpg',
    gradient: 'linear-gradient(90deg, rgba(46, 16, 101, 0.95) 15%, rgba(46, 16, 101, 0.75) 45%, rgba(46, 16, 101, 0.1) 100%)',
    icon: '🏸',
    tag: 'Court Bookings'
  },
  {
    sport: 'Tennis',
    title: 'Ace Your Game',
    subtitle: 'Connect with tennis players nearby',
    image: '/assets/images/tennis/download (4).jpg',
    gradient: 'linear-gradient(90deg, rgba(7, 89, 133, 0.95) 15%, rgba(7, 89, 133, 0.75) 45%, rgba(7, 89, 133, 0.1) 100%)',
    icon: '🎾',
    tag: 'Ace Leagues'
  },
]

const currentHeroSlide = ref(0)
let heroInterval = null

const nextHeroSlide = () => {
  currentHeroSlide.value = (currentHeroSlide.value + 1) % heroSlides.length
}

const goToSlide = (idx) => {
  currentHeroSlide.value = idx
}

onMounted(() => {
  heroInterval = setInterval(nextHeroSlide, 4000)
  // Refresh data from DB every time user visits home
  store.init()
})

onUnmounted(() => {
  if (heroInterval) clearInterval(heroInterval)
})


// Filter and sort matches nearby
const nearbyMatches = computed(() => {
  const now = new Date()
  let filtered = store.state.matches.filter(match => {
    // Category filter
    if (selectedCategory.value !== 'All' && match.sportType !== selectedCategory.value) {
      return false
    }
    // Filter out past matches
    const matchTime = new Date(match.dateTime.replace(' ', 'T'))
    return matchTime >= now
  })
  
  // Sort chronologically (closest first)
  return filtered.sort((a, b) => {
    return new Date(a.dateTime.replace(' ', 'T')) - new Date(b.dateTime.replace(' ', 'T'))
  })
})

const trendingMatches = computed(() => {
  const now = new Date()
  let filtered = store.state.matches.filter(match => {
    const matchTime = new Date(match.dateTime.replace(' ', 'T'))
    return matchTime >= now
  })
  
  // Sort by popularity (joinedCount) and chronologically
  return filtered.sort((a, b) => {
    if (b.joinedCount !== a.joinedCount) {
      return b.joinedCount - a.joinedCount
    }
    return new Date(a.dateTime.replace(' ', 'T')) - new Date(b.dateTime.replace(' ', 'T'))
  })
})

const handleCategorySelect = (category) => {
  selectedCategory.value = category
}

const handleJoinMatchClick = (sportName) => {
  selectedCategory.value = sportName
  const el = document.querySelector('.section-row')
  if (el) {
    el.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }
}

const handleWheelScroll = (e) => {
  if (e.deltaY !== 0) {
    e.preventDefault()
    e.currentTarget.scrollLeft += e.deltaY * 1.2
  }
}

let isCardScrolling = false
const handleCardWheelScroll = (e) => {
  if (e.deltaY !== 0) {
    e.preventDefault()
    if (isCardScrolling) return
    isCardScrolling = true

    const container = e.currentTarget
    const cardWidthWithGap = 306 // 290px card width + 16px gap
    
    const currentIndex = Math.round(container.scrollLeft / cardWidthWithGap)
    let targetIndex = currentIndex
    
    if (e.deltaY > 0) {
      targetIndex = currentIndex + 1
    } else {
      targetIndex = currentIndex - 1
    }
    
    const maxScroll = container.scrollWidth - container.clientWidth
    const maxIndex = Math.ceil(maxScroll / cardWidthWithGap)
    targetIndex = Math.max(0, Math.min(targetIndex, maxIndex))
    
    container.scrollTo({
      left: targetIndex * cardWidthWithGap,
      behavior: 'smooth'
    })
    
    setTimeout(() => {
      isCardScrolling = false
    }, 350)
  }
}

let isDragging = false
let startX = 0
let scrollLeft = 0
let dragMoved = false

const handleDragStart = (e) => {
  isDragging = true
  dragMoved = false
  const container = e.currentTarget
  container.classList.add('grabbing')
  startX = e.pageX - container.offsetLeft
  scrollLeft = container.scrollLeft
}

const handleDragMove = (e) => {
  if (!isDragging) return
  e.preventDefault()
  const container = e.currentTarget
  const x = e.pageX - container.offsetLeft
  const walk = (x - startX) * 1.5
  if (Math.abs(x - startX) > 5) {
    dragMoved = true
  }
  container.scrollLeft = scrollLeft - walk
}

const handleDragEnd = (e) => {
  if (!isDragging) return
  isDragging = false
  const container = e.currentTarget
  container.classList.remove('grabbing')
  
  if (dragMoved) {
    const preventClick = (clickEvent) => {
      clickEvent.stopImmediatePropagation()
      clickEvent.preventDefault()
      container.removeEventListener('click', preventClick, true)
    }
    container.addEventListener('click', preventClick, true)
  }
}
</script>

<template>
  <div class="home-container scrollable-y animate-fade-in">
    <!-- Header -->
    <div class="home-header">
      <div class="user-info">
        <img :src="avatarUrl" class="user-avatar" @error="(e) => e.target.src = '/assets/images/players/download.jpg'" @click="emit('open-player', currentUser, 'Football')" />
        <div class="greeting-wrap">
          <span class="greeting-lbl">{{ greeting }}</span>
          <span class="user-name">{{ currentUser.name }}</span>
        </div>
      </div>
      <button class="icon-btn" @click="emit('open-notifications')">
        <span class="bell-icon">🔔</span>
        <span v-if="store.state.notifications.some(n => !n.read)" class="badge-dot"></span>
      </button>
    </div>

    <!-- Hero Banner Carousel -->
    <div class="hero-banner" v-if="heroSlides.length">
      <div
        class="hero-slide"
        v-for="(slide, idx) in heroSlides"
        :key="slide.sport"
        :class="{ active: currentHeroSlide === idx }"
        :style="{ backgroundImage: `url('${slide.image}')` }"
      >
        <div class="hero-slide-overlay" :style="{ background: slide.gradient }"></div>
        <div class="hero-slide-content">
          <div class="hero-slide-badge">
            <span class="hero-slide-badge-icon">{{ slide.icon }}</span>
            <span class="hero-slide-badge-text">{{ slide.tag }}</span>
          </div>
          <h2 class="hero-slide-title">{{ slide.title }}</h2>
          <p class="hero-slide-subtitle">{{ slide.subtitle }}</p>
          <button class="hero-slide-btn" @click="handleJoinMatchClick(slide.sport)">
            <span>{{ t('joinAMatch') }}</span>
            <svg class="btn-arrow" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"></line><polyline points="12 5 19 12 12 19"></polyline></svg>
          </button>
        </div>
      </div>
      <!-- Dots indicator -->
      <div class="hero-dots">
        <span
          v-for="(s, i) in heroSlides"
          :key="i"
          class="hero-dot"
          :class="{ active: currentHeroSlide === i }"
          @click="goToSlide(i)"
        ></span>
      </div>
    </div>

    <!-- Search bar trigger -->
    <div class="search-trigger-bar" @click="emit('open-search')">
      <span class="search-icon">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="search-svg"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
      </span>
      <span class="placeholder-text">{{ t('findPlaceholder') }}</span>
    </div>

    <!-- Category Pills horizontal scroll -->
    <div class="category-section-wrap">
      <div 
        class="category-slider" 
        @wheel.prevent="handleWheelScroll"
        @mousedown="handleDragStart"
        @mousemove="handleDragMove"
        @mouseup="handleDragEnd"
        @mouseleave="handleDragEnd"
      >
        <button 
          v-for="cat in categories" 
          :key="cat"
          class="category-pill"
          :class="[cat.toLowerCase().trim(), { active: selectedCategory === cat }]"
          @click="handleCategorySelect(cat)"
        >
          {{ cat }}
        </button>
      </div>
      <div class="category-create-btn-wrap">
        <button class="category-create-btn" @click="emit('open-create')" title="Create Match">
          <span class="plus-icon">+</span>
          {{ t('createMatch') }}
        </button>
      </div>
    </div>

    <!-- Nearby Matches -->
    <div class="section-row">
      <h3 class="section-title">{{ t('nearbyMatches') }}</h3>
    </div>

    <!-- Loading skeletons for matches -->
    <div v-if="store.state.isLoading" class="nearby-slider">
      <div v-for="n in 3" :key="n" class="skeleton-card"></div>
    </div>
    <div 
      v-else
      class="nearby-slider" 
      @wheel.prevent="handleCardWheelScroll"
      @mousedown="handleDragStart"
      @mousemove="handleDragMove"
      @mouseup="handleDragEnd"
      @mouseleave="handleDragEnd"
    >
      <div v-if="nearbyMatches.length === 0" class="empty-matches">
        <span class="empty-icon">🏃</span>
        <span>{{ t('noMatchesFound') }}<br/>{{ t('beFirstToCreate') }}</span>
      </div>
      <MatchCard 
        v-for="match in nearbyMatches" 
        :key="match.id"
        :match="match"
        :is-horizontal="true"
        @open-details="emit('open-details', match)"
        @open-player="(p, s) => emit('open-player', p, s)"
      />
    </div>

    <!-- Trending Matches -->
    <div class="section-row trending-row">
      <h3 class="section-title">{{ t('trendingMatches') }}</h3>
    </div>

    <div v-if="store.state.isLoading" class="nearby-slider">
      <div v-for="n in 3" :key="n" class="skeleton-card"></div>
    </div>
    <div 
      v-else 
      class="nearby-slider"
      @wheel.prevent="handleCardWheelScroll"
      @mousedown="handleDragStart"
      @mousemove="handleDragMove"
      @mouseup="handleDragEnd"
      @mouseleave="handleDragEnd"
    >
      <div v-if="trendingMatches.length === 0" class="empty-matches">
        <span class="empty-icon">🔥</span>
        <span>{{ t('noTrendingMatches') }}</span>
      </div>
      <MatchCard 
        v-for="match in trendingMatches" 
        :key="match.id"
        :match="match"
        :is-horizontal="true"
        @open-details="emit('open-details', match)"
        @open-player="(p, s) => emit('open-player', p, s)"
      />
    </div>

  </div>
</template>

<style scoped>
.home-container {
  padding: 56px 20px 80px;
  background-color: var(--scaffold-bg);
}

/* ── HERO BANNER ── */
.hero-banner {
  position: relative;
  width: 100%;
  margin: 0 0 28px;
  height: 220px;
  overflow: hidden;
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-md);
  border: 1px solid var(--outline-variant);
  background-color: var(--surface-dim);
}

.hero-slide {
  position: absolute;
  inset: 0;
  background-size: cover;
  background-position: right 25% center;
  opacity: 0;
  transition: opacity 0.8s ease;
  display: flex;
  align-items: center;
}

.hero-slide.active {
  opacity: 1;
  z-index: 1;
}

.hero-slide-overlay {
  position: absolute;
  inset: 0;
  z-index: 1;
}

.hero-slide-content {
  position: relative;
  z-index: 2;
  padding: 32px 36px;
  color: #fff;
  display: flex;
  flex-direction: column;
  justify-content: center;
  height: 100%;
  max-width: 65%;
  gap: 8px;
}

/* Badge styling */
.hero-slide-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: rgba(255, 255, 255, 0.15);
  backdrop-filter: blur(4px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  padding: 4px 10px;
  border-radius: 30px;
  width: fit-content;
  margin-bottom: 2px;
}

.hero-slide-badge-icon {
  font-size: 0.95rem;
  line-height: 1;
}

.hero-slide-badge-text {
  font-size: 0.65rem;
  font-weight: 800;
  letter-spacing: 0.8px;
  text-transform: uppercase;
  color: rgba(255, 255, 255, 0.95);
}

.hero-slide-title {
  font-family: var(--font-display);
  font-size: 1.8rem;
  font-weight: 800;
  line-height: 1.2;
  margin: 0;
  color: #fff;
  letter-spacing: -0.5px;
  text-shadow: 0 2px 10px rgba(0,0,0,0.4);
}

.hero-slide-subtitle {
  font-size: 0.88rem;
  opacity: 0.9;
  margin: 0 0 4px;
  line-height: 1.45;
  color: rgba(255, 255, 255, 0.85);
  text-shadow: 0 1px 5px rgba(0,0,0,0.3);
}

/* Premium Button style */
.hero-slide-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background: #ffffff;
  border: none;
  color: #0f172a;
  font-size: 0.8rem;
  font-weight: 800;
  padding: 10px 20px;
  border-radius: 30px;
  cursor: pointer;
  transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
  width: fit-content;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.hero-slide-btn .btn-arrow {
  transition: transform 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}

.hero-slide-btn:hover {
  background: #ffffff;
  color: var(--primary);
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(255, 255, 255, 0.25), 0 4px 15px rgba(0, 0, 0, 0.2);
}

.hero-slide-btn:hover .btn-arrow {
  transform: translateX(4px);
}

.hero-slide-btn:active {
  transform: translateY(0);
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.15);
}

.hero-dots {
  position: absolute;
  bottom: 16px;
  right: 24px;
  z-index: 10;
  display: flex;
  gap: 6px;
}

.hero-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.45);
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

.hero-dot:hover {
  background: rgba(255, 255, 255, 0.85);
}

.hero-dot.active {
  width: 20px;
  border-radius: 4px;
  background: #fff;
  box-shadow: 0 0 8px rgba(255, 255, 255, 0.4);
}

/* Responsive Hero Banner queries */
@media (max-width: 768px) {
  .hero-banner {
    height: 200px;
  }
  .hero-slide-content {
    padding: 24px;
    max-width: 80%;
    gap: 6px;
  }
  .hero-slide-title {
    font-size: 1.5rem;
  }
  .hero-slide-subtitle {
    font-size: 0.8rem;
  }
  .hero-slide-btn {
    padding: 8px 16px;
    font-size: 0.75rem;
  }
  .hero-dots {
    right: 16px;
    bottom: 12px;
  }
}

@media (max-width: 480px) {
  .hero-banner {
    height: 180px;
    margin-bottom: 20px;
  }
  .hero-slide-content {
    padding: 16px 20px;
    max-width: 90%;
    gap: 4px;
  }
  .hero-slide-title {
    font-size: 1.3rem;
  }
  .hero-slide-subtitle {
    font-size: 0.75rem;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
  .hero-slide-badge {
    padding: 2px 8px;
    margin-bottom: 0px;
  }
  .hero-slide-badge-text {
    font-size: 0.58rem;
  }
  .hero-slide-btn {
    padding: 6px 12px;
    font-size: 0.7rem;
    gap: 6px;
  }
}


/* ── SKELETON LOADING ── */
@keyframes shimmer {
  0% { background-position: -400px 0; }
  100% { background-position: 400px 0; }
}

.skeleton-card {
  width: 290px;
  height: 350px;
  flex-shrink: 0;
  border-radius: 20px;
  background: linear-gradient(90deg, var(--surface-dim) 25%, var(--outline-variant) 50%, var(--surface-dim) 75%);
  background-size: 400px 100%;
  animation: shimmer 1.5s infinite;
}

.skeleton-card-vertical {
  width: 100%;
  height: 160px;
  border-radius: 16px;
  margin-bottom: 16px;
  background: linear-gradient(90deg, var(--surface-dim) 25%, var(--outline-variant) 50%, var(--surface-dim) 75%);
  background-size: 400px 100%;
  animation: shimmer 1.5s infinite;
}

.empty-matches {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 32px 24px;
  font-size: 0.85rem;
  color: var(--on-surface-variant);
  width: 100%;
  text-align: center;
}

.empty-icon {
  font-size: 2rem;
  opacity: 0.6;
}



.home-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}



.user-info {
  display: flex;
  align-items: center;
  gap: 16px;
}

.user-avatar {
  width: 52px;
  height: 52px;
  border-radius: 50%;
  object-fit: cover;
  border: 2.5px solid var(--primary);
  box-shadow: var(--shadow-md);
  cursor: pointer;
  transition: transform 0.2s cubic-bezier(0.16, 1, 0.3, 1), box-shadow 0.2s ease;
}

.user-avatar:hover {
  transform: scale(1.08);
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.1);
}

.greeting-wrap {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.greeting-lbl {
  font-size: 0.88rem;
  color: var(--on-surface-variant);
  font-weight: 500;
  letter-spacing: 0.2px;
}

.user-name {
  font-family: var(--font-display);
  font-size: 1.4rem;
  font-weight: 800;
  color: var(--on-surface);
  line-height: 1.2;
}

@media (min-width: 769px) {
  .user-info {
    gap: 20px;
  }
  
  .user-avatar {
    width: 68px;
    height: 68px;
    border-width: 3px;
  }
  
  .greeting-lbl {
    font-size: 1.05rem;
  }
  
  .user-name {
    font-size: 1.95rem;
  }
}

.icon-btn {
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: 50%;
  width: 40px;
  height: 40px;
  display: flex;
  justify-content: center;
  align-items: center;
  cursor: pointer;
  position: relative;
  box-shadow: var(--shadow-sm);
}

.bell-icon {
  font-size: 1.1rem;
}

.badge-dot {
  position: absolute;
  top: 10px;
  right: 10px;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: var(--primary);
  border: 1.5px solid var(--surface);
}

.search-trigger-bar {
  display: flex;
  align-items: center;
  gap: 12px;
  background: rgba(255, 255, 255, 0.7);
  backdrop-filter: blur(8px);
  border: 1px solid rgba(226, 232, 240, 0.8);
  border-radius: var(--radius-md);
  padding: 14px 18px;
  cursor: pointer;
  margin-bottom: 28px;
  box-shadow: 0 4px 12px rgba(31, 38, 135, 0.03);
  transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}

.search-trigger-bar:hover {
  background-color: var(--surface);
  border-color: var(--primary);
  box-shadow: var(--shadow-md);
  transform: translateY(-1px);
}

.search-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--outline);
  transition: color 0.2s ease;
}

.search-trigger-bar:hover .search-icon {
  color: var(--primary);
}

.placeholder-text {
  font-size: 0.88rem;
  color: var(--on-surface-variant);
  font-weight: 500;
}

.category-section-wrap {
  position: relative;
  margin: 0 -20px 28px;
}

.category-slider {
  display: flex;
  gap: 8px;
  overflow-x: auto;
  padding: 4px 160px 4px 20px;
  margin: 0;
  -webkit-overflow-scrolling: touch;
  scrollbar-width: thin;
  scrollbar-color: var(--outline-variant) transparent;
  cursor: grab;
  user-select: none;
}

.category-create-btn-wrap {
  position: absolute;
  right: 20px;
  top: 0;
  bottom: 0;
  width: 170px;
  background: linear-gradient(to right, transparent 0%, var(--scaffold-bg) 40%, var(--scaffold-bg) 100%);
  display: flex;
  align-items: center;
  justify-content: flex-end;
  padding-right: 20px;
  pointer-events: none;
  z-index: 10;
}

.category-create-btn {
  pointer-events: auto;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 18px;
  border-radius: 30px;
  border: none;
  background-color: var(--primary);
  color: #ffffff;
  font-size: 0.82rem;
  font-weight: 700;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.category-create-btn:hover {
  transform: translateY(-2px);
  filter: brightness(1.1);
  box-shadow: 0 6px 15px rgba(0, 0, 0, 0.2);
}

.category-slider.grabbing {
  cursor: grabbing;
  scroll-snap-type: none !important;
  scroll-behavior: auto !important;
}

.category-slider::-webkit-scrollbar {
  height: 6px;
  display: block;
}

.category-slider::-webkit-scrollbar-track {
  background: transparent;
}

.category-slider::-webkit-scrollbar-thumb {
  background: var(--outline-variant);
  border-radius: 10px;
}

.category-slider::-webkit-scrollbar-thumb:hover {
  background: var(--outline);
}

.category-pill {
  padding: 8px 18px;
  border-radius: 20px;
  border: 1px solid var(--outline-variant);
  background-color: var(--surface);
  color: var(--on-surface-variant);
  font-size: 0.82rem;
  font-weight: 700;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
  box-shadow: var(--shadow-sm);
}

.category-pill:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-md);
  color: var(--on-surface);
}

.category-pill.active {
  color: #ffffff !important;
  border-color: transparent !important;
}

.category-pill.all.active {
  background: linear-gradient(135deg, var(--primary) 0%, var(--primary-container) 100%);
  box-shadow: 0 4px 10px rgba(26, 35, 126, 0.25);
}

.category-pill.football.active {
  background: linear-gradient(135deg, #10b981 0%, #047857 100%);
  box-shadow: 0 4px 10px rgba(16, 185, 129, 0.25);
}

.category-pill.cricket.active {
  background: linear-gradient(135deg, #f59e0b 0%, #b45309 100%);
  box-shadow: 0 4px 10px rgba(245, 158, 11, 0.25);
}

.category-pill.badminton.active {
  background: linear-gradient(135deg, #8b5cf6 0%, #6d28d9 100%);
  box-shadow: 0 4px 10px rgba(139, 92, 246, 0.25);
}

.category-pill.basketball.active {
  background: linear-gradient(135deg, #f97316 0%, #ea580c 100%);
  box-shadow: 0 4px 10px rgba(249, 115, 22, 0.25);
}

.category-pill.tennis.active {
  background: linear-gradient(135deg, #06b6d4 0%, #0891b2 100%);
  box-shadow: 0 4px 10px rgba(6, 182, 212, 0.25);
}

.category-pill.padel.active {
  background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
  box-shadow: 0 4px 10px rgba(59, 130, 246, 0.25);
}

.section-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.section-title {
  font-family: var(--font-display);
  font-size: 1.25rem;
  font-weight: 800;
  color: var(--text-dark);
  letter-spacing: -0.2px;
}

.see-all-btn {
  background: none;
  border: none;
  font-size: 0.85rem;
  font-weight: 700;
  color: var(--primary);
  cursor: pointer;
  transition: opacity 0.2s ease, transform 0.2s ease;
}

.see-all-btn:hover {
  opacity: 0.8;
  transform: scale(1.02);
}

.see-all-btn:active {
  transform: scale(0.98);
}

.nearby-slider {
  display: flex;
  gap: 16px;
  overflow-x: auto;
  padding: 4px 20px 16px;
  margin: 0 -20px 28px;
  scroll-snap-type: x mandatory;
  -webkit-overflow-scrolling: touch;
  scrollbar-width: thin;
  scrollbar-color: var(--outline-variant) transparent;
  cursor: grab;
  user-select: none;
}

.nearby-slider.grabbing {
  cursor: grabbing;
  scroll-snap-type: none !important;
  scroll-behavior: auto !important;
}

@media (max-width: 500px) {
  .nearby-slider {
    gap: 20px;
  }
}

.nearby-slider::-webkit-scrollbar {
  height: 6px;
  display: block;
}

.nearby-slider::-webkit-scrollbar-track {
  background: transparent;
}

.nearby-slider::-webkit-scrollbar-thumb {
  background: var(--outline-variant);
  border-radius: 10px;
}

.nearby-slider::-webkit-scrollbar-thumb:hover {
  background: var(--outline);
}

.empty-matches {
  text-align: center;
  padding: 24px;
  font-size: 0.85rem;
  color: var(--on-surface-variant);
  width: 100%;
}



.trending-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 20px;
}

@media (min-width: 640px) {
  .trending-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (min-width: 1024px) {
  .trending-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

.plus-icon {
  font-size: 1.1rem;
  font-weight: 500;
  line-height: 1;
}
</style>
