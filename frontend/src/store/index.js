import { reactive, computed } from 'vue'

const state = reactive({
  currentUser: JSON.parse(sessionStorage.getItem('sportigo_user')) || null,
  themePreference: localStorage.getItem('sportigo_theme_pref') || 'system',
  language: localStorage.getItem('sportigo_language') || 'en',
  matches: [],
  players: [],
  activities: [],
  myMatchActivities: [],   // join/leave events on matches the current user created
  notifications: [],
  chats: {},
  isLoading: false
})

// Auto-theme to elegantLavender on load if female
if (state.currentUser && state.currentUser.gender === 'female') {
  state.themePreference = 'elegantLavender'
}

// Dynamic theme checks matching ThemeManager class logic
const isWomenMode = computed(() => {
  if (state.currentUser?.gender === 'male') return false
  return state.themePreference === 'elegantLavender'
})

// API_URL: use /api (proxied by Vite) so no CORS or SSL issues
const API_URL = '/api'

// Helper to get headers with Bearer token
const getAuthHeaders = () => {
  const token = sessionStorage.getItem('sportigo_token')
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
      sessionStorage.removeItem('sportigo_user')
      sessionStorage.removeItem('sportigo_token')
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
  console.log('store.init() called stack:\n', new Error().stack);
  const token = sessionStorage.getItem('sportigo_token')
  if (!token) return // Not logged in

  state.isLoading = true;
  try {
    const headers = getAuthHeaders()

    // Fetch user details, matches, and joined matches (critical for homepage) in parallel
    const [userData, matchesData, mineMatchesData] = await Promise.all([
      safeFetch(`${API_URL}/user`, { headers }),
      safeFetch(`${API_URL}/matches`, { headers }),
      safeFetch(`${API_URL}/matches/mine`, { headers })
    ])

    if (userData) {
      state.currentUser = userData
      sessionStorage.setItem('sportigo_user', JSON.stringify(userData))
      if (userData.gender === 'female') {
        setThemePreference('elegantLavender')
      }
    }
    if (matchesData) {
      const allMatches = Array.isArray(matchesData) ? matchesData : (matchesData.data || [])
      const mineMatches = Array.isArray(mineMatchesData) ? mineMatchesData : (mineMatchesData || [])
      console.log('store.init() - allMatches count:', allMatches.length, 'mineMatches count:', mineMatches.length)
      
      const combined = [...allMatches]
      mineMatches.forEach(m => {
        if (!combined.some(existing => existing.id === m.id)) {
          combined.push(m)
        }
      })

      // Preserve newly created matches or future matches that might have been loaded
      // but are not returned on the first page of paginated results, or were affected by race conditions.
      const currentUserId = state.currentUser?.id
      const now = new Date()
      state.matches.forEach(m => {
        if (m && m.id && !combined.some(existing => existing.id === m.id)) {
          const matchTime = new Date((m.dateTime || m.date_time || m.date || '').replace(' ', 'T'))
          const isUpcoming = !isNaN(matchTime.getTime()) && matchTime >= now
          const isMine = currentUserId && (Number(m.creatorId || m.creator_id || m.user_id) === Number(currentUserId))
          if (isUpcoming || isMine) {
            combined.push(m)
          }
        }
      })

      state.matches = combined
      console.log('store.init() - state.matches updated count:', state.matches.length)
    }

    // Unblock the main UI / skeletons immediately once critical dashboard data is loaded
    state.isLoading = false

    // Fetch non-critical data (activities, my-match activities, notifications) concurrently in the background
    Promise.all([
      safeFetch(`${API_URL}/activities`, { headers }),
      safeFetch(`${API_URL}/activities/my-matches`, { headers }),
      safeFetch(`${API_URL}/notifications`, { headers })
    ]).then(([activitiesData, myMatchActivitiesData, notificationsData]) => {
      if (activitiesData) {
        state.activities = Array.isArray(activitiesData)
          ? activitiesData
          : (Array.isArray(activitiesData.data) ? activitiesData.data : [])
      }
      if (myMatchActivitiesData) {
        const raw = Array.isArray(myMatchActivitiesData)
          ? myMatchActivitiesData
          : (Array.isArray(myMatchActivitiesData.data) ? myMatchActivitiesData.data : [])
        state.myMatchActivities = raw.map(act => ({
          ...act,
          sportType: act.sportType || act.sport_type || act.meta?.sport_type || 'Sports',
          matchTitle: act.matchTitle || act.match_title || act.meta?.title || '',
          time: formatRelativeTime(act.created_at)
        }))
      }
      if (notificationsData && Array.isArray(notificationsData.data)) {
        state.notifications = notificationsData.data.map(n => {
          let meta = n.meta
          if (meta && typeof meta === 'string') {
            try {
              meta = JSON.parse(meta)
            } catch (e) {
              console.warn('Store: Failed to parse notification meta:', e)
            }
          }
          return {
            ...n,
            meta,
            read: Boolean(n.is_read),
            body: n.message,
            time: formatRelativeTime(n.created_at)
          }
        })
      }
    }).catch(e => {
      console.warn('Background store fetch failed:', e.message)
    })

  } catch (e) {
    console.error('Store init error:', e)
    state.isLoading = false
  }
}

