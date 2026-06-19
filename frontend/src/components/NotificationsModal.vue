<script setup>
import { computed } from 'vue'
import { store } from '../store'
import { getSportIconUrl } from '../utils/sportImageHelper'

const props = defineProps({
  show: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['close', 'open-match-details', 'view-profile'])

const notificationList = computed(() => {
  return store.state.notifications || []
})

const groupedNotifications = computed(() => {
  const groups = {}
  notificationList.value.forEach(item => {
    let groupName = 'Earlier'
    const t = String(item.time || '').toLowerCase()
    if (t.includes('sec') || t.includes('min') || t.includes('hour') || t.includes('hr') || t.includes('today')) {
      groupName = 'Today'
    } else if (t.includes('yesterday')) {
      groupName = 'Yesterday'
    } else {
      groupName = 'Earlier'
    }
    if (!groups[groupName]) {
      groups[groupName] = []
    }
    groups[groupName].push(item)
  })
  
  // Sort groups
  const sorted = {}
  if (groups['Today'] && groups['Today'].length > 0) sorted['Today'] = groups['Today']
  if (groups['Yesterday'] && groups['Yesterday'].length > 0) sorted['Yesterday'] = groups['Yesterday']
  if (groups['Earlier'] && groups['Earlier'].length > 0) sorted['Earlier'] = groups['Earlier']
  return sorted
})

const getNotificationSport = (title, body, meta) => {
  if (meta && typeof meta === 'object') {
    if (meta.sport_type) return meta.sport_type
    if (meta.sport) return meta.sport
  }
  const text = `${title} ${body}`.toLowerCase()
  if (text.includes('football') || text.includes('soccer')) return 'Football'
  if (text.includes('cricket')) return 'Cricket'
  if (text.includes('badminton')) return 'Badminton'
  if (text.includes('basketball')) return 'Basketball'
  if (text.includes('tennis')) return 'Tennis'
  if (text.includes('padel')) return 'Padel'
  return ''
}

const getNotificationType = (title) => {
  const t = String(title || '').toLowerCase()
  if (t.includes('left')) return 'left'
  if (t.includes('joined') || t.includes('join')) return 'joined'
  if (t.includes('wave')) return 'wave'
  return 'default'
}

const getNotificationEmoji = (title, body, meta) => {
  const type = getNotificationType(title)
  if (type === 'left') return '🏃'
  if (type === 'wave') return '👋'
  
  const sport = getNotificationSport(title, body, meta)
  const s = String(sport || '').toLowerCase().trim()
  switch (s) {
    case 'football': return '⚽'
    case 'basketball': return '🏀'
    case 'tennis': return '🎾'
    case 'padel': return '🏓'
    case 'badminton': return '🏸'
    case 'cricket': return '🏏'
    default: return '🔔'
  }
}

const getNotificationIconKey = (title, body, meta) => {
  const type = getNotificationType(title)
  if (type === 'left') return 'left'
  if (type === 'wave') return 'wave'
  
  const sport = getNotificationSport(title, body, meta)
  if (sport) return sport
  return 'bell'
}

const getNotificationColorClass = (title, body, meta) => {
  const type = getNotificationType(title)
  if (type === 'left') return 'left'
  if (type === 'wave') return 'wave'
  if (type === 'joined') {
    const sport = getNotificationSport(title, body, meta)
    const s = String(sport || '').toLowerCase().trim()
    switch (s) {
      case 'football': return 'football'
      case 'basketball': return 'basketball'
      case 'tennis': return 'tennis'
      case 'padel': return 'padel'
      case 'badminton': return 'badminton'
      case 'cricket': return 'cricket'
      default: return 'default'
    }
  }
  return 'default'
}

const handleMarkAllRead = async () => {
  await store.markAllNotificationsAsRead()
}

const handleMarkRead = (item) => {
  console.log('--- NOTIFICATION CLICKED ---')
  console.log('Item ID:', item.id)
  console.log('Item Title:', item.title)
  console.log('Item Message/Body:', item.body || item.message)
  console.log('Item Meta Raw:', JSON.stringify(item.meta))

  if (!item.read) {
    store.markNotificationAsRead(item.id)
  }

  let meta = item.meta
  if (meta && typeof meta === 'string') {
    try {
      meta = JSON.parse(meta)
      console.log('Parsed Meta String to Object:', JSON.stringify(meta))
    } catch (e) {
      console.warn('Failed to parse notification meta:', e)
    }
  }

  if (meta && typeof meta === 'object') {
    const senderId = meta.sender_id || meta.follower_id
    const senderName = meta.sender_name || meta.follower_name
    console.log('Resolved senderId:', senderId, 'senderName:', senderName)

    if (senderId) {
      console.log('Emitting view-profile for user:', senderId, senderName)
      emit('view-profile', {
        id: Number(senderId),
        name: senderName || 'Player'
      })
      emit('close')
      return
    }

    const matchId = meta.match_id ? Number(meta.match_id) : null
    const matchTitle = meta.title || ''
    
    // Find matching match in store
    const match = store.state.matches.find(m => 
      (matchId && Number(m.id) === matchId) || 
      (matchTitle && m.title === matchTitle)
    )
    
    if (match) {
      emit('open-match-details', match)
      emit('close')
    }
  }
}
</script>

<template>
  <Transition name="drawer">
    <div v-if="show" class="modal-backdrop" @click="emit('close')">
      <div class="modal-sheet" @click.stop>
        <!-- Header -->
        <div class="modal-header">
          <button class="back-btn" @click="emit('close')" aria-label="Close">
            <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="back-icon"><line x1="19" y1="12" x2="5" y2="12"></line><polyline points="12 19 5 12 12 5"></polyline></svg>
          </button>
          <h2 class="modal-title">Notifications</h2>
          <button v-if="notificationList.length > 0" class="read-all-btn" @click="handleMarkAllRead">All Read</button>
        </div>

        <!-- List / Body -->
        <div class="modal-body scrollable-y">
          <div v-if="notificationList.length === 0" class="empty-state">
            <div class="empty-bell-wrap">
              <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#3f51b5" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" class="empty-bell-svg">
                <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
                <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
              </svg>
            </div>
            <h3 class="empty-title">No Notifications Yet</h3>
            <p class="empty-desc">You will get notified here when other players join or interact with your matches!</p>
          </div>

          <div v-else class="notifications-list-wrap">
            <div v-for="(items, groupName) in groupedNotifications" :key="groupName" class="notifications-group-section">
              <h4 class="group-header">{{ groupName }}</h4>
              <div class="notifications-group">
                <div 
                  v-for="item in items" 
                  :key="item.id"
                  class="notification-card"
                  :class="{ unread: !item.read }"
                  @click="handleMarkRead(item)"
                >
                  <div class="card-icon-wrap" :class="getNotificationColorClass(item.title, item.body, item.meta)">
                    <img :src="getSportIconUrl(getNotificationIconKey(item.title, item.body, item.meta))" class="notif-icon-img" alt="" />
                  </div>
                  
                  <div class="card-content">
                    <div class="card-header-row">
                      <span class="card-title">{{ item.title }}</span>
                      <span class="card-time">{{ item.time }}</span>
                    </div>
                    <p class="card-body-text">{{ item.body }}</p>
                  </div>

                  <div v-if="!item.read" class="unread-dot"></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.modal-backdrop {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background-color: rgba(15, 23, 42, 0.45);
  backdrop-filter: blur(4px);
  z-index: 9999;
  display: flex;
  align-items: flex-end;
  justify-content: center;
}

.modal-sheet {
  width: 100%;
  height: 80%;
  background-color: var(--scaffold-bg);
  border-top-left-radius: var(--radius-xl);
  border-top-right-radius: var(--radius-xl);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  box-shadow: 0 -8px 32px rgba(0, 0, 0, 0.08);
}

@media (min-width: 768px) {
  .modal-backdrop {
    align-items: stretch;
    justify-content: flex-end;
    padding-right: 0;
  }

  .modal-sheet {
    width: 100%;
    max-width: 480px;
    height: 100vh;
    max-height: 100vh;
    border-radius: 0;
    border-top-left-radius: var(--radius-xl);
    border-bottom-left-radius: var(--radius-xl);
    box-shadow: -8px 0 32px rgba(0, 0, 0, 0.15);
  }
}

.modal-header {
  position: relative;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 18px 20px;
  border-bottom: 1px solid var(--outline-variant);
  background-color: var(--surface);
  flex-shrink: 0;
  height: 64px;
}

.modal-title {
  position: absolute;
  left: 50%;
  transform: translateX(-50%);
  font-family: var(--font-display);
  font-size: 1.25rem;
  font-weight: 700;
  color: var(--on-surface);
  margin: 0;
  pointer-events: none;
}

.back-btn {
  background: none;
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--on-surface);
  cursor: pointer;
  padding: 4px;
  border-radius: 50%;
  transition: background-color 0.2s;
  z-index: 2;
}

