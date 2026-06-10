<script setup>
const emit = defineEmits(['chat-tap'])

const activeUsers = [
  { name: 'Your Story', isStory: true, icon: '➕' },
  { name: 'Mike', isStory: false, icon: '👤', online: true },
  { name: 'Sarah', isStory: false, icon: '👩', online: true },
  { name: 'Alex', isStory: false, icon: '👦', online: true },
  { name: 'Coach', isStory: false, icon: '👨', online: true }
]

const recentChats = [
  {
    name: 'Downtown 3v3 Pickup',
    message: 'Mike: Yeah, I\'ll bring the extra ball. See you guys at 5.',
    time: '12:45 PM',
    unreadCount: 3,
    isGroup: true
  },
  {
    name: 'Sarah Jenkins',
    message: 'Great match today! Let\'s hit the courts again next week.',
    time: 'Yesterday',
    unreadCount: 0,
    isGroup: false
  },
  {
    name: 'Coach Reynolds',
    message: 'Don\'t forget to review the drills I sent over.',
    time: 'Tue',
    unreadCount: 0,
    isGroup: false
  },
  {
    name: 'Weekend Tennis League',
    message: 'Court 4 is booked for Saturday morning.',
    time: 'Mon',
    unreadCount: 0,
    isGroup: true
  }
]

const handleChatClick = (chat) => {
  emit('chat-tap', `Opening chat with ${chat.name}... 💬`)
}

const handleStoryClick = (user) => {
  emit('chat-tap', `Viewing ${user.name}'s story... 📸`)
}
</script>

<template>
  <div class="chat-list-container scrollable-y animate-fade-in">
    <!-- Active Now section -->
    <div class="section-header">
      <h3 class="section-title">Active Now</h3>
    </div>
    
    <div class="active-slider">
      <div 
        v-for="(user, i) in activeUsers" 
        :key="i" 
        class="active-user-card"
        @click="handleStoryClick(user)"
      >
        <div class="avatar-wrap" :class="{ story: user.isStory }">
          <span class="avatar-emoji">{{ user.icon }}</span>
          <div v-if="user.online" class="online-dot"></div>
        </div>
        <span class="user-name">{{ user.name }}</span>
      </div>
    </div>

    <!-- Recent section -->
    <div class="section-header recent-header">
      <h3 class="section-title">Recent</h3>
    </div>

    <div class="chats-list">
      <div 
        v-for="(chat, i) in recentChats" 
        :key="i"
        class="chat-tile"
        @click="handleChatClick(chat)"
      >
        <div class="tile-avatar">
          <span class="avatar-icon">{{ chat.isGroup ? '👥' : '👤' }}</span>
          <div v-if="chat.unreadCount > 0" class="unread-badge">
            {{ chat.unreadCount }}
          </div>
        </div>

        <div class="tile-body">
          <div class="tile-top-row">
            <span class="chat-name" :class="{ bold: chat.unreadCount > 0 }">
              {{ chat.name }}
            </span>
            <span class="chat-time" :class="{ bold: chat.unreadCount > 0 }">
              {{ chat.time }}
            </span>
          </div>
          <p class="chat-message" :class="{ bold: chat.unreadCount > 0 }">
            {{ chat.message }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.chat-list-container {
  padding: 16px 20px 80px;
  background-color: var(--scaffold-bg);
}

.section-header {
  margin-bottom: 12px;
  margin-top: 10px;
}

.section-title {
  font-size: 1.05rem;
  font-weight: 700;
  color: var(--on-surface);
}

.active-slider {
  display: flex;
  gap: 14px;
  overflow-x: auto;
  padding: 4px 0 16px;
  margin-bottom: 16px;
}

.active-slider::-webkit-scrollbar {
  display: none; /* Hide scrollbar for category list */
}

.active-user-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  flex-shrink: 0;
  width: 64px;
}

.avatar-wrap {
  position: relative;
  width: 58px;
  height: 58px;
  border-radius: 50%;
  background-color: var(--surface);
  border: 2px solid var(--primary);
  display: flex;
  justify-content: center;
  align-items: center;
  font-size: 1.4rem;
}

.avatar-wrap.story {
  border-color: var(--outline-variant);
}

.online-dot {
  position: absolute;
  bottom: 0;
  right: 0;
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background-color: var(--sports-green);
  border: 2px solid var(--surface);
}

.user-name {
  font-size: 0.75rem;
  font-weight: 600;
  color: var(--on-surface-variant);
  text-align: center;
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.recent-header {
  margin-top: 16px;
}

.chats-list {
  display: flex;
  flex-direction: column;
}

.chat-tile {
  display: flex;
  gap: 14px;
  padding: 12px 0;
  border-bottom: 1px solid var(--outline-variant);
  cursor: pointer;
}

.tile-avatar {
  position: relative;
  width: 50px;
  height: 50px;
  border-radius: 50%;
  background-color: var(--surface-dim);
  display: flex;
  justify-content: center;
  align-items: center;
  font-size: 1.4rem;
  flex-shrink: 0;
}

.unread-badge {
  position: absolute;
  top: -2px;
  right: -2px;
  background-color: var(--primary);
  color: var(--on-primary);
  font-size: 0.65rem;
  font-weight: 700;
  width: 18px;
  height: 18px;
  border-radius: 50%;
  display: flex;
  justify-content: center;
  align-items: center;
  border: 1.5px solid var(--surface);
}

.tile-body {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
  justify-content: center;
  min-width: 0;
}

.tile-top-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.chat-name {
  font-size: 0.9rem;
  font-weight: 600;
  color: var(--on-surface);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.chat-name.bold {
  font-weight: 700;
}

.chat-time {
  font-size: 0.72rem;
  color: var(--outline);
}

.chat-time.bold {
  color: var(--primary);
  font-weight: 700;
}

.chat-message {
  font-size: 0.8rem;
  color: var(--on-surface-variant);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.chat-message.bold {
  font-weight: 700;
  color: var(--on-surface);
}
</style>
