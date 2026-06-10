import { reactive, computed } from 'vue'

const state = reactive({
  currentUser: JSON.parse(localStorage.getItem('sportigo_user')) || null,
  themePreference: localStorage.getItem('sportigo_theme_pref') || 'system',
  language: localStorage.getItem('sportigo_language') || 'en',
  matches: [],
  activities: [],
  notifications: [],
  chats: {},
  isLoading: false
})

// Dynamic theme checks matching ThemeManager class logic
const isWomenMode = computed(() => {
  if (state.themePreference === 'elegantLavender') return true
  if (state.themePreference === 'activeSteelBlue') return false
  return state.currentUser?.gender === 'female'
})

// API_URL: use /api (proxied by Vite) so no CORS or SSL issues
const API_URL = '/api'

// Helper to get headers with Bearer token
const getAuthHeaders = () => {
  const token = localStorage.getItem('sportigo_token')
  return token
    ? { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json', 'Accept': 'application/json' }
    : { 'Content-Type': 'application/json', 'Accept': 'application/json' }
}

const safeFetch = async (url, options = {}) => {
  try {
    const res = await fetch(url, options)
    if (res.status === 401) {
      console.warn(`Unauthorized request (401) to ${url}. Clearing invalid session.`)
      state.currentUser = null
      state.matches = []
      state.activities = []
      localStorage.removeItem('sportigo_user')
      localStorage.removeItem('sportigo_token')
      return null
    }
    if (!res.ok) return null
    return await res.json()
  } catch (e) {
    console.warn(`Fetch failed: ${url}`, e.message)
    return null
  }
}

// Helper to format relative time
const formatRelativeTime = (dateStr) => {
  if (!dateStr) return ''
  const date = new Date(dateStr)
  const now = new Date()
  const diffMs = now - date
  const diffMins = Math.floor(diffMs / 60000)
  if (diffMins < 1) return 'Just now'
  if (diffMins < 60) return `${diffMins}m ago`
  const diffHours = Math.floor(diffMins / 60)
  if (diffHours < 24) return `${diffHours}h ago`
  const diffDays = Math.floor(diffHours / 24)
  if (diffDays === 1) return 'Yesterday'
  return `${diffDays}d ago`
}

// Initialize state from database
const init = async () => {
  const token = localStorage.getItem('sportigo_token')
  if (!token) return // Not logged in

  state.isLoading = true
  try {
    const headers = getAuthHeaders()

    // Fetch user details, matches, activities, and notifications in parallel
    const [userData, matchesData, mineMatchesData, activitiesData, notificationsData] = await Promise.all([
      safeFetch(`${API_URL}/user`, { headers }),
      safeFetch(`${API_URL}/matches`, { headers }),
      safeFetch(`${API_URL}/matches/mine`, { headers }),
      safeFetch(`${API_URL}/activities`, { headers }),
      safeFetch(`${API_URL}/notifications`, { headers })
    ])

    if (userData) {
      state.currentUser = userData
      localStorage.setItem('sportigo_user', JSON.stringify(userData))
    }
    if (matchesData) {
      const allMatches = Array.isArray(matchesData) ? matchesData : (matchesData.data || [])
      const mineMatches = Array.isArray(mineMatchesData) ? mineMatchesData : (mineMatchesData || [])
      
      const combined = [...allMatches]
      mineMatches.forEach(m => {
        if (!combined.some(existing => existing.id === m.id)) {
          combined.push(m)
        }
      })
      state.matches = combined
    }
    if (Array.isArray(activitiesData)) {
      state.activities = activitiesData
    }
    if (notificationsData && Array.isArray(notificationsData.data)) {
      state.notifications = notificationsData.data.map(n => ({
        ...n,
        read: Boolean(n.is_read),
        body: n.message,
        time: formatRelativeTime(n.created_at)
      }))
    }
  } catch (e) {
    console.error('Store init error:', e)
  } finally {
    state.isLoading = false
  }
}

// Auto-run init on page load if user is already logged in
init()

const login = async (username, password) => {
  const data = await safeFetch(`${API_URL}/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
    body: JSON.stringify({ username, password })
  })

  if (data && data.access_token) {
    state.currentUser = data.user
    localStorage.setItem('sportigo_user', JSON.stringify(data.user))
    localStorage.setItem('sportigo_token', data.access_token)
    await init()
    return true
  }

  throw new Error(data?.message || 'Invalid login details')
}

const loginWithGoogle = async (credential) => {
  const data = await safeFetch(`${API_URL}/auth/google`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
    body: JSON.stringify({ credential })
  })

  if (data && data.access_token) {
    state.currentUser = data.user
    localStorage.setItem('sportigo_user', JSON.stringify(data.user))
    localStorage.setItem('sportigo_token', data.access_token)
    await init()
    return true
  }

  throw new Error(data?.message || 'Google login failed')
}

const register = async (name, username, password, gender) => {
  const data = await safeFetch(`${API_URL}/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
    body: JSON.stringify({ name, username, password, gender })
  })

  if (data && data.access_token) {
    state.currentUser = data.user
    localStorage.setItem('sportigo_user', JSON.stringify(data.user))
    localStorage.setItem('sportigo_token', data.access_token)
    await init()
    return true
  }

  throw new Error(data?.message || 'Registration failed')
}