.back-btn:hover {
  background-color: var(--scaffold-bg);
}

.read-all-btn {
  background: none;
  border: none;
  color: var(--primary);
  font-weight: 700;
  font-size: 0.85rem;
  cursor: pointer;
  padding: 6px 12px;
  border-radius: 12px;
  transition: background-color 0.2s;
  z-index: 2;
}

.read-all-btn:hover {
  background-color: rgba(46, 125, 50, 0.08);
}

.modal-body {
  padding: 24px 20px;
  flex: 1;
  overflow-y: auto;
}

/* Empty State Styling (matching screenshot) */
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  height: 80%;
  padding: 40px 20px;
}

.empty-bell-wrap {
  width: 90px;
  height: 90px;
  background-color: #f1f1fe; /* Soft violet/indigo tint */
  border-radius: 50%;
  display: flex;
  justify-content: center;
  align-items: center;
  margin-bottom: 24px;
}

.empty-bell-svg {
  display: flex;
  align-items: center;
}

.empty-title {
  font-family: var(--font-display);
  font-size: 1.35rem;
  font-weight: 700;
  color: #0f172a;
  margin: 0 0 12px;
}

.empty-desc {
  font-size: 0.92rem;
  color: #64748b;
  line-height: 1.5;
  max-width: 280px;
  margin: 0;
}