// Auto-run init on page load if user is already logged in
init()

const login = async (username, password) => {
  const res = await fetch(`${API_URL}/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
    body: JSON.stringify({ username, password })
  })

  const data = await res.json().catch(() => null)
  if (res.ok && data && data.access_token) {
    state.currentUser = data.user
    sessionStorage.setItem('sportigo_user', JSON.stringify(data.user))
    sessionStorage.setItem('sportigo_token', data.access_token)
    if (data.user && data.user.gender === 'female') {
      setThemePreference('elegantLavender')
    }
    await init()
    return true
  }

  throw new Error(data?.message || 'Invalid login details')
}

const loginWithGoogle = async (credential) => {
  const res = await fetch(`${API_URL}/auth/google`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
    body: JSON.stringify({ id_token: credential })
  })

  const data = await res.json().catch(() => null)
  if (res.ok && data && data.access_token) {
    state.currentUser = data.user
    sessionStorage.setItem('sportigo_user', JSON.stringify(data.user))
    sessionStorage.setItem('sportigo_token', data.access_token)
    if (data.user && data.user.gender === 'female') {
      setThemePreference('elegantLavender')
    }
    await init()
    return true
  }

  throw new Error(data?.message || 'Google login failed')
}

const uploadProfilePhoto = async (file) => {
  const formData = new FormData()
  formData.append('profile_photo', file)

  const res = await fetch(`${API_URL}/profile/photo`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${sessionStorage.getItem('sportigo_token')}`,
      'Accept': 'application/json'
    },
    body: formData
  })

  const data = await res.json().catch(() => null)
  if (res.ok && data && data.user) {
    state.currentUser = data.user
    sessionStorage.setItem('sportigo_user', JSON.stringify(data.user))
    return data
  }
  throw new Error(data?.message || 'Failed to upload profile photo')
}

