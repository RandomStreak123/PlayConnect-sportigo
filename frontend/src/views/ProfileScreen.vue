<script setup>
import { ref, computed, watch } from 'vue'
import { store } from '../store'
import { getPlayerAvatar } from '../utils/sportImageHelper'
import { supabase } from '../utils/supabase'
import { t } from '../utils/i18n'

const emit = defineEmits(['auth-logout', 'toast-message', 'view-profile'])

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

const showUnfollowConfirm = ref(false)
const playerToUnfollow = ref(null)
const unfollowSource = ref('main') // 'main' or 'list'

const requestUnfollow = (user, source = 'main') => {
  playerToUnfollow.value = user
  unfollowSource.value = source
  showUnfollowConfirm.value = true
}

const confirmUnfollow = async () => {
  if (!playerToUnfollow.value) return
  showUnfollowConfirm.value = false
  
  const userId = playerToUnfollow.value.id
  try {
    const res = await store.unfollowPlayer(userId)
    if (res && res.success) {
      if (unfollowSource.value === 'main') {
        if (profileUser.value) {
          profileUser.value.isFollowed = false
          profileUser.value.followersCount = res.followersCount
        }
      } else {
        const idx = followListUsers.value.findIndex(u => u.id === userId)
        if (idx !== -1) {
          followListUsers.value[idx].isFollowed = false
        }
        if (!props.isCurrentUser && profileUser.value && userId === store.state.currentUser?.id) {
          profileUser.value.isFollowed = false
          profileUser.value.followersCount = res.followersCount
        }
      }
      emit('toast-message', `Unfollowed ${playerToUnfollow.value.name}! 👥`)
    }
  } catch (err) {
    console.error('Failed to unfollow:', err)
  }
}

const handleFollowToggle = async () => {
  if (props.isCurrentUser) return
  try {
    if (currentUser.value.isFollowed) {
      requestUnfollow(currentUser.value, 'main')
    } else {
      const res = await store.followPlayer(props.userId)
      if (res && res.success) {
        if (profileUser.value) {
          profileUser.value.isFollowed = true
          profileUser.value.followersCount = res.followersCount
        }
        emit('toast-message', `Following ${currentUser.value.name}! 🎉`)
      }
    }
  } catch (err) {
    console.error('Failed to toggle follow status:', err)
    emit('toast-message', 'Failed to update follow status ❌')
  }
}

const showFollowListModal = ref(false)
const followListType = ref('followers') // 'followers' or 'following'
const followListUsers = ref([])
const loadingFollowList = ref(false)