/* Notifications List styling */
.notifications-group {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.notification-card {
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  padding: 16px;
  display: flex;
  gap: 14px;
  position: relative;
  cursor: pointer;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
  box-shadow: var(--shadow-sm);
}

.notification-card:hover {
  transform: translateY(-1px);
  box-shadow: var(--shadow-md);
}

.notification-card.unread {
  background-color: rgba(46, 125, 50, 0.02); /* slight primary tint */
  border-color: rgba(46, 125, 50, 0.1);
}

.group-header {
  font-size: 0.8rem;
  font-weight: 700;
  color: var(--on-surface-variant);
  margin: 18px 0 12px;
  text-transform: capitalize;
  letter-spacing: 0.5px;
}

.card-icon-wrap {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  display: flex;
  justify-content: center;
  align-items: center;
  font-size: 1.1rem;
  flex-shrink: 0;
}

.notif-icon-img {
  width: 22px;
  height: 22px;
  object-fit: contain;
}

.card-icon-wrap.football { background-color: rgba(46, 125, 50, 0.08); }
.card-icon-wrap.basketball { background-color: rgba(255, 145, 0, 0.08); }
.card-icon-wrap.tennis { background-color: rgba(205, 220, 57, 0.08); }
.card-icon-wrap.padel { background-color: rgba(0, 150, 136, 0.08); }
.card-icon-wrap.badminton { background-color: rgba(0, 188, 212, 0.08); }
.card-icon-wrap.cricket { background-color: rgba(63, 81, 181, 0.08); }
.card-icon-wrap.left { background-color: rgba(255, 82, 82, 0.08); }
.card-icon-wrap.wave { background-color: rgba(63, 81, 181, 0.08); }
.card-icon-wrap.default { background-color: var(--surface-dim); }

.card-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.card-header-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-title {
  font-size: 0.88rem;
  font-weight: 700;
  color: var(--on-surface);
}

.card-time {
  font-size: 0.72rem;
  color: var(--outline);
}

.card-body-text {
  font-size: 0.78rem;
  color: var(--on-surface-variant);
  line-height: 1.4;
}

.unread-dot {
  position: absolute;
  right: 16px;
  bottom: 16px;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: var(--primary);
}

/* Drawer Transition (Backdrop fade + Responsive Slide-in) */
.drawer-enter-active,
.drawer-leave-active {
  transition: opacity 0.3s ease;
}

.drawer-enter-from,
.drawer-leave-to {
  opacity: 0;
}

/* Mobile (default): Slide up/down */
.drawer-enter-active .modal-sheet {
  animation: slideUp 0.3s ease-out forwards;
}

.drawer-leave-active .modal-sheet {
  animation: slideDown 0.25s ease-in forwards;
}

/* Desktop (min-width: 768px): Slide left/right */
@media (min-width: 768px) {
  .drawer-enter-active .modal-sheet {
    animation: slideLeft 0.35s cubic-bezier(0.16, 1, 0.3, 1) forwards;
  }

  .drawer-leave-active .modal-sheet {
    animation: slideRight 0.25s ease-in forwards;
  }
}

@keyframes slideUp {
  from {
    transform: translateY(100%);
  }
  to {
    transform: translateY(0);
  }
}

@keyframes slideDown {
  from {
    transform: translateY(0);
  }
  to {
    transform: translateY(100%);
  }
}

@keyframes slideLeft {
  from {
    transform: translateX(100%);
  }
  to {
    transform: translateX(0);
  }
}

@keyframes slideRight {
  from {
    transform: translateX(0);
  }
  to {
    transform: translateX(100%);
  }
}
</style>