const register = async (name, username, password, gender) => {
  const res = await fetch(`${API_URL}/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
    body: JSON.stringify({ name, username, password, gender })
  })

  const data = await res.json().catch(() => null)
  if (res.ok) {
    return true
  }

  throw new Error(data?.message || 'Registration failed')
}

const logout = async () => {
  const headers = getAuthHeaders()
  
  state.currentUser = null
  state.matches = []
  state.activities = []
  state.myMatchActivities = []
  sessionStorage.removeItem('sportigo_user')
  sessionStorage.removeItem('sportigo_token')

  // Fire-and-forget: perform backend logout in the background without awaiting
  fetch(`${API_URL}/logout`, {
    method: 'POST',
    headers
  }).catch(e => {
    console.warn('Backend logout call failed:', e.message)
  })
}

const updateProfile = async (name, gender, avatar, bio, primarySport, skillTier, email) => {
  if (!state.currentUser) return
  const body = { name, gender }
  if (avatar) body.avatar = avatar
  if (bio !== undefined) body.bio = bio
  if (primarySport !== undefined) body.primary_sport = primarySport
  if (skillTier !== undefined) body.skill_tier = skillTier
  if (email !== undefined) {
    body.email = (typeof email === 'string' && email.trim() === '') ? null : email
  }

  const res = await fetch(`${API_URL}/user`, {
    method: 'PUT',
    headers: getAuthHeaders(),
    body: JSON.stringify(body)
  })

  if (!res.ok) {
    if (res.status === 401) {
      console.warn(`Unauthorized request (401) to updateProfile. Clearing invalid session.`)
      state.currentUser = null
      state.matches = []
      state.activities = []
      sessionStorage.removeItem('sportigo_user')
      sessionStorage.removeItem('sportigo_token')
      throw new Error('Session expired. Please log in again.')
    }
    const errData = await res.json().catch(() => ({}))
    // Laravel 422 validation errors: prefer per-field messages (e.g. email uniqueness)
    // over the generic summary message so the UI can show a precise error.
    if (res.status === 422 && errData.errors) {
      const fieldErrors = Object.values(errData.errors).flat()
      if (fieldErrors.length > 0) {
        throw new Error(fieldErrors[0])
      }
    }
    throw new Error(errData.message || 'Failed to update profile details')
  }

  const data = await res.json()
  state.currentUser = data
  sessionStorage.setItem('sportigo_user', JSON.stringify(data))
  if (data && data.gender === 'female') {
    setThemePreference('elegantLavender')
  }
  await init()
  return true
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
  if (acts) {
    state.activities = Array.isArray(acts)
      ? acts
      : (Array.isArray(acts.data) ? acts.data : [])
  }
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
  // Refresh activities
  const acts = await safeFetch(`${API_URL}/activities`, { headers: getAuthHeaders() })
  if (acts) {
    state.activities = Array.isArray(acts)
      ? acts
      : (Array.isArray(acts.data) ? acts.data : [])
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

const createMatch = async (sportType, title, dateTime, location, maxSlots, skillLevel, price, womenOnly, latitude = null, longitude = null) => {
  if (!state.currentUser) return null
  const data = await safeFetch(`${API_URL}/matches`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({
      title,
      sport_type: sportType,
      category: sportType,
      location,
      date_time: dateTime.replace('T', ' ').substring(0, 16),
      date: dateTime.replace('T', ' ').substring(0, 16),
      price: String(price || 0),
      women_only: Boolean(womenOnly),
      is_women_only: Boolean(womenOnly),
      available_slots: Number(maxSlots),
      max_slots: Number(maxSlots),
      skill_level: skillLevel,
      latitude: latitude !== null ? Number(latitude) : null,
      longitude: longitude !== null ? Number(longitude) : null
    })
  })
  if (data && data.id) {
    state.matches.unshift(data)
    safeFetch(`${API_URL}/activities`, { headers: getAuthHeaders() })
      .then(acts => {
        if (acts) {
          state.activities = Array.isArray(acts)
            ? acts
            : (Array.isArray(acts.data) ? acts.data : [])
        }
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

const fetchPlayers = async (search = '') => {
  const headers = getAuthHeaders()
  const url = search ? `${API_URL}/players?search=${encodeURIComponent(search)}` : `${API_URL}/players`
  const data = await safeFetch(url, { headers })
  if (data && data.success) {
    state.players = data.data || []
    return state.players
  }
  return []
}

const fetchMatches = async (filters = {}) => {
  const headers = getAuthHeaders()
  const params = new URLSearchParams()
  if (filters.sportType) params.append('sport_type', filters.sportType)
  if (filters.skillLevel) params.append('skill_level', filters.skillLevel)
  if (filters.search) params.append('search', filters.search)
  if (filters.womenOnly !== undefined) params.append('women_only', filters.womenOnly ? '1' : '0')
  if (filters.cursor) params.append('cursor', filters.cursor)

  const url = `${API_URL}/matches?${params.toString()}`
  const data = await safeFetch(url, { headers })
  if (data && data.data) {
    if (filters.cursor) {
      const existingIds = new Set(state.matches.map(m => m.id))
      data.data.forEach(m => {
        if (!existingIds.has(m.id)) {
          state.matches.push(m)
        }
      })
    } else {
      state.matches = data.data
    }
    return {
      data: data.data,
      next_cursor: data.next_cursor,
      has_more: data.has_more
    }
  }
  return { data: [], next_cursor: null, has_more: false }
}

const followPlayer = async (playerId) => {
  if (!state.currentUser) return null
  const data = await safeFetch(`${API_URL}/users/${playerId}/follow`, {
    method: 'POST',
    headers: getAuthHeaders()
  })
  if (data && data.success) {
    const idx = state.players.findIndex(p => p.id === playerId)
    if (idx !== -1) {
      state.players[idx].isFollowed = true
      state.players[idx].followersCount = data.followersCount
    }
    if (state.currentUser && state.currentUser.followingCount !== undefined) {
      state.currentUser.followingCount++
    }
    return data
  }
  return null
}

const unfollowPlayer = async (playerId) => {
  if (!state.currentUser) return null
  const data = await safeFetch(`${API_URL}/users/${playerId}/unfollow`, {
    method: 'POST',
    headers: getAuthHeaders()
  })
  if (data && data.success) {
    const idx = state.players.findIndex(p => p.id === playerId)
    if (idx !== -1) {
      state.players[idx].isFollowed = false
      state.players[idx].followersCount = data.followersCount
    }
    if (state.currentUser && state.currentUser.followingCount !== undefined) {
      state.currentUser.followingCount = Math.max(0, state.currentUser.followingCount - 1)
    }
    return data
  }
  return null
}

const wavePlayer = async (playerId) => {
  if (!state.currentUser) return null
  const data = await safeFetch(`${API_URL}/users/${playerId}/wave`, {
    method: 'POST',
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
  uploadProfilePhoto,
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
  getMatchRatings,
  fetchPlayers,
  fetchMatches,
  followPlayer,
  unfollowPlayer,
  wavePlayer
}

if (typeof window !== 'undefined') {
  window.store = store
}