const logout = async () => {
  try {
    await fetch(`${API_URL}/logout`, {
      method: 'POST',
      headers: getAuthHeaders()
    })
  } catch (e) { /* ignore */ }
  state.currentUser = null
  state.matches = []
  state.activities = []
  localStorage.removeItem('sportigo_user')
  localStorage.removeItem('sportigo_token')
}

const updateProfile = async (name, gender, avatar, bio, primarySport, skillTier) => {
  if (!state.currentUser) return
  const body = { name, gender }
  if (avatar) body.avatar = avatar
  if (bio !== undefined) body.bio = bio
  if (primarySport !== undefined) body.primary_sport = primarySport
  if (skillTier !== undefined) body.skill_tier = skillTier

  const data = await safeFetch(`${API_URL}/user`, {
    method: 'PUT',
    headers: getAuthHeaders(),
    body: JSON.stringify(body)
  })
  if (data) {
    state.currentUser = data
    localStorage.setItem('sportigo_user', JSON.stringify(data))
    await init()
  }
}

const setThemePreference = (pref) => {
  state.themePreference = pref
  localStorage.setItem('sportigo_theme_pref', pref)
}

const setLanguage = (lang) => {
  state.language = lang
  localStorage.setItem('sportigo_language', lang)
}

const joinMatch = async (matchId) => {
  if (!state.currentUser) return
  const data = await safeFetch(`${API_URL}/matches/${matchId}/join`, {
    method: 'POST',
    headers: getAuthHeaders()
  })
  if (data && data.match) {
    const idx = state.matches.findIndex(m => m.id === matchId)
    if (idx !== -1) state.matches[idx] = data.match
    else state.matches.push(data.match)
  }
  // Refresh activities
  const acts = await safeFetch(`${API_URL}/activities`, { headers: getAuthHeaders() })
  if (Array.isArray(acts)) state.activities = acts
}

const leaveMatch = async (matchId) => {
  if (!state.currentUser) return
  const data = await safeFetch(`${API_URL}/matches/${matchId}/leave`, {
    method: 'POST',
    headers: getAuthHeaders()
  })
  if (data && data.match) {
    const idx = state.matches.findIndex(m => m.id === matchId)
    if (idx !== -1) state.matches[idx] = data.match
  }
}

const recordResults = async (matchId, results) => {
  if (!state.currentUser) return null
  const data = await safeFetch(`${API_URL}/matches/${matchId}/result`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({ results })
  })
  if (data && data.match) {
    const idx = state.matches.findIndex(m => m.id === matchId)
    if (idx !== -1) state.matches[idx] = data.match
    return data
  }
  return null
}

