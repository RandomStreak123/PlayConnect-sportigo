<script setup>
import { ref, onMounted, onUnmounted } from 'vue'

const timeStr = ref('09:41')

const updateTime = () => {
  const now = new Date()
  const hours = String(now.getHours()).padStart(2, '0')
  const minutes = String(now.getMinutes()).padStart(2, '0')
  timeStr.value = `${hours}:${minutes}`
}

let intervalId = null

onMounted(() => {
  updateTime()
  intervalId = setInterval(updateTime, 60000) // Update every minute
})

onUnmounted(() => {
  if (intervalId) clearInterval(intervalId)
})
</script>

<template>
  <div class="phone-wrapper">
    <!-- Phone Bezel & Body (visible on desktop) -->
    <div class="phone-bezel">
      <!-- Phone Notch / Dynamic Island Simulated -->
      <div class="phone-notch"></div>
      
      <!-- Phone Status Bar -->
      <div class="phone-status-bar">
        <div class="status-time">{{ timeStr }}</div>
        <div class="status-indicators">
          <!-- Signal Icon -->
          <svg class="status-icon" viewBox="0 0 24 24" fill="currentColor">
            <path d="M2 22h20V2z"/>
          </svg>
          <!-- Wifi Icon -->
          <svg class="status-icon" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 21l-12-12c4.4-4.4 11.6-4.4 16 0z"/>
          </svg>
          <!-- Battery Icon -->
          <svg class="status-icon battery-icon" viewBox="0 0 24 24" fill="currentColor">
            <rect x="2" y="5" width="16" height="10" rx="2" fill="none" stroke="currentColor" stroke-width="2"/>
            <rect x="5" y="8" width="10" height="4" fill="currentColor"/>
            <path d="M20 9v2" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
          </svg>
        </div>
      </div>
      
      <!-- Inner Screen Viewport -->
      <div class="phone-screen">
        <slot></slot>
      </div>

      <!-- iOS Home Indicator simulated at the bottom -->
      <div class="phone-home-indicator"></div>
    </div>
  </div>
</template>

<style scoped>
.phone-wrapper {
  display: flex;
  justify-content: center;
  align-items: center;
  width: 100%;
  height: 100vh;
}

.phone-bezel {
  position: relative;
  width: 100%;
  max-width: 440px;
  height: 100%;
  max-height: 880px;
  background-color: var(--scaffold-bg);
  border: 12px solid #1E293B; /* Charcoal bezel */
  border-radius: 48px;
  box-shadow: 0 25px 60px -15px rgba(0, 0, 0, 0.35);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

/* Simulated notch / speaker */
.phone-notch {
  position: absolute;
  top: 0;
  left: 50%;
  transform: translateX(-50%);
  width: 130px;
  height: 28px;
  background-color: #1E293B;
  border-bottom-left-radius: 18px;
  border-bottom-right-radius: 18px;
  z-index: 1000;
}

/* Simulated status bar */
.phone-status-bar {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 38px;
  padding: 8px 24px 0;
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.72rem;
  font-weight: 700;
  color: var(--on-surface);
  z-index: 999;
  font-family: 'Inter', sans-serif;
  pointer-events: none;
}

.status-indicators {
  display: flex;
  align-items: center;
  gap: 6px;
}

.status-icon {
  width: 14px;
  height: 14px;
}

.battery-icon {
  width: 16px;
  height: 14px;
}

/* Home bottom bar */
.phone-home-indicator {
  position: absolute;
  bottom: 8px;
  left: 50%;
  transform: translateX(-50%);
  width: 120px;
  height: 5px;
  background-color: #475569;
  border-radius: 3px;
  z-index: 999;
  pointer-events: none;
}

.phone-screen {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  height: 100%;
  position: relative;
}

@media (max-width: 600px) {
  .phone-bezel {
    max-width: 100%;
    height: 100vh;
    max-height: 100vh;
    border: none;
    border-radius: 0;
    box-shadow: none;
  }
  .phone-notch, .phone-status-bar, .phone-home-indicator {
    display: none; /* Hide device simulator on real mobile browser */
  }
}
</style>
