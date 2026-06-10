<script setup>
import { computed } from 'vue'
import { store } from '../store'

const props = defineProps({
  show: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['close'])

const notificationList = computed(() => {
  return store.state.notifications || []
})

const getIcon = (title) => {
  const t = String(title || '').toLowerCase()
  if (t.includes('reminder') || t.includes('schedule')) return '📅'
  if (t.includes('request') || t.includes('join')) return '👤'
  if (t.includes('found')) return '🎾'
  return '🔔'
}

const getIconClass = (title) => {
  const t = String(title || '').toLowerCase()
  if (t.includes('reminder')) return 'reminder'
  if (t.includes('request')) return 'request'
  if (t.includes('found')) return 'found'
  return 'default'
}

const handleMarkAllRead = async () => {
  await store.markAllNotificationsAsRead()
}

const handleMarkRead = async (item) => {
  if (!item.read) {
    await store.markNotificationAsRead(item.id)
  }
}
</script>

<template>
  <Transition name="drawer">
    <div v-if="show" class="modal-backdrop" @click="emit('close')">
      <div class="modal-sheet" @click.stop>
        <!-- Header -->
        <div class="modal-header">
          <button class="back-btn" @click="emit('close')" aria-label="Go back">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="back-arrow"><line x1="19" y1="12" x2="5" y2="12"></line><polyline points="12 19 5 12 12 5"></polyline></svg>
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

          <div v-else class="notifications-group">
            <div 
              v-for="item in notificationList" 
              :key="item.id"
              class="notification-card"
              :class="{ unread: !item.read }"
              @click="handleMarkRead(item)"
            >
              <div class="card-icon-wrap" :class="getIconClass(item.title)">
                {{ getIcon(item.title) }}
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
    align-items: center;
    justify-content: flex-end;
    padding-right: 24px;
  }

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

.card-icon-wrap {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  display: flex;
  justify-content: center;
  align-items: center;
  font-size: 1.1rem;
  flex-shrink: 0;
}

.card-icon-wrap.reminder {
  background-color: rgba(26, 35, 126, 0.08);
}
.card-icon-wrap.request {
  background-color: rgba(123, 97, 255, 0.08);
}
.card-icon-wrap.found {
  background-color: rgba(255, 145, 0, 0.08);
}
.card-icon-wrap.default {
  background-color: var(--surface-dim);
}

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