const createMatch = async (sportType, title, dateTime, location, maxSlots, skillLevel, price, womenOnly) => {
  if (!state.currentUser) return null
  const data = await safeFetch(`${API_URL}/matches`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({
      title,
      category: sportType,
      location,
      date: dateTime.replace('T', ' ').substring(0, 16),
      price: String(price || 0),
      is_women_only: Boolean(womenOnly),
      max_slots: Number(maxSlots),
      skill_level: skillLevel
    })
  })
  if (data && data.id) {
    state.matches.unshift(data)
    safeFetch(`${API_URL}/activities`, { headers: getAuthHeaders() })
      .then(acts => {
        if (Array.isArray(acts)) state.activities = acts
      })
      .catch(e => console.warn("Failed to fetch activities asynchronously:", e));
    return data
  }
  return null
}

const toggleLikeActivity = async (actId) => {
  // No backend endpoint yet - handle locally
  const idx = state.activities.findIndex(a => a.id === actId)
  if (idx !== -1) {
    state.activities[idx] = {
      ...state.activities[idx],
      likedByMe: !state.activities[idx].likedByMe,
      likes: state.activities[idx].likedByMe
        ? state.activities[idx].likes - 1
        : state.activities[idx].likes + 1
    }
  }
}

const addCommentToActivity = async (actId) => {
  // No backend endpoint yet
}

const loadChats = async (matchId) => {
  const data = await safeFetch(`${API_URL}/chats/${matchId}`, {
    headers: getAuthHeaders()
  })
  if (Array.isArray(data)) state.chats[matchId] = data
}

const sendMessage = async (matchId, text) => {
  if (!state.currentUser) return
  const now = new Date()
  let hours = now.getHours()
  const minutes = String(now.getMinutes()).padStart(2, '0')
  const ampm = hours >= 12 ? 'PM' : 'AM'
  hours = hours % 12 || 12
  const timeStr = `${hours}:${minutes} ${ampm}`

  const data = await safeFetch(`${API_URL}/chats/${matchId}`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({
      senderId: state.currentUser.id,
      senderName: state.currentUser.name,
      text,
      time: timeStr
    })
  })
  if (data) {
    if (!state.chats[matchId]) state.chats[matchId] = []
    state.chats[matchId].push(data)
  }
}

const markNotificationAsRead = async (notificationId) => {
  if (!state.currentUser) return
  const idx = state.notifications.findIndex(n => n.id === notificationId)
  if (idx !== -1) {
    state.notifications[idx].read = true
  }
  await safeFetch(`${API_URL}/notifications/${notificationId}/read`, {
    method: 'PUT',
    headers: getAuthHeaders()
  })
}

const markAllNotificationsAsRead = async () => {
  if (!state.currentUser) return
  state.notifications.forEach(n => n.read = true)
  await safeFetch(`${API_URL}/notifications/read-all`, {
    method: 'PUT',
    headers: getAuthHeaders()
  })
}

const submitPlayerRatings = async (matchId, ratings) => {
  if (!state.currentUser) return null
  const data = await safeFetch(`${API_URL}/matches/${matchId}/ratings`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({ ratings })
  })
  return data
}

const getMatchRatings = async (matchId) => {
  const data = await safeFetch(`${API_URL}/matches/${matchId}/ratings`, {
    headers: getAuthHeaders()
  })
  return data
}

export const store = {
  state,
  isWomenMode,
  init,
  login,
  loginWithGoogle,
  register,
  logout,
  updateProfile,
  setThemePreference,
  setLanguage,
  joinMatch,
  leaveMatch,
  recordResults,
  createMatch,
  toggleLikeActivity,
  addCommentToActivity,
  loadChats,
  sendMessage,
  markNotificationAsRead,
  markAllNotificationsAsRead,
  submitPlayerRatings,
  getMatchRatings
}