const openFollowModal = async (type) => {
  followListType.value = type
  showFollowListModal.value = true
  loadingFollowList.value = true
  followListUsers.value = []
  
  const userId = props.isCurrentUser ? store.state.currentUser?.id : props.userId
  if (!userId) {
    loadingFollowList.value = false
    return
  }

  try {
    const res = await fetch(`/api/users/${userId}/${type}`, {
      headers: {
        'Authorization': `Bearer ${sessionStorage.getItem('sportigo_token')}`,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    })
    if (res.ok) {
      followListUsers.value = await res.json()
    }
  } catch (err) {
    console.error(`Failed to load ${type}:`, err)
  } finally {
    loadingFollowList.value = false
  }
}

const navigateToPlayerProfile = (player) => {
  showFollowListModal.value = false
  emit('view-profile', player)
}

const handleListFollowToggle = async (user) => {
  try {
    if (user.isFollowed) {
      requestUnfollow(user, 'list')
    } else {
      const res = await store.followPlayer(user.id)
      if (res && res.success) {
        user.isFollowed = true
        if (!props.isCurrentUser && profileUser.value && user.id === store.state.currentUser?.id) {
          profileUser.value.isFollowed = true
          profileUser.value.followersCount = res.followersCount
        }
        emit('toast-message', `Following ${user.name}! 🎉`)
      }
    }
  } catch (err) {
    console.error('Failed to toggle follow in list:', err)
  }
}

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
        'Authorization': `Bearer ${sessionStorage.getItem('sportigo_token')}`,
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

watch(() => [props.userId, props.isCurrentUser], () => {
  profileUser.value = null
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
  console.log('ProfileScreen - userMatches - total matches:', matches.length, 'uid:', uid)
  if (!uid) return []
  
  const filtered = matches.filter(m => {
    const isCreator = Number(m.creator_id || m.user_id) === Number(uid)
    const isParticipant = m.participants?.some(p => Number(p.id) === Number(uid))
    return isCreator || isParticipant
  })
  console.log('ProfileScreen - userMatches - filtered matches:', filtered.length)
  return filtered
})

// Filter to matches that have already been played (strictly in the past)
const playedMatches = computed(() => {
  const now = new Date()
  const filtered = userMatches.value.filter(m => {
    const dateStr = m.date_time || m.date
    if (!dateStr) return false
    const matchDate = new Date(dateStr.replace(' ', 'T'))
    const isPast = matchDate <= now
    console.log(`ProfileScreen - playedMatches - checking: ${m.title} (${dateStr}) | parsed: ${matchDate} | isPast: ${isPast}`)
    return isPast
  })
  console.log('ProfileScreen - playedMatches - filtered past matches:', filtered.length)
  return filtered
})

// Streaks navigation state
const weekOffset = ref(0)

const getMonday = (d) => {
  const dateCopy = new Date(d)
  const day = dateCopy.getDay()
  const diff = dateCopy.getDate() - day + (day === 0 ? -6 : 1)
  return new Date(dateCopy.setDate(diff))
}

const weekLabel = computed(() => {
  if (weekOffset.value === 0) return t('thisWeek') || 'This Week'
  if (weekOffset.value === -1) return t('lastWeek') || 'Last Week'
  
  const today = new Date()
  const targetMonday = getMonday(today)
  targetMonday.setDate(targetMonday.getDate() + weekOffset.value * 7)
  
  const targetSunday = new Date(targetMonday)
  targetSunday.setDate(targetSunday.getDate() + 6)
  
  const options = { month: 'short', day: 'numeric' }
  return `${targetMonday.toLocaleDateString('default', options)} - ${targetSunday.toLocaleDateString('default', options)}`
})

// Dynamic streak calculation based on playedMatches.value
const calculatedStreak = computed(() => {
  if (playedMatches.value.length === 0) return 0

  const uniqueDates = new Set()
  playedMatches.value.forEach(m => {
    const dateStr = m.date_time || m.date
    if (!dateStr) return
    const mDate = new Date(dateStr.replace(' ', 'T'))
    const yyyy = mDate.getFullYear()
    const mm = String(mDate.getMonth() + 1).padStart(2, '0')
    const dd = String(mDate.getDate()).padStart(2, '0')
    uniqueDates.add(`${yyyy}-${mm}-${dd}`)
  })

  // Determine reference date based on weekOffset
  let refDate = new Date()
  if (weekOffset.value < 0) {
    const monday = getMonday(new Date())
    monday.setDate(monday.getDate() + weekOffset.value * 7)
    const sunday = new Date(monday)
    sunday.setDate(monday.getDate() + 6)
    sunday.setHours(23, 59, 59, 999)
    refDate = sunday
  }

  const refYear = refDate.getFullYear()
  const refMonth = String(refDate.getMonth() + 1).padStart(2, '0')
  const refDay = String(refDate.getDate()).padStart(2, '0')
  const refStr = `${refYear}-${refMonth}-${refDay}`
  
  const prevDate = new Date(refDate)
  prevDate.setDate(refDate.getDate() - 1)
  const prevStr = `${prevDate.getFullYear()}-${String(prevDate.getMonth() + 1).padStart(2, '0')}-${String(prevDate.getDate()).padStart(2, '0')}`

  let checkDate = null

  // 1. Determine anchor date (ref date or day before ref date)
  if (uniqueDates.has(refStr)) {
    checkDate = new Date(refDate)
  } else if (uniqueDates.has(prevStr)) {
    checkDate = new Date(prevDate)
  } else {
    return 0
  }

  // 2. Count backwards from the anchor date
  let backwardCount = 0
  let tempDate = new Date(checkDate)
  while (true) {
    const checkStr = `${tempDate.getFullYear()}-${String(tempDate.getMonth() + 1).padStart(2, '0')}-${String(tempDate.getDate()).padStart(2, '0')}`
    if (uniqueDates.has(checkStr)) {
      backwardCount++
      tempDate.setDate(tempDate.getDate() - 1)
    } else {
      break
    }
  }

  // 3. Count forwards from the day after the anchor date (limited to target week's end if in the past)
  let forwardCount = 0
  tempDate = new Date(checkDate)
  tempDate.setDate(tempDate.getDate() + 1)
  const maxForwardDate = weekOffset.value === 0 ? new Date(3000, 0, 1) : refDate
  maxForwardDate.setHours(23, 59, 59, 999)

  while (tempDate <= maxForwardDate) {
    const checkStr = `${tempDate.getFullYear()}-${String(tempDate.getMonth() + 1).padStart(2, '0')}-${String(tempDate.getDate()).padStart(2, '0')}`
    if (uniqueDates.has(checkStr)) {
      forwardCount++
      tempDate.setDate(tempDate.getDate() + 1)
    } else {
      break
    }
  }

  return backwardCount + forwardCount
})

const showAllActivities = ref(false)

const isPastMatch = (match) => {
  const dateStr = match.date_time || match.date
  if (!dateStr) return false
  const matchDate = new Date(dateStr.replace(' ', 'T'))
  return matchDate < new Date()
}

const userActivities = computed(() => {
  if (props.isCurrentUser) {
    const myId = store.state.currentUser?.id
    if (!myId) return []
    return (store.state.activities || []).filter(act => {
      const isMatchAct = ['match_created', 'match_joined', 'match_left'].includes(act.type)
      const isMyAct = Number(act.user_id || act.userId) === Number(myId)
      return isMatchAct && isMyAct
    })
  } else {
    return (profileUser.value?.activities || []).filter(act => {
      return ['match_created', 'match_joined', 'match_left'].includes(act.type)
    })
  }
})

const sortedActivities = computed(() => {
  const sorted = [...userActivities.value].sort((a, b) => {
    const timeA = new Date(String(a.created_at || 0).replace(' ', 'T'))
    const timeB = new Date(String(b.created_at || 0).replace(' ', 'T'))
    return timeB - timeA
  })
  return sorted
})

const visibleActivities = computed(() => {
  if (showAllActivities.value) {
    return sortedActivities.value
  }
  return sortedActivities.value.slice(0, 4)
})

// Determine if a match is a win for the given user
// Only uses real recorded results from pivot data — no fake fallback
const isMatchWin = (match, uid) => {
  const participant = match.participants?.find(p => Number(p.id) === Number(uid))
  if (participant?.pivot?.result) {
    return participant.pivot.result === 'win'
  }
  // No result recorded yet — return null (unrecorded)
  return null
}

const hasRealResult = (match, uid) => {
  const participant = match.participants?.find(p => Number(p.id) === Number(uid))
  return !!participant?.pivot?.result
}

const profileStats = computed(() => {
  if (currentUser.value && currentUser.value.stats) {
    return currentUser.value.stats
  }
  return {
    xp: 0,
    level: 1,
    currentLevelXp: 0,
    nextLevelXp: 1000,
    progressPct: 0,
    winRate: 0,
    streak: 0,
    averageRating: 0.0,
    totalGames: 0
  }
})

// Calculate per-match XP for Activity Log display
const getMatchXp = (match) => {
  const uid = props.isCurrentUser ? store.state.currentUser?.id : props.userId
  const isCreator = Number(match.creator_id || match.user_id) === Number(uid)
  const result = isMatchWin(match, uid)

  let matchXp = isCreator ? 20 : 5   // Create or Join
  matchXp += 15                       // Complete
  if (result === true) matchXp += 25  // Win (only real recorded wins)
  return matchXp
}

const getActivityXp = (act) => {
  if (act.type === 'match_left') return -20
  
  const matches = props.isCurrentUser ? store.state.matches : (profileUser.value?.matches || [])
  const matchId = act.meta?.match_id || act.meta?.matchId
  const match = matches.find(m => Number(m.id) === Number(matchId))
  
  if (match) {
    return getMatchXp(match)
  }
  
  const isCreator = act.type === 'match_created'
  return isCreator ? 35 : 20
}

// Date Formatting Helper
const formatDate = (dateStr) => {
  if (!dateStr) return ''
  try {
    const d = new Date(dateStr.replace(' ', 'T'))
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

const showRulesModal = ref(false)
const showPoliciesModal = ref(false)
const selectedRulesSport = ref(null)

const getSportSubtitle = (sport) => {
  switch (sport) {
    case 'Football': return store.state.language === 'hi' ? 'स्लाइड टैकल, गोलकीपर और क्षेत्र नियम' : 'Slide tackles, goalkeeper rules & pitch play'
    case 'Cricket': return store.state.language === 'hi' ? 'ओवर, अतिरिक्त रन, रन और विकेट' : 'Overs, extras, runs & wickets'
    case 'Badminton': return store.state.language === 'hi' ? 'सर्विस नियम, स्कोरिंग और फॉल्ट कॉल' : 'Serving rules, scoring & fault calls'
    case 'Basketball': return store.state.language === 'hi' ? 'स्कोरिंग, ड्रिब्लिंग और व्यक्तिगत फाउल' : 'Scoring, dribbling & personal fouls'
    case 'Tennis': return store.state.language === 'hi' ? 'सर्विस अनुक्रम, स्कोरिंग और लाइन कॉल' : 'Serving sequences, scoring & line calls'
    case 'Padel': return store.state.language === 'hi' ? 'कोर्ट की दीवारें, अंडरहैंड सर्व और गोल्डन पॉइंट' : 'Court walls, underhand serves & golden point'
    default: return store.state.language === 'hi' ? 'सामान्य खेल नियम और आचार संहिता' : 'General game rules & code of conduct'
  }
}

const getSportSVG = (sport) => {
  const name = (sport || '').toLowerCase().trim()
  if (name === 'football') {
    return `<svg viewBox="0 0 100 100" width="100%" height="100%">
      <circle cx="50" cy="50" r="46" fill="#ffffff" stroke="#1e293b" stroke-width="3"/>
      <polygon points="50,30 38,38 42,54 58,54 62,38" fill="#1e293b"/>
      <path d="M50,30 L50,4 M38,38 L18,30 M42,54 L26,70 M58,54 L74,70 M62,38 L82,30" stroke="#1e293b" stroke-width="3"/>
      <polygon points="50,4 35,12 35,26 50,30" fill="none" stroke="#1e293b" stroke-width="3"/>
      <polygon points="50,4 65,12 65,26 50,30" fill="none" stroke="#1e293b" stroke-width="3"/>
      <polygon points="18,30 8,44 18,58 38,38" fill="none" stroke="#1e293b" stroke-width="3"/>
      <polygon points="82,30 92,44 82,58 62,38" fill="none" stroke="#1e293b" stroke-width="3"/>
      <polygon points="26,70 42,88 50,88 42,54" fill="none" stroke="#1e293b" stroke-width="3"/>
      <polygon points="74,70 58,88 50,88 58,54" fill="none" stroke="#1e293b" stroke-width="3"/>
    </svg>`
  } else if (name === 'cricket') {
    return `<svg viewBox="0 0 100 100" width="100%" height="100%">
      <g transform="rotate(-45 50 50)">
        <rect x="47" y="5" width="6" height="35" rx="3" fill="#d97706" stroke="#451a03" stroke-width="2"/>
        <rect x="46" y="25" width="8" height="15" fill="#1e293b"/>
        <path d="M44,40 L56,40 L54,90 L46,90 Z" fill="#f59e0b" stroke="#451a03" stroke-width="2"/>
      </g>
      <circle cx="75" cy="40" r="12" fill="#dc2626" stroke="#7f1d1d" stroke-width="2"/>
      <path d="M66,33 Q75,40 84,33" fill="none" stroke="#ffffff" stroke-width="2" stroke-dasharray="2,2"/>
      <path d="M66,47 Q75,40 84,47" fill="none" stroke="#ffffff" stroke-width="2" stroke-dasharray="2,2"/>
    </svg>`
  } else if (name === 'badminton') {
    return `<svg viewBox="0 0 100 100" width="100%" height="100%">
      <g transform="rotate(-30 50 50)">
        <rect x="48" y="45" width="4" height="50" rx="2" fill="#94a3b8" stroke="#475569" stroke-width="1.5"/>
        <rect x="47" y="85" width="6" height="10" fill="#1e293b" rx="1"/>
        <ellipse cx="50" cy="28" rx="18" ry="22" fill="none" stroke="#475569" stroke-width="3"/>
        <path d="M35,28 L65,28 M38,18 L62,18 M38,38 L62,38 M44,10 L44,46 M50,6 L50,50 M56,10 L56,46" stroke="#cbd5e1" stroke-width="1"/>
      </g>
      <g transform="translate(15, 15)">
        <path d="M35,45 C35,55 45,55 45,45 Z" fill="#ffffff" stroke="#475569" stroke-width="2"/>
        <rect x="35" y="42" width="10" height="3" fill="#dc2626"/>
        <path d="M35,42 L25,15 L55,15 L45,42 Z" fill="#f8fafc" stroke="#475569" stroke-width="2"/>
        <path d="M30,42 L20,15 M35,42 L30,15 M40,42 L40,15 M45,42 L50,15" stroke="#cbd5e1" stroke-width="1.5"/>
      </g>
    </svg>`
  } else if (name === 'basketball') {
    return `<svg viewBox="0 0 100 100" width="100%" height="100%">
      <circle cx="50" cy="50" r="46" fill="#ea580c" stroke="#431407" stroke-width="3"/>
      <path d="M4,50 L96,50 M50,4 L50,96" stroke="#431407" stroke-width="3"/>
      <path d="M18,18 Q50,50 18,82" fill="none" stroke="#431407" stroke-width="3"/>
      <path d="M82,18 Q50,50 82,82" fill="none" stroke="#431407" stroke-width="3"/>
    </svg>`
  } else if (name === 'tennis') {
    return `<svg viewBox="0 0 100 100" width="100%" height="100%">
      <g transform="rotate(-40 50 50)">
        <rect x="48" y="45" width="4" height="50" rx="2" fill="#d1d5db" stroke="#374151" stroke-width="1.5"/>
        <rect x="46" y="85" width="8" height="10" fill="#2563eb" rx="1"/>
        <circle cx="50" cy="26" r="22" fill="none" stroke="#dc2626" stroke-width="3.5"/>
        <path d="M30,26 L70,26 M32,16 L68,16 M32,36 L68,36 M40,8 L40,44 M50,4 L50,48 M60,8 L60,44" stroke="#e5e7eb" stroke-width="1"/>
      </g>
      <circle cx="35" cy="35" r="10" fill="#ccff00" stroke="#4d7c0f" stroke-width="2"/>
      <path d="M27,29 Q35,35 35,45" fill="none" stroke="#ffffff" stroke-width="1.5"/>
      <path d="M43,29 Q35,35 35,45" fill="none" stroke="#ffffff" stroke-width="1.5" transform="rotate(180 35 35)"/>
    </svg>`
  } else if (name === 'padel') {
    return `<svg viewBox="0 0 100 100" width="100%" height="100%">
      <g transform="rotate(-35 50 50)">
        <rect x="47" y="55" width="6" height="40" rx="3" fill="#1e293b" stroke="#0f172a" stroke-width="2"/>
        <rect x="45" y="85" width="10" height="10" fill="#ef4444" rx="2"/>
        <path d="M32,32 C32,12 68,12 68,32 C68,52 32,52 32,32 Z" fill="#ef4444" stroke="#0f172a" stroke-width="3"/>
        <circle cx="44" cy="26" r="2" fill="#0f172a"/>
        <circle cx="50" cy="26" r="2" fill="#0f172a"/>
        <circle cx="56" cy="26" r="2" fill="#0f172a"/>
        <circle cx="40" cy="32" r="2" fill="#0f172a"/>
        <circle cx="46" cy="32" r="2" fill="#0f172a"/>
        <circle cx="54" cy="32" r="2" fill="#0f172a"/>
        <circle cx="60" cy="32" r="2" fill="#0f172a"/>
        <circle cx="44" cy="38" r="2" fill="#0f172a"/>
        <circle cx="50" cy="38" r="2" fill="#0f172a"/>
        <circle cx="56" cy="38" r="2" fill="#0f172a"/>
      </g>
      <circle cx="72" cy="40" r="8" fill="#ccff00" stroke="#4d7c0f" stroke-width="1.5"/>
      <path d="M66,35 Q72,40 72,48" fill="none" stroke="#ffffff" stroke-width="1"/>
      <path d="M78,35 Q72,40 72,48" fill="none" stroke="#ffffff" stroke-width="1" transform="rotate(180 72 40)"/>
    </svg>`
  }
  return ''
}

const currentSportRules = computed(() => {
  const sport = selectedRulesSport.value
  if (!sport) return null
  
  const color = getSportColor(sport)
  const icon = getSportEmoji(sport)
  
  let description = ''
  let rules = []
  
  if (sport === 'Football') {
    description = store.state.language === 'hi' 
      ? 'सुंदर खेल। घास या टर्फ पर 11v11, 7v7 या 5v5 का मुकाबला।'
      : 'The beautiful game. 11v11, 7v7 or 5v5 action on grass or turf.'
    rules = [
      { 
        title: store.state.language === 'hi' ? 'फेयर प्ले (स्लाइड्स वर्जित)' : 'Fair Play (No Slides)', 
        desc: store.state.language === 'hi' ? 'चोट से बचने के लिए मनोरंजक खेलों में स्लाइड टैकल पूरी तरह से प्रतिबंधित हैं। अपने पैरों पर रहें!' : 'Slide tackles are strictly prohibited in recreational play to prevent injury. Stay on your feet!' 
      },
      { 
        title: store.state.language === 'hi' ? 'गोल क्षेत्र और रक्षक' : 'Goal Area & Keepers', 
        desc: store.state.language === 'hi' ? 'गोलकीपर केवल निर्धारित पेनल्टी क्षेत्र के भीतर ही गेंद को छू सकते हैं। बैक-पास हाथ से नहीं पकड़े जा सकते।' : 'Goalkeepers can only handle the ball inside the designated penalty area. No back-passes can be handled.' 
      },
      { 
        title: store.state.language === 'hi' ? 'रीस्टार्ट' : 'Restarts', 
        desc: store.state.language === 'hi' ? 'स्थल शैली के आधार पर टचलाइन से किक-इन या थ्रो-इन। सभी फ्री किक में सुरक्षात्मक दूरी का सम्मान किया जाना चाहिए।' : 'Kick-ins or throw-ins from the touchline depending on venue style. All free kicks must respect defensive distance.' 
      },
      { 
        title: store.state.language === 'hi' ? 'ऑफसाइड नियम' : 'Offside Rule', 
        desc: store.state.language === 'hi' ? 'आमतौर पर 5v5/7v7 छोटे आकार के मैचों में ऑफसाइड लागू नहीं होता है जब तक कि पहले से सहमति न हो।' : 'Offside is typically not enforced in 5v5/7v7 small-sided matches unless explicitly agreed beforehand.' 
      }
    ]
  } else if (sport === 'Cricket') {
    description = store.state.language === 'hi'
      ? 'बल्ला, गेंद और क्षेत्ररक्षण। टी20 या आवश्यकतानुसार कस्टम ओवर प्रारूप।'
      : 'Bat, bowl, field. T20 or custom overs format.'
    rules = [
      {
        title: store.state.language === 'hi' ? 'प्रारूप और ओवर' : 'Format & Overs',
        desc: store.state.language === 'hi' ? 'आमतौर पर टी20 या कस्टम ओवर प्रारूप में खेला जाता है। गेंदबाजों के लिए प्रति मैच अधिकतम 4 ओवर की सीमा है।' : 'Usually played as T20 or custom overs format. Bowlers are restricted to a maximum of 4 overs per match.'
      },
      {
        title: store.state.language === 'hi' ? 'रन बनाना' : 'Scoring Runs',
        desc: store.state.language === 'hi' ? 'रन विकेटों के बीच दौड़कर या सीमा पार (टप्पा खाकर 4 रन, हवा में 6 रन) मारकर बनाए जाते हैं।' : 'Runs are scored by running between wickets or hitting boundaries (4 runs on bounce, 6 runs aerial).'
      },
      {
        title: store.state.language === 'hi' ? 'अतिरिक्त दंड' : 'Extra Penalties',
        desc: store.state.language === 'hi' ? 'वाइड और नो-बॉल बल्लेबाजी टीम को 1 अतिरिक्त रन प्रदान करते हैं, और नो-बॉल पर अगली गेंद फ्री हिट होती है।' : 'Wides and No-balls grant 1 extra run to the batting team, and No-balls grant a Free Hit on the next delivery.'
      },
      {
        title: store.state.language === 'hi' ? 'बर्खास्तगी (आउट) के प्रकार' : 'Dismissal Types',
        desc: store.state.language === 'hi' ? 'बल्लेबाज को बोल्ड, कैच, एलबीडब्ल्यू, रन आउट, स्टंप्ड, या हित विकेट के माध्यम से आउट किया जा सकता है।' : 'Batsmen can be dismissed via Bowled, Caught, LBW, Run Out, Stumped, or Hit Wicket.'
      }
    ]
  } else if (sport === 'Badminton') {
    description = store.state.language === 'hi'
      ? 'शटलकॉक के साथ जाल के ऊपर खेला जाने वाला तेज गति वाला रैकेट खेल।'
      : 'Fast-paced racket sport played over a net with shuttlecocks.'
    rules = [
      {
        title: store.state.language === 'hi' ? 'अंडरहैंड सर्विस' : 'Underhand Serve',
        desc: store.state.language === 'hi' ? 'सर्विस सर्वर की कमर के नीचे से अंडरहैंड होनी चाहिए। शटलकॉक प्रतिद्वंद्वी के विपरीत सर्विस कोर्ट में जानी चाहिए।' : 'The serve must be hit underhand from below the server\'s waist. The shuttlecock must travel diagonally into the opponent\'s service court.'
      },
      {
        title: store.state.language === 'hi' ? 'स्कोरिंग प्रारूप' : 'Scoring Format',
        desc: store.state.language === 'hi' ? 'मैच 21 अंकों के सर्वश्रेष्ठ 3 खेलों के रूप में खेले जाते हैं। प्रत्येक रैली में एक अंक प्राप्त होता है।' : 'Matches are played as best of 3 games of 21 points. A point is scored on every rally (rally scoring).'
      },
      {
        title: store.state.language === 'hi' ? 'फाउल (त्रुटि)' : 'Fault Calls',
        desc: store.state.language === 'hi' ? 'यदि शटलकॉक जाल को छूती है, बाहर गिरती है, या यदि खिलाड़ी अपने शरीर या रैकेट से जाल को छूता है तो फाउल होता।' : 'It is a fault if the shuttlecock touches the net, lands out of bounds, or if a player touches the net with their body or racket.'
      },
      {
        title: store.state.language === 'hi' ? 'अंदर या बाहर' : 'In or Out',
        desc: store.state.language === 'hi' ? 'सीमा रेखा पर गिरने वाले शटलकॉक को इन-बाउंड (अंदर) माना जाता है।' : 'Shuttlecocks landing on the boundary line are considered in-bounds.'
      }
    ]
  } else if (sport === 'Basketball') {
    description = store.state.language === 'hi'
      ? 'हूप एक्शन। 5v5 फुल-कोर्ट या 3v3 हाफ-कोर्ट खेल।'
      : 'Hoop action. 5v5 full-court or 3v3 half-court play.'
    rules = [
      {
        title: store.state.language === 'hi' ? 'स्कोरिंग प्रणाली' : 'Scoring System',
        desc: store.state.language === 'hi' ? 'मैच 5v5 फुल-कोर्ट या 3v3 हाफ-कोर्ट हो सकते हैं। आर्क के अंदर टोकरी 2 अंक, बाहर 3 अंक दिलाती है।' : 'Matches can be 5v5 full-court or 3v3 half-court. Baskets inside the arc count for 2 points, outside for 3.'
      },
      {
        title: store.state.language === 'hi' ? 'ड्रिब्लिंग नियम' : 'Dribbling Rules',
        desc: store.state.language === 'hi' ? 'डबल ड्रिब्लिंग और ट्रैवलिंग (ड्रिबल किए बिना 2 से अधिक कदम उठाना) उल्लंघन हैं।' : 'Double dribbling and traveling (taking more than 2 steps without dribbling) are violations.'
      },
      {
        title: store.state.language === 'hi' ? 'व्यक्तिगत फाउल' : 'Personal Fouls',
        desc: store.state.language === 'hi' ? 'अत्यधिक शारीरिक संपर्क से बचें। रक्षकों को बिना ब्लॉक किए कानूनी रक्षात्मक स्थिति बनानी चाहिए।' : 'Avoid excessive physical contact. Defenders must establish legal guarding position without reaching/blocking.'
      },
      {
        title: store.state.language === 'hi' ? 'कब्जा और घड़ी' : 'Possession & Clock',
        desc: store.state.language === 'hi' ? 'मानक 24-सेकंड शॉट क्लॉक (यदि लागू हो) या स्वयं-रेफरी मोड। 3v3 में गेंद मिलने पर आर्क के पार ले जाएं।' : 'Standard 24-second shot clock (if applicable) or self-refereed turnover flow. Clear the ball past the arc on changes in 3v3.'
      }
    ]
  } else if (sport === 'Tennis') {
    description = store.state.language === 'hi'
      ? 'मिट्टी, घास या हार्ड कोर्ट पर क्लासिक एकल या युगल रैकेट खेल।'
      : 'Classic singles or doubles racket game on clay, grass, or hard court.'
    rules = [
      {
        title: store.state.language === 'hi' ? 'सर्विस अनुक्रम' : 'Serving Sequence',
        desc: store.state.language === 'hi' ? 'बेसलाइन के पीछे से तिरछे सर्विस करें। यदि गेंद जाल के ऊपरी हिस्से को छूकर सही बॉक्स में गिरती है, तो लेट (दोबारा खेल) होता है।' : 'Serve diagonally behind the baseline. If it hits the net tape and lands in the correct box, it is a let (replay).'
      },
      {
        title: store.state.language === 'hi' ? 'स्कोरिंग प्रारूप' : 'Scoring Format',
        desc: store.state.language === 'hi' ? 'खेलों को 15, 30, 40, गेम के रूप में स्कोर किया जाता है। सेट जीतने के लिए 6 खेल जीतने होते हैं, कम से कम 2 खेलों की बढ़त के साथ।' : 'Games are scored 15, 30, 40, Game. Winning a set requires winning 6 games, with at least a 2-game lead.'
      },
      {
        title: store.state.language === 'hi' ? 'Line Calls' : 'Line Calls',
        desc: store.state.language === 'hi' ? 'सीमा रेखा के किसी भी हिस्से पर गिरने वाली गेंद को अंदर माना जाता है। खिलाड़ी अपनी तरफ की लाइन कॉल करते हैं।' : 'Any ball landing on any part of the boundary line is considered in. Players call lines on their side of the net.'
      },
      {
        title: store.state.language === 'hi' ? 'नेट प्ले' : 'Net Play',
        desc: store.state.language === 'hi' ? 'गेंद खेल में रहने के दौरान कोई भी खिलाड़ी या उसका रैकेट जाल को नहीं छू सकता है। गेंद मारने के लिए नेट के ऊपर पहुंचना फाउल है।' : 'No player or their racket may touch the net while the ball is in play. Reaching over the net to hit a ball is a foul.'
      }
    ]
  } else if (sport === 'Padel') {
    description = store.state.language === 'hi'
      ? 'तेजी से बढ़ता हुआ बंद युगल रैकेट खेल जिसमें टेनिस और स्क्वैश का संयोजन है।'
      : 'Fast-growing enclosed doubles racket sport combining tennis and squash.'
    rules = [
      {
        title: store.state.language === 'hi' ? 'कोर्ट और उपकरण' : 'Court & Equipment',
        desc: store.state.language === 'hi' ? 'कांच की दीवारों वाले 10x20 मीटर के बंद कोर्ट में युगल में खेला जाता है। पैडल रैकेट बिना तार के ठोस होते हैं।' : 'Played in doubles on an enclosed 10x20m court with glass walls. Padel rackets are solid with no strings.'
      },
      {
        title: store.state.language === 'hi' ? 'अंडरहैंड सर्विस' : 'Underhand Service',
        desc: store.state.language === 'hi' ? 'सर्विस कमर या उससे नीचे के स्तर पर अंडरहैंड की जानी चाहिए। गेंद प्रतिद्वंद्वी के विपरीत सर्विस बॉक्स में टप्पा खानी चाहिए।' : 'Serves must be hit underhand at or below waist level. The ball must bounce once in the diagonally opposite service box.'
      },
      {
        title: store.state.language === 'hi' ? 'दीवार बाउंस नियम' : 'Wall Bounce Rules',
        desc: store.state.language === 'hi' ? 'प्रतिद्वंद्वी के कोर्ट में टप्पा खाने के बाद, गेंद कांच या जालीदार दीवार से टकरा सकती है। जाली/कांच पर सीधी हिट बाहर (आउट) मानी जाती है।' : 'After bouncing in the opponent\'s court, the ball may strike any glass or mesh wall. Direct hits to mesh/glass are out.'
      },
      {
        title: store.state.language === 'hi' ? 'निर्णायक अंक (स्वर्ण)' : 'Deciding Point (Gold)',
        desc: store.state.language === 'hi' ? 'यदि स्कोर ड्यूस (40-40) तक पहुंच जाता है, तो एकल निर्णायक स्वर्ण बिंदु खेला जाता है। रिसीवर अपनी पसंद की दिशा चुनते हैं।' : 'If the score reaches Deuce (40-40), a single deciding Golden Point is played. Receivers choose the side.'
      }
    ]
  } else {
    description = store.state.language === 'hi' ? 'सामान्य खेल नियम और दिशा-निर्देश।' : 'General game rules and match guidelines.'
    rules = [
      {
        title: store.state.language === 'hi' ? 'ईमानदारी और खेल भावना' : 'Fair Play',
        desc: store.state.language === 'hi' ? 'हमेशा ईमानदारी से खेलें, विरोधियों और आयोजन स्थल के कर्मचारियों का सम्मान करें।' : 'Play with integrity and show respect for opponents, teammates, and venue staff.'
      },
      {
        title: store.state.language === 'hi' ? 'सुरक्षा प्रथम' : 'Safety First',
        desc: store.state.language === 'hi' ? 'सुरक्षा को खतरे में डालने वाले लापरवाह टकराव या खतरनाक कार्यों से बचें।' : 'Avoid dangerous actions, reckless collisions, and play that threatens player safety.'
      }
    ]
  }
  
  return {
    color,
    icon,
    description,
    rules
  }
})

const handleThemeToggle = (e) => {
  const checked = e.target.checked
  store.setThemePreference(checked ? 'elegantLavender' : 'activeSteelBlue')
}

const showLogoutConfirm = ref(false)

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
const editEmail = ref('')
const editBio = ref('')
const editSport = ref('')
const editSkill = ref('')
const editGender = ref('')

const openEditModal = () => {
  editName.value = currentUser.value.name || ''
  editEmail.value = currentUser.value.email || ''
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
      editSkill.value,
      editEmail.value.trim()
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



// Track total ratings given by the user
const totalRatingsGiven = computed(() => {
  return profileStats.value.totalRatingsGiven || 0
})

// Dynamic Profile Theme & Achievements Code

const uniqueSportsPlayedCount = computed(() => {
  const sports = playedMatches.value.map(m => m.sport_type).filter(Boolean)
  return new Set(sports).size
})

const isCommunityPillar = computed(() => {
  const uid = props.isCurrentUser ? store.state.currentUser?.id : props.userId
  if (!uid) return false
  const total = playedMatches.value.length
  if (total === 0) return false
  const created = playedMatches.value.filter(m => Number(m.creator_id || m.user_id) === Number(uid)).length
  return (created / total) >= 0.40
})

const isInvincible = computed(() => {
  return calculatedStreak.value >= 5
})

const isFairPlayAmbassador = computed(() => {
  const avgRating = Number(profileStats.value.averageRating || 0)
  const totalGames = Number(profileStats.value.totalGames || 0)
  return avgRating >= 4.5 && totalGames >= 5
})

const isUltimateAllRounder = computed(() => {
  return uniqueSportsPlayedCount.value >= 3
})

// Combined Achievements & Milestones List
const achievementsList = computed(() => {
  const lvl = profileStats.value.level || 1
  const uid = props.isCurrentUser ? store.state.currentUser?.id : props.userId
  const total = playedMatches.value.length
  const created = playedMatches.value.filter(m => Number(m.creator_id || m.user_id) === Number(uid)).length

  return [
    // Milestones
    {
      id: 'rookie',
      type: 'milestone',
      title: 'Rookie Milestone',
      description: 'Welcome to Sportigo! Level 1 reached.',
      icon: '🌱',
      unlocked: true,
      progressText: `Level ${lvl} / 1`
    },
    {
      id: 'rising_star',
      type: 'milestone',
      title: 'Rising Star Milestone',
      description: 'Reach Level 2 to show your potential.',
      icon: '✨',
      unlocked: lvl >= 2,
      progressText: `Level ${lvl} / 2`
    },
    {
      id: 'veteran',
      type: 'milestone',
      title: 'Veteran Milestone',
      description: 'Reach Level 5. Unlocks the Lavender Dusk profile theme.',
      icon: '🎖️',
      unlocked: lvl >= 5,
      progressText: `Level ${lvl} / 5`
    },
    {
      id: 'competitor',
      type: 'milestone',
      title: 'Elite Competitor Milestone',
      description: 'Reach Level 10. Unlocks the Gold Rush profile theme.',
      icon: '🏆',
      unlocked: lvl >= 10,
      progressText: `Level ${lvl} / 10`
    },
    {
      id: 'legend',
      type: 'milestone',
      title: 'Sportigo Legend Milestone',
      description: 'Reach Level 25. Unlocks the animated Golden Legend profile theme.',
      icon: '👑',
      unlocked: lvl >= 25,
      progressText: `Level ${lvl} / 25`
    },
    // Badges
    {
      id: 'community_pillar',
      type: 'badge',
      title: 'Community Pillar',
      description: 'Organize at least 40% of the matches you play (minimum 1 game).',
      icon: '📣',
      unlocked: isCommunityPillar.value,
      progressText: `${total > 0 ? Math.round((created / total) * 100) : 0}% matches organized (${created}/${total})`
    },
    {
      id: 'invincible',
      type: 'badge',
      title: 'Invincible',
      description: 'Maintain a winning streak of 5 matches or more.',
      icon: '🔥',
      unlocked: isInvincible.value,
      progressText: `Streak: ${calculatedStreak.value} / 5`
    },
    {
      id: 'fair_play',
      type: 'badge',
      title: 'Fair Play Ambassador',
      description: 'Maintain an average rating of 4.5+ with at least 5 games played.',
      icon: '🤝',
      unlocked: isFairPlayAmbassador.value,
      progressText: `Rating: ${Number(profileStats.value.averageRating || 0).toFixed(1)}/4.5 (${profileStats.value.totalGames || 0}/5 games)`
    },
    {
      id: 'all_rounder',
      type: 'badge',
      title: 'Ultimate All-Rounder',
      description: 'Play at least 3 unique sport types.',
      icon: '🎯',
      unlocked: isUltimateAllRounder.value,
      progressText: `${uniqueSportsPlayedCount.value} / 3 sports played`
    }
  ]
})

// Profile Background Style
const profileBackgroundStyle = computed(() => {
  if (isLavenderTheme.value) {
    return { background: 'linear-gradient(180deg, rgba(139, 92, 246, 0.18) 0%, rgba(224, 204, 250, 0.08) 150px, var(--scaffold-bg) 350px, var(--scaffold-bg) 100%)' }
  }
  // Default sport-based background
  return { background: `linear-gradient(180deg, ${currentSportColor.value}2E 0%, var(--scaffold-bg) 350px, var(--scaffold-bg) 100%)` }
})

// Avatar Border CSS Class
const avatarBorderClass = computed(() => {
  const lvl = profileStats.value.level || 1
  if (lvl >= 25) return 'border-legend'
  if (lvl >= 10) return 'border-gold-elite'
  if (lvl >= 5) return 'border-gold'
  if (lvl >= 2) return 'border-silver'
  return 'border-bronze'
})

// Streaks computed status
const weekDaysStatus = computed(() => {
  const now = new Date()
  const currentMonday = getMonday(now)
  currentMonday.setDate(currentMonday.getDate() + weekOffset.value * 7)
  currentMonday.setHours(0, 0, 0, 0)

  const daysLabel = ['M', 'T', 'W', 'T', 'F', 'S', 'S']
  
  return daysLabel.map((label, index) => {
    const targetDate = new Date(currentMonday)
    targetDate.setDate(currentMonday.getDate() + index)
    
    const hasPlayed = playedMatches.value.some(m => {
      const dateStr = m.date_time || m.date
      if (!dateStr) return false
      const matchDate = new Date(dateStr.replace(' ', 'T'))
      return matchDate.getFullYear() === targetDate.getFullYear() &&
             matchDate.getMonth() === targetDate.getMonth() &&
             matchDate.getDate() === targetDate.getDate()
    })
    
    return {
      label,
      date: targetDate,
      hasPlayed
    }
  })
})


</script>

<template>
  <div 
    class="profile-container scrollable-y animate-fade-in"
    :style="profileBackgroundStyle"
  >
    <div class="profile-content-wrap">
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
        <img :src="avatarUrl" class="card-avatar" :class="avatarBorderClass" @error="(e) => e.target.src = '/assets/images/players/download.jpg'" />
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
        <span v-if="calculatedStreak > 0" class="xp-streak-tag">🔥 {{ calculatedStreak }} Day Winning Streak</span>
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
      
      <!-- Card 2: Primary Sport -->
      <div class="new-stat-card">
        <div class="stat-header">
          <span class="stat-card-title">{{ t('primarySport') }}</span>
          <span class="stat-svg-container">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#06b6d4" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="stat-card-svg"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/></svg>
          </span>
        </div>
        <div class="stat-card-value">{{ currentUser.primary_sport || 'None' }}</div>
      </div>

      <!-- Card 3: Total Games -->
      <div class="new-stat-card">
        <div class="stat-header">
          <span class="stat-card-title">{{ t('totalGames') }}</span>
          <span class="stat-svg-container">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#10b981" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="stat-card-svg"><circle cx="12" cy="12" r="10"/><path d="m12 2-1.91 3.42L6.2 5.09M12 22l1.91-3.42 3.89.33M2.05 12.5l3.82-.76-.36-3.89M21.95 11.5l-3.82.76.36 3.89M12 7.5 9 9.5v3l3 2 3-2v-3Z"/><path d="M9 9.5 6.2 5.09M9 12.5l-3.48 2.54M12 14.5v3.42M15 12.5l3.48 2.54M15 9.5l2.8-4.41"/></svg>
          </span>
        </div>
        <div class="stat-card-value">{{ profileStats.totalGames }}</div>
      </div>

      <!-- Card 4: Average Rating -->
      <div class="new-stat-card">
        <div class="stat-header">
          <span class="stat-card-title">{{ t('averageRating') }}</span>
          <span class="stat-svg-container">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#eab308" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="stat-card-svg"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
          </span>
        </div>
        <div class="stat-card-value">{{ Number(profileStats.averageRating || 0).toFixed(1) }} ⭐</div>
      </div>
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
        <template v-if="sortedActivities.length > 0">
          <div v-for="act in visibleActivities" :key="act.id" class="activity-tile-new">
            <div class="activity-left">
              <span 
                class="activity-icon-circle"
                :class="act.type === 'match_created' ? 'bg-light-green' : act.type === 'match_left' ? 'bg-light-red' : 'bg-light-blue'"
                style="display: flex; align-items: center; justify-content: center; font-size: 1.1rem;"
              >
                <span>{{ act.sportType === 'Football' ? '⚽' : act.sportType === 'Cricket' ? '🏏' : act.sportType === 'Basketball' ? '🏀' : act.sportType === 'Tennis' ? '🎾' : act.sportType === 'Badminton' ? '🏸' : act.sportType === 'Padel' ? '🏓' : '🏃' }}</span>
              </span>
              <div class="activity-info-new">
                <span class="activity-title-new">
                  {{ act.type === 'match_created' ? 'Organized' : act.type === 'match_left' ? 'Left' : 'Joined' }} 
                  {{ act.sportType || 'Sports' }} Match
                </span>
                <span class="activity-desc-new">{{ act.matchTitle }} at {{ act.meta?.location || 'Unknown' }} • {{ formatDate(act.created_at) }}</span>
              </div>
            </div>
            <span class="xp-badge-new" :class="{ 'negative-xp': act.type === 'match_left' }">
              {{ getActivityXp(act) > 0 ? '+' : '' }}{{ getActivityXp(act) }} XP
            </span>
          </div>
          <div v-if="sortedActivities.length > 4" class="see-all-container">
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
      <div v-else-if="activeSegmentTab === 1" class="panel-content achievements-panel animate-fade-in">
        <!-- Milestone Header -->
        <h4 class="achievements-section-title">Level Milestones</h4>
        <div class="achievements-grid">
          <div 
            v-for="item in achievementsList.filter(a => a.type === 'milestone')" 
            :key="item.id"
            class="achievement-item-card"
            :class="{ locked: !item.unlocked, 'unlocked-milestone': item.unlocked }"
          >
            <div class="achievement-icon-wrapper">
              <span class="achievement-icon">{{ item.icon }}</span>
              <span v-if="!item.unlocked" class="lock-indicator">🔒</span>
            </div>
            <div class="achievement-details">
              <h5 class="achievement-name">{{ item.title }}</h5>
              <p class="achievement-desc">{{ item.description }}</p>
              <div class="achievement-progress-row">
                <span class="achievement-progress-text">{{ item.progressText }}</span>
                <span class="achievement-status" :class="item.unlocked ? 'status-unlocked' : 'status-locked'">
                  {{ item.unlocked ? 'Unlocked' : 'Locked' }}
                </span>
              </div>
            </div>
          </div>
        </div>

        <!-- Badges Header -->
        <h4 class="achievements-section-title" style="margin-top: 24px;">Stat-Based Badges</h4>
        <div class="achievements-grid">
          <div 
            v-for="item in achievementsList.filter(a => a.type === 'badge')" 
            :key="item.id"
            class="achievement-item-card"
            :class="{ locked: !item.unlocked, 'unlocked-badge': item.unlocked }"
          >
            <div class="achievement-icon-wrapper">
              <span class="achievement-icon">{{ item.icon }}</span>
              <span v-if="!item.unlocked" class="lock-indicator">🔒</span>
            </div>
            <div class="achievement-details">
              <h5 class="achievement-name">{{ item.title }}</h5>
              <p class="achievement-desc">{{ item.description }}</p>
              <div class="achievement-progress-row">
                <span class="achievement-progress-text">{{ item.progressText }}</span>
                <span class="achievement-status" :class="item.unlocked ? 'status-unlocked' : 'status-locked'">
                  {{ item.unlocked ? 'Active' : 'Inactive' }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Streaks -->
      <div v-else class="panel-content streaks-panel animate-fade-in">
        <div class="streak-card">
          <div class="streak-card-header">
            <div class="streak-header-left">
              <h4 class="streak-title-text">
                🔥 {{ calculatedStreak }} Day Winning Streak
              </h4>
              <p class="streak-subtitle-text">
                {{ calculatedStreak > 0 ? 'Keep playing matches daily to grow your streak!' : 'Play matches daily to keep your streak!' }}
              </p>
            </div>
            <div class="streak-header-right" style="display: flex; align-items: center;">
              <!-- Week Navigator controls -->
              <div class="week-navigator-container" style="display: inline-flex; align-items: center; background: #f1f5f9; padding: 4px; border-radius: 12px; margin-right: 12px; border: 1px solid #cbd5e1;">
                <button 
                  @click="weekOffset--"
                  type="button"
                  style="background: transparent; border: none; width: 28px; height: 28px; display: flex; align-items: center; justify-content: center; color: #64748b; cursor: pointer; font-weight: bold; border-radius: 8px; transition: background 0.2s;"
                  onmouseover="this.style.background='#e2e8f0'; this.style.color='#0f172a';"
                  onmouseout="this.style.background='transparent'; this.style.color='#64748b';"
                  title="Previous Week"
                >
                  ◀
                </button>
                <span class="week-navigator-label" style="font-size: 0.75rem; font-weight: 800; text-transform: uppercase; color: #475569; min-width: 90px; text-align: center; user-select: none;">
                  {{ weekLabel }}
                </span>
                <button 
                  @click="weekOffset++"
                  :disabled="weekOffset === 0"
                  type="button"
                  style="background: transparent; border: none; width: 28px; height: 28px; display: flex; align-items: center; justify-content: center; color: #64748b; cursor: pointer; font-weight: bold; border-radius: 8px; transition: background 0.2s;"
                  onmouseover="if(!this.disabled) { this.style.background='#e2e8f0'; this.style.color='#0f172a'; }"
                  onmouseout="this.style.background='transparent'; this.style.color='#64748b';"
                  :style="weekOffset === 0 ? { opacity: '0.3', cursor: 'not-allowed' } : {}"
                  title="Next Week"
                >
                  ▶
                </button>
              </div>
            </div>
          </div>
          
          <div class="streak-days-row">
            <div 
              v-for="(day, idx) in weekDaysStatus" 
              :key="idx" 
              class="streak-day-col"
            >
              <div 
                class="streak-day-indicator"
                :class="{ 'day-played': day.hasPlayed, 'day-missed': !day.hasPlayed }"
              >
                <svg v-if="day.hasPlayed" class="indicator-svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                  <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
                <svg v-else class="indicator-svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                  <line x1="18" y1="6" x2="6" y2="18"></line>
                  <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
              </div>
              <span class="streak-day-label">{{ day.label }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Settings Full-Screen Panel -->
    <Transition name="settings-slide">
      <div v-if="showSettingsModal" class="settings-fullscreen-panel" :class="{ 'theme-women': store.isWomenMode.value }">
        <div class="settings-panel-header">
          <h2 class="settings-panel-title modal-title">{{ t('settings') }}</h2>
          <button class="settings-close-btn close-btn" @click="showSettingsModal = false">
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

            <!-- Elegant Lavender Theme Toggle -->
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
          <div class="privacy-section">
            <h4 class="section-sub-title">{{ store.state.language === 'hi' ? 'खाता और विकल्प' : 'Account & Options' }}</h4>
            <div class="settings-menu-list">
              <div class="menu-tile" @click="() => { showSettingsModal = false; openEditModal(); }">
                <span class="menu-icon">✏️</span>
                <div class="menu-info">
                  <span class="menu-title">{{ t('editProfile') }}</span>
                  <span class="menu-subtitle">Update display name, bio, and settings</span>
                </div>
                <span class="chevron">➔</span>
              </div>

              <div class="menu-tile" @click="() => { console.log('Game Rules clicked'); showRulesModal = true; }">
                <span class="menu-icon">🛡️</span>
                <div class="menu-info">
                  <span class="menu-title">{{ t('gameRules') }}</span>
                  <span class="menu-subtitle">{{ t('gameRulesSub') }}</span>
                </div>
                <span class="chevron">➔</span>
              </div>

              <div class="menu-tile" @click="() => { console.log('Company Policies clicked'); showPoliciesModal = true; }">
                <span class="menu-icon">📄</span>
                <div class="menu-info">
                  <span class="menu-title">{{ t('statsHistory') }}</span>
                  <span class="menu-subtitle">{{ t('statsHistorySub') }}</span>
                </div>
                <span class="chevron">➔</span>
              </div>

              <div class="menu-tile destructive" @click="showLogoutConfirm = true">
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
      </div>
    </Transition>

    <!-- Game Rules Full-Screen Panel -->
    <Transition name="settings-slide">
      <div v-if="showRulesModal" class="rules-fullscreen-panel" :class="{ 'theme-women': store.isWomenMode.value }">
        <!-- Main Sports Options List View -->
        <div v-if="!selectedRulesSport" class="rules-main-view flex-col h-full" style="display: flex; flex-direction: column; height: 100%;">
          <div class="settings-panel-header">
            <h2 class="settings-panel-title modal-title" style="display: flex; align-items: center; gap: 8px;">
              <span>🛡️</span>
              <span>{{ store.state.language === 'hi' ? 'खेल के नियम' : 'Game Rules' }}</span>
            </h2>
            <button class="settings-close-btn close-btn" @click="showRulesModal = false">
              <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
            </button>
          </div>

          <div class="settings-panel-body scrollable-y flex-1 no-scrollbar" style="flex: 1; overflow-y: auto;">
            <p class="rules-intro-text">{{ store.state.language === 'hi' ? 'दिशानिर्देश और नियम देखने के लिए एक खेल चुनें:' : 'Select a sport to view its detailed rules and match guidelines:' }}</p>
            
            <div class="rules-sports-grid">
              <div 
                v-for="sport in sportsList" 
                :key="sport.name" 
                class="rules-sport-card-option"
                :style="{ borderLeft: `5px solid ${getSportColor(sport.name)}` }"
                @click="selectedRulesSport = sport.name"
              >
                <div class="rules-option-icon" :style="{ backgroundColor: `${getSportColor(sport.name)}1A`, color: getSportColor(sport.name) }">
                  <div class="rules-option-icon-svg" v-html="getSportSVG(sport.name)"></div>
                </div>
                <div class="rules-option-info">
                  <span class="rules-option-title">{{ store.state.language === 'hi' ? t('sport_' + sport.name) : sport.name }}</span>
                  <span class="rules-option-subtitle">{{ getSportSubtitle(sport.name) }}</span>
                </div>
                <span class="rules-option-arrow" :style="{ color: getSportColor(sport.name) }">➔</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Sport Detailed Rules View -->
        <div v-else class="rules-detail-view flex-col h-full animate-fade-in" style="display: flex; flex-direction: column; height: 100%;" :key="selectedRulesSport">
          <div class="settings-panel-header" :style="{ borderBottom: `2px solid ${currentSportRules.color}20` }">
            <h2 class="settings-panel-title modal-title" style="display: flex; align-items: center; gap: 8px;">
              <div class="rules-header-icon-svg" v-html="getSportSVG(selectedRulesSport)"></div>
              <span>{{ store.state.language === 'hi' ? t('sport_' + selectedRulesSport) : selectedRulesSport }} {{ store.state.language === 'hi' ? 'के नियम' : 'Rules' }}</span>
            </h2>
            <button class="settings-close-btn close-btn" @click="selectedRulesSport = null">
              <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
            </button>
          </div>

          <div class="settings-panel-body scrollable-y flex-1 no-scrollbar" style="flex: 1; overflow-y: auto;">
            <div class="rules-sport-info-card" :style="{ background: getSportGradient(selectedRulesSport) }">
              <div class="rules-sport-info-header-wrap">
                <div class="rules-sport-avatar-circle">
                  <div class="rules-sport-avatar-svg" v-html="getSportSVG(selectedRulesSport)"></div>
                </div>
                <h3 class="rules-sport-title-text">{{ store.state.language === 'hi' ? t('sport_' + selectedRulesSport) : selectedRulesSport }}</h3>
                <p class="rules-sport-desc-text">{{ currentSportRules.description }}</p>
              </div>
            </div>

            <div class="rules-list-container">
              <div v-for="(rule, index) in currentSportRules.rules" :key="index" class="rule-item-card">
                <div class="rule-item-number" :style="{ backgroundColor: currentSportRules.color }">{{ index + 1 }}</div>
                <div class="rule-item-content">
                  <h4 class="rule-item-title">{{ rule.title }}</h4>
                  <p class="rule-item-description">{{ rule.desc }}</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Company Policies Full-Screen Panel -->
    <Transition name="settings-slide">
      <div v-if="showPoliciesModal" class="rules-fullscreen-panel" :class="{ 'theme-women': store.isWomenMode.value }">
        <div class="rules-main-view flex-col h-full" style="display: flex; flex-direction: column; height: 100%;">
          <div class="settings-panel-header">
            <h2 class="settings-panel-title modal-title" style="display: flex; align-items: center; gap: 8px;">
              <span>📄</span>
              <span>{{ t('statsHistory') }}</span>
            </h2>
            <button class="settings-close-btn close-btn" @click="showPoliciesModal = false">
              <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
            </button>
          </div>

          <div class="settings-panel-body scrollable-y flex-1 no-scrollbar" style="flex: 1; overflow-y: auto;">
            <!-- Policies list -->
            <div class="policies-list">
              <div class="policy-item-card">
                <div class="policy-header-row">
                  <h4 class="policy-item-title">{{ store.state.language === 'hi' ? '1. खाता सुरक्षा और प्रमाणीकरण' : '1. Account Security & Verification' }}</h4>
                </div>
                <p class="policy-item-description">
                  {{ store.state.language === 'hi' ? 'पासवर्ड भूल जाने की स्थिति में त्वरित और सुरक्षित प्रमाणीकरण के लिए सभी उपयोगकर्ताओं को एक वैध ईमेल पता प्रदान करना आवश्यक है। यह सुनिश्चित करता है कि आपके व्यक्तिगत आंकड़े, बुकिंग और भुगतान इतिहास सुरक्षित रहें।' : 'To guarantee quick and secure authentication, especially in the event of a forgotten password, all players must register with a valid email. This ensures that your progress, stats, and personal bookings remain secure and recoverable.' }}
                </p>
              </div>

              <div class="policy-item-card">
                <div class="policy-header-row">
                  <h4 class="policy-item-title">{{ store.state.language === 'hi' ? '2. आचार संहिता और निष्पक्ष खेल' : '2. Code of Conduct & Fair Play' }}</h4>
                </div>
                <p class="policy-item-description">
                  {{ store.state.language === 'hi' ? 'टूर्नामेंट और मैत्रीपूर्ण मैचों के दौरान खेल भावना बनाए रखें। किसी भी प्रकार की अभद्र भाषा, धोखाधड़ी या अभद्र व्यवहार के परिणामस्वरूप स्थायी खाता निलंबन किया जाएगा।' : 'Maintain a respectful, friendly environment during matches. PlayConnect has a zero-tolerance policy for harassment, cheating, or unsportsmanlike behavior. Violation of code of conduct can lead to permanent account suspension.' }}
                </p>
              </div>

              <div class="policy-item-card">
                <div class="policy-header-row">
                  <h4 class="policy-item-title">{{ store.state.language === 'hi' ? '3. सुरक्षा और संरक्षा नीतियां' : '3. Safety & Safety Policies' }}</h4>
                </div>
                <p class="policy-item-description">
                  {{ store.state.language === 'hi' ? 'महिलाओं के लिए विशिष्ट रूप से चिह्नित मैचों में केवल महिला खिलाड़ी ही शामिल हो सकती हैं। प्लेकनेक्ट सभी खिलाड़ियों के लिए एक समावेशी, मैत्रीपूर्ण और सुरक्षित खेल मैदान प्रदान करने के लिए प्रतिबद्ध है।' : 'Only verified female players can join matches designated as "Women-Only". PlayConnect is committed to providing a safe, friendly, and inclusive sporting ecosystem for everyone.' }}
                </p>
              </div>

              <div class="policy-item-card">
                <div class="policy-header-row">
                  <h4 class="policy-item-title">{{ store.state.language === 'hi' ? '4. रद्दीकरण और धनवापसी नीति' : '4. Cancellation & Refund Policy' }}</h4>
                </div>
                <p class="policy-item-description">
                  {{ store.state.language === 'hi' ? 'यदि बुकिंग शुरू होने से 24 घंटे पहले रद्द की जाती है, तो पूरी राशि वापस कर दी जाएगी। अंतिम समय में बुकिंग रद्द करने पर धनवापसी नहीं मिलेगी।' : 'Full refund is available if a match spot or booking is cancelled at least 24 hours prior to the scheduled start. Cancellations made within 24 hours of the match start time are non-refundable.' }}
                </p>
              </div>

              <div class="policy-item-card">
                <div class="policy-header-row">
                  <h4 class="policy-item-title">{{ store.state.language === 'hi' ? '5. देयता की सीमा' : '5. Limitation of Liability' }}</h4>
                </div>
                <p class="policy-item-description">
                  {{ store.state.language === 'hi' ? 'मैच के दौरान खिलाड़ियों को लगी किसी भी शारीरिक चोट के लिए प्लेकनेक्ट या आयोजन स्थल जिम्मेदार नहीं होंगे। सभी खिलाड़ियों को स्वयं की सुरक्षा सुनिश्चित करने की सलाह दी जाती है।' : 'PlayConnect or associated venues are not liable for physical injuries sustained during matches. Players participate at their own risk and are advised to maintain physical fitness and wear proper protective gear.' }}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Transition>

  </div>

    <!-- Followers / Following Modal -->
    <Teleport to="body">
      <div v-if="showFollowListModal" class="modal-backdrop" :class="{ 'theme-women': store.isWomenMode.value }" @click="showFollowListModal = false">
        <div class="modal-sheet animate-slide-up" @click.stop>
          <div class="modal-header">
            <h2 class="modal-title">{{ followListType === 'followers' ? 'Followers' : 'Following' }}</h2>
            <button class="close-btn" @click="showFollowListModal = false">✕</button>
          </div>

          <div class="modal-body scrollable-y">
            <div v-if="loadingFollowList" class="loading-state" style="text-align: center; padding: 32px 0; color: var(--outline);">
              <span>⏳ Loading list...</span>
            </div>
            <div v-else-if="followListUsers.length === 0" class="empty-state" style="text-align: center; padding: 48px 16px; color: #64748b;">
              <span style="font-size: 2.5rem; display: block; margin-bottom: 12px;">👥</span>
              <h3 style="font-size: 1.1rem; font-weight: 700; color: #0f172a; margin-bottom: 6px;">No users found</h3>
              <p style="font-size: 0.82rem; color: #64748b; margin: 0;">This list is currently empty.</p>
            </div>
            <div v-else class="follow-list-group" style="display: flex; flex-direction: column; gap: 14px;">
              <div 
                v-for="user in followListUsers" 
                :key="user.id" 
                class="follow-user-row"
                style="display: flex; align-items: center; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid var(--outline-variant);"
              >
                <!-- User Profile info -->
                <div 
                  class="follow-user-info" 
                  style="display: flex; align-items: center; gap: 12px; cursor: pointer; flex: 1;"
                  @click="navigateToPlayerProfile(user)"
                >
                  <img 
                    :src="getPlayerAvatar(user.avatar || user.profile_picture || user.profile_photo, user.gender)" 
                    class="follow-user-avatar" 
                    style="width: 44px; height: 44px; border-radius: 50%; object-fit: cover;"
                    @error="(e) => e.target.src = '/assets/images/players/download.jpg'"
                  />
                  <div style="display: flex; flex-direction: column;">
                    <span style="font-size: 0.9rem; font-weight: 700; color: var(--on-surface);">{{ user.name }}</span>
                    <span style="font-size: 0.75rem; color: #64748b;">@{{ user.username }}</span>
                  </div>
                </div>

                <!-- Follow toggle button -->
                <button 
                  v-if="store.state.currentUser && user.id !== store.state.currentUser.id"
                  class="list-follow-btn"
                  :class="{ 'following': user.isFollowed }"
                  style="padding: 6px 14px; border-radius: 16px; font-size: 0.78rem; font-weight: 700; cursor: pointer; border: none; transition: all 0.2s ease;"
                  @click="handleListFollowToggle(user)"
                >
                  {{ user.isFollowed ? '✓ Following' : '+ Follow' }}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Teleport>

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

            <!-- Email -->
            <div class="input-group">
              <label class="input-label">Email Address (for Google Login Link)</label>
              <input 
                v-model="editEmail"
                type="email" 
                placeholder="e.g. user@example.com"
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

    <!-- Logout Confirmation Modal -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="showLogoutConfirm" class="logout-confirm-backdrop" @click="showLogoutConfirm = false">
          <div class="logout-confirm-card animate-slide-up" @click.stop>
            <div class="logout-confirm-handle"></div>
            <div class="logout-confirm-icon-wrap">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#dc2626" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="logout-svg"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
            </div>
            <h3 class="logout-confirm-title">Sign Out?</h3>
            <p class="logout-confirm-desc">You will need to log in again.</p>
            <div class="logout-confirm-actions">
              <button class="logout-btn-no" @click="showLogoutConfirm = false">Cancel</button>
              <button class="logout-btn-yes" @click="() => { showLogoutConfirm = false; showSettingsModal = false; handleLogout(); }">Sign Out</button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<style scoped>
.profile-content-wrap {
  width: 100%;
  max-width: 1000px;
  margin: 0 auto;
  position: relative;
}

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
  background-color: #ffffff;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.05);
  transition: all 0.3s ease;
}

/* avatar-online-dot removed */

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

.stat-follow-block {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 4px 12px;
}

.follow-num {
  font-size: 1.15rem;
  font-weight: 800;
  color: #0f172a;
}

.follow-label {
  font-size: 0.72rem;
  color: #64748b;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.follow-divider {
  width: 1px;
  height: 24px;
  background-color: #cbd5e1;
  margin: 0 4px;
}

.profile-actions-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.follow-btn {
  background-color: var(--primary);
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

.follow-btn:hover {
  filter: brightness(1.1);
  transform: translateY(-1px);
}

.follow-btn.following {
  background-color: transparent;
  border: 1.5px solid var(--outline-variant);
  color: var(--on-surface-variant);
  box-shadow: none;
}

.follow-btn.following:hover {
  background-color: rgba(239, 68, 68, 0.05);
  color: #ef4444;
  border-color: #fca5a5;
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

.activity-icon-circle.bg-light-red {
  background-color: #ffebee;
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

.xp-badge-new.negative-xp {
  background-color: #ffebee;
  color: #c62828;
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
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.language-select-dropdown,
.theme-select-dropdown {
  padding: 8px 12px;
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  color: var(--on-surface);
  font-size: 0.85rem;
  font-weight: 600;
  outline: none;
  cursor: pointer;
  font-family: inherit;
  transition: all 0.2s ease;
}

.language-select-dropdown:hover,
.theme-select-dropdown:hover {
  background-color: var(--scaffold-bg);
  border-color: var(--outline);
}

.language-select-dropdown:focus,
.theme-select-dropdown:focus {
  border-color: var(--primary);
  box-shadow: 0 0 0 2px rgba(46, 125, 50, 0.1);
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
  .settings-panel-header {
    padding: 20px 24px 16px;
  }
  .settings-panel-body {
    padding: 20px 24px;
  }
}

.settings-fullscreen-panel .settings-panel-body {
  max-width: 1200px;
  display: grid;
  grid-template-columns: 1fr;
  gap: 32px;
  align-content: start;
}

@media (min-width: 768px) {
  .settings-fullscreen-panel .settings-panel-body {
    grid-template-columns: 1fr 1fr;
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

/* Logout Confirmation Modal */
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

.logout-svg {
  display: flex;
  align-items: center;
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

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.25s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* Avatar dynamic border styling */
.border-bronze {
  border: 4px solid transparent !important;
  background-image: linear-gradient(#fff, #fff), linear-gradient(135deg, #10b981, #34d399, #059669) !important;
  background-origin: border-box !important;
  background-clip: padding-box, border-box !important;
  box-shadow: 0 0 10px rgba(16, 185, 129, 0.35) !important;
}

.border-silver {
  border: 4px solid transparent !important;
  background-image: linear-gradient(#fff, #fff), linear-gradient(135deg, #c0c0c0, #f0f0f0, #8a8a8a) !important;
  background-origin: border-box !important;
  background-clip: padding-box, border-box !important;
  box-shadow: 0 0 12px rgba(192, 192, 192, 0.4) !important;
}

.border-gold {
  border: 4px solid transparent !important;
  background-image: linear-gradient(#fff, #fff), linear-gradient(135deg, #ffd700, #fff3a8, #c5a000) !important;
  background-origin: border-box !important;
  background-clip: padding-box, border-box !important;
  box-shadow: 0 0 16px rgba(255, 215, 0, 0.5) !important;
}

.border-gold-elite {
  border: 4px solid transparent !important;
  background-image: linear-gradient(#fff, #fff), linear-gradient(135deg, #ffd700, #ff8c00, #d97706) !important;
  background-origin: border-box !important;
  background-clip: padding-box, border-box !important;
  box-shadow: 0 0 20px rgba(245, 158, 11, 0.7) !important;
}

.border-legend {
  border: 4px solid transparent !important;
  background-image: linear-gradient(#fff, #fff), linear-gradient(135deg, #8b5cf6, #ec4899, #3b82f6) !important;
  background-origin: border-box !important;
  background-clip: padding-box, border-box !important;
  animation: legendBorderPulse 3s infinite alternate !important;
}

/* Golden Legend Pulsing Radial Glow Overlay */
.golden-radial-glow {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 350px;
  background: radial-gradient(circle, rgba(255, 215, 0, 0.15) 0%, rgba(255, 215, 0, 0) 70%);
  pointer-events: none;
  z-index: 0;
  animation: goldenGlowPulse 4s ease-in-out infinite alternate;
}

@keyframes goldenGlowPulse {
  0% {
    transform: scale(0.95);
    opacity: 0.7;
  }
  100% {
    transform: scale(1.05);
    opacity: 1;
  }
}

@keyframes legendBorderPulse {
  0% {
    background-image: linear-gradient(#fff, #fff), linear-gradient(135deg, #8b5cf6, #ec4899, #3b82f6);
    box-shadow: 0 0 16px rgba(139, 92, 246, 0.4);
  }
  50% {
    background-image: linear-gradient(#fff, #fff), linear-gradient(135deg, #ec4899, #3b82f6, #8b5cf6);
    box-shadow: 0 0 24px rgba(236, 72, 153, 0.7);
  }
  100% {
    background-image: linear-gradient(#fff, #fff), linear-gradient(135deg, #3b82f6, #8b5cf6, #ec4899);
    box-shadow: 0 0 16px rgba(59, 130, 246, 0.4);
  }
}

/* Achievements Section Styles */
.achievements-panel {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 8px 4px;
}

.achievements-section-title {
  font-family: var(--font-display);
  font-size: 1.05rem;
  font-weight: 800;
  color: var(--on-surface);
  text-transform: uppercase;
  letter-spacing: 0.5px;
  margin-bottom: 4px;
  border-left: 3px solid var(--primary);
  padding-left: 8px;
}

.achievements-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 16px;
}

.achievement-item-card {
  background-color: #ffffff;
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  padding: 16px;
  display: flex;
  gap: 16px;
  align-items: center;
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.02);
  position: relative;
}

.achievement-item-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.06);
}

.achievement-item-card.locked {
  opacity: 0.65;
  background-color: var(--surface-dim);
  border-color: var(--outline-variant);
}

.achievement-item-card.unlocked-milestone {
  border-left: 4px solid var(--primary);
}

.achievement-item-card.unlocked-badge {
  border-left: 4px solid #f59e0b;
  background: linear-gradient(135deg, #ffffff 0%, rgba(245, 158, 11, 0.02) 100%);
}

.achievement-icon-wrapper {
  width: 50px;
  height: 50px;
  border-radius: 50%;
  background-color: var(--surface-dim);
  display: flex;
  justify-content: center;
  align-items: center;
  position: relative;
  flex-shrink: 0;
  border: 1px solid var(--outline-variant);
}

.unlocked-milestone .achievement-icon-wrapper {
  background-color: rgba(0, 196, 159, 0.1);
  border-color: rgba(0, 196, 159, 0.2);
}

.unlocked-badge .achievement-icon-wrapper {
  background-color: rgba(245, 158, 11, 0.1);
  border-color: rgba(245, 158, 11, 0.2);
}

.achievement-icon {
  font-size: 1.5rem;
}

.lock-indicator {
  position: absolute;
  bottom: -4px;
  right: -4px;
  font-size: 0.8rem;
  background-color: #ffffff;
  border-radius: 50%;
  padding: 2px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  display: flex;
  align-items: center;
  justify-content: center;
}

.achievement-details {
  display: flex;
  flex-direction: column;
  flex: 1;
  text-align: left;
}

.achievement-name {
  font-family: var(--font-display);
  font-size: 0.95rem;
  font-weight: 700;
  color: var(--on-surface);
  margin-bottom: 2px;
}

.achievement-desc {
  font-size: 0.78rem;
  color: var(--on-surface-variant);
  margin-bottom: 8px;
  line-height: 1.3;
}

.achievement-progress-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.72rem;
  font-weight: 700;
}

.achievement-progress-text {
  color: var(--outline);
}

.achievement-status {
  padding: 2px 6px;
  border-radius: 8px;
  font-size: 0.68rem;
}

.status-unlocked {
  background-color: rgba(16, 185, 129, 0.12);
  color: #10b981;
}

.status-locked {
  background-color: var(--outline-variant);
  color: var(--outline);
}

/* Streaks Tab Custom Styles */
.streaks-panel {
  padding: 8px 4px;
}

.streak-card {
  background-color: #ffffff;
  border: 1px solid var(--outline-variant);
  border-radius: 24px;
  padding: 24px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.02);
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.streak-card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  text-align: left;
}

.streak-header-left {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.streak-title-text {
  font-family: var(--font-display);
  font-size: 1.25rem;
  font-weight: 800;
  color: var(--on-surface);
  margin: 0;
  display: flex;
  align-items: center;
  gap: 6px;
}

.streak-subtitle-text {
  font-size: 0.85rem;
  font-weight: 600;
  color: #16a34a; /* Green text matching screenshot */
  margin: 0;
}

.streak-header-right {
  flex-shrink: 0;
}

.streak-multiplier-badge {
  font-size: 1.05rem;
  font-weight: 700;
  color: #16a34a; /* Green matching screenshot */
}

.streak-days-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 8px;
  width: 100%;
}

.streak-day-col {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  flex: 1;
}

.streak-day-indicator {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: flex;
  justify-content: center;
  align-items: center;
  transition: all 0.2s ease;
}

.streak-day-indicator.day-played {
  background-color: #2e7d32;
  color: #ffffff;
  box-shadow: 0 4px 10px rgba(46, 125, 80, 0.3);
}

.streak-day-indicator.day-missed {
  background-color: #f1f5f9;
  color: #94a3b8;
}

.indicator-svg {
  width: 16px;
  height: 16px;
}

.streak-day-label {
  font-size: 0.78rem;
  font-weight: 700;
  color: var(--on-surface-variant);
}
/* Rules & Policies Modals styling */
.rules-fullscreen-panel {
  position: fixed;
  top: 0;
  right: 0;
  width: calc(100% - 280px);
  height: 100vh;
  background-color: var(--scaffold-bg, #f8fafc);
  z-index: 1250;
  display: flex;
  flex-direction: column;
  box-shadow: -8px 0 40px rgba(0, 0, 0, 0.08);
}

@media (max-width: 768px) {
  .rules-fullscreen-panel {
    width: 100%;
    left: 0;
  }
}

.rules-fullscreen-panel .settings-panel-body {
  max-width: 100% !important;
  width: 100% !important;
  margin: 0 !important;
  padding: 32px 40px !important;
  box-sizing: border-box !important;
}

@media (max-width: 768px) {
  .rules-fullscreen-panel .settings-panel-body {
    padding: 20px 24px !important;
  }
}

.rules-main-view, .rules-detail-view {
  display: flex;
  flex-direction: column;
  height: 100%;
  width: 100%;
}

.rules-intro-text {
  font-size: 0.95rem;
  color: var(--on-surface-variant, #64748b);
  margin-bottom: 24px;
  line-height: 1.5;
}

.rules-sports-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 16px;
  margin-top: 16px;
}

.rules-sport-card-option {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px 20px;
  background-color: var(--surface, #ffffff);
  border-radius: 16px;
  border: 1px solid var(--outline-variant, #e2e8f0);
  cursor: pointer;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.015);
  position: relative;
  overflow: hidden;
}

.rules-sport-card-option:hover {
  transform: translateY(-3px);
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.06);
  background-color: var(--surface-dim, #f1f5f9);
}

.rules-option-icon {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.5rem;
  flex-shrink: 0;
}

.rules-option-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
  flex-grow: 1;
}

.rules-option-title {
  font-size: 1.05rem;
  font-weight: 700;
  color: var(--on-surface, #0f172a);
}

.rules-option-subtitle {
  font-size: 0.8rem;
  color: var(--on-surface-variant, #64748b);
}

.rules-option-arrow {
  font-size: 1.1rem;
  transition: transform 0.2s ease;
}

.rules-sport-card-option:hover .rules-option-arrow {
  transform: translateX(4px);
}

/* Detailed rules view */
.rules-sport-info-card {
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 40px 24px;
  border-radius: 24px;
  margin-bottom: 24px;
  position: relative;
  overflow: hidden;
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.05);
  color: #ffffff;
  text-align: center;
}

.rules-sport-info-card::before {
  content: '';
  position: absolute;
  top: -60px;
  left: -60px;
  width: 200px;
  height: 200px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(255,255,255,0.15) 0%, rgba(255,255,255,0) 70%);
  pointer-events: none;
}

.rules-sport-info-card::after {
  content: '';
  position: absolute;
  bottom: -90px;
  right: -50px;
  width: 280px;
  height: 280px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(255,255,255,0.12) 0%, rgba(255,255,255,0) 70%);
  pointer-events: none;
}

.rules-sport-info-header-wrap {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  z-index: 2;
  max-width: 600px;
  width: 100%;
}

.rules-sport-avatar-circle {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background-color: rgba(255, 255, 255, 0.2);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  border: 1px solid rgba(255, 255, 255, 0.35);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 2.5rem;
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.1);
  animation: avatarBounce 3s ease-in-out infinite alternate;
}

.rules-sport-title-text {
  font-family: var(--font-display);
  font-size: 2rem;
  font-weight: 800;
  color: #ffffff;
  margin: 0;
  letter-spacing: -0.5px;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.rules-sport-desc-text {
  font-size: 0.92rem;
  color: rgba(255, 255, 255, 0.9);
  line-height: 1.5;
  margin: 0;
  font-weight: 500;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
}

@keyframes avatarBounce {
  0% {
    transform: translateY(0);
  }
  100% {
    transform: translateY(-4px);
  }
}

.rules-list-container {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 16px;
}

.rule-item-card {
  display: flex;
  gap: 16px;
  padding: 20px;
  background-color: var(--surface, #ffffff);
  border-radius: 16px;
  border: 1px solid var(--outline-variant, #e2e8f0);
  align-items: flex-start;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.01);
  transition: all 0.2s ease;
}

.rule-item-card:hover {
  transform: translateX(3px);
  border-color: var(--outline, #94a3b8);
}

.rule-item-number {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ffffff;
  font-weight: 800;
  font-size: 0.85rem;
  flex-shrink: 0;
}

.rule-item-content {
  display: flex;
  flex-direction: column;
  gap: 6px;
  flex: 1;
}

.rule-item-title {
  font-size: 1rem;
  font-weight: 700;
  color: var(--on-surface, #0f172a);
  margin: 0;
}

.rule-item-description {
  font-size: 0.88rem;
  color: var(--on-surface-variant, #64748b);
  line-height: 1.5;
  margin: 0;
}

/* Policies tab */
.policies-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 18px;
}

.policy-item-card {
  padding: 24px;
  background-color: var(--surface, #ffffff);
  border-radius: 16px;
  border: 1px solid var(--outline-variant, #e2e8f0);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.01);
  transition: all 0.25s ease;
}

.policy-item-card:hover {
  border-color: var(--primary, #6366f1);
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.02);
}

.policy-header-row {
  display: flex;
  align-items: center;
  margin-bottom: 10px;
}

.policy-item-title {
  font-size: 1.05rem;
  font-weight: 700;
  color: var(--primary, #6366f1);
  margin: 0;
}

.policy-item-description {
  font-size: 0.9rem;
  color: var(--on-surface-variant, #64748b);
  line-height: 1.6;
  margin: 0;
}
/* SVG Icon Wrapper styles */
.rules-option-icon-svg {
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.rules-sport-avatar-svg {
  width: 52px;
  height: 52px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.rules-header-icon-svg {
  width: 24px;
  height: 24px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}
</style>
