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
  <div v-if="show" class="modal-backdrop" @click="emit('close')">
    <div class="modal-sheet animate-slide-up" @click.stop>
      <!-- Header -->
      <div class="modal-header">
        <button class="back-btn" @click="emit('close')">✕</button>
        <h2 class="modal-title">Notifications</h2>
        <button class="read-all-btn" @click="handleMarkAllRead">All Read</button>
      </div>

      <!-- List -->
      <div class="modal-body scrollable-y">
        <div v-if="notificationList.length === 0" class="empty-state">
          <div class="empty-icon">🔔</div>
          <span class="empty-title">All caught up!</span>
          <span class="empty-desc">No new notifications at this time.</span>
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
</template>

<style scoped>
.modal-backdrop {
  position: absolute;
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
  height: 80%;
  background-color: var(--scaffold-bg);
  border-top-left-radius: var(--radius-xl);
  border-top-right-radius: var(--radius-xl);
  display: flex;
  flex-direction: column;
  overflow: hidden;
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
  padding: 16px 20px;
  border-bottom: 1px solid var(--outline-variant);
  display: flex;
  justify-content: space-between;
  align-items: center;
  background-color: var(--surface);
}

.modal-title {
  font-size: 1.15rem;
  font-weight: 700;
  color: var(--on-surface);
}

.back-btn {
  background: none;
  border: none;
  font-size: 1.1rem;
  color: var(--on-surface);
  cursor: pointer;
}

.read-all-btn {
  background: none;
  border: none;
  color: var(--primary);
  font-weight: 700;
  font-size: 0.82rem;
  cursor: pointer;
}

.modal-body {
  padding: 16px;
  flex: 1;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  padding-top: 80px;
}

.empty-icon {
  font-size: 3.5rem;
  margin-bottom: 16px;
  opacity: 0.6;
}

.empty-title {
  font-size: 1.1rem;
  font-weight: 700;
  margin-bottom: 4px;
}

.empty-desc {
  font-size: 0.85rem;
  color: var(--on-surface-variant);
}

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
  transition: transform 0.2s ease;
}

.notification-card:hover {
  transform: translateY(-1px);
}

.notification-card.unread {
  background-color: rgba(26, 35, 126, 0.02);
  border-color: rgba(26, 35, 126, 0.1);
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

/* Color classes for card icon */
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
</style>
