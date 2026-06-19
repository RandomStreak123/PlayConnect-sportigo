<script setup>
import { ref, onMounted, watch, nextTick, computed } from 'vue'
import { store } from '../store'

const emit = defineEmits(['auth-success'])

const activeTab = ref('signin') // 'signin' or 'signup'

// Sign In Fields
const loginUsername = ref('')
const loginPassword = ref('')
const loginPasswordVisible = ref(false)
const loginLoading = ref(false)
const loginError = ref('')
const loginSuccess = ref('')

// Sign Up Fields
const registerName = ref('')
const registerUsername = ref('')
const registerPassword = ref('')
const registerPasswordVisible = ref(false)
const selectedGender = ref(null)
const signupLoading = ref(false)
const signupError = ref('')

const toggleLoginPassword = () => {
  loginPasswordVisible.value = !loginPasswordVisible.value
}

const toggleRegisterPassword = () => {
  registerPasswordVisible.value = !registerPasswordVisible.value
}

const selectGender = (gender) => {
  selectedGender.value = gender
}

const socialLoading = ref('')

// Prevent browser from auto-filling fields on page load
const isReadonly = ref(true)
const removeReadonly = () => {
  isReadonly.value = false
}

const handleSignIn = async () => {
  if (!loginUsername.value || !loginPassword.value) {
    loginError.value = 'Please enter username and password'
    return
  }
  loginError.value = ''
  loginSuccess.value = ''
  loginLoading.value = true
  
  try {
    const success = await store.login(loginUsername.value, loginPassword.value)
    loginLoading.value = false
    if (success) {
      emit('auth-success')
    } else {
      loginError.value = 'Invalid login details'
    }
  } catch (e) {
    loginError.value = e.message || 'Login failed'
    loginLoading.value = false
  }
}

const handleSocialLogin = async (provider) => {
  socialLoading.value = provider
  setTimeout(() => {
    socialLoading.value = ''
    const msg = `${provider} login integration coming soon! Stay tuned.`
    if (activeTab.value === 'signup') {
      signupError.value = msg
    } else {
      loginError.value = msg
    }
  }, 1200)
}

const handleSignUp = async () => {
  if (!registerName.value || !registerUsername.value || !registerPassword.value) {
    signupError.value = 'Please fill all fields'
    return
  }
  signupError.value = ''
  signupLoading.value = true
  
  try {
    const success = await store.register(
      registerName.value,
      registerUsername.value,
      registerPassword.value,
      selectedGender.value || 'male'
    )
    signupLoading.value = false
    if (success) {
      activeTab.value = 'signin'
      loginSuccess.value = 'Registration successful! Please log in.'
      loginError.value = ''
      // Clear signup fields
      registerName.value = ''
      registerUsername.value = ''
      registerPassword.value = ''
    } else {
      signupError.value = 'Registration failed'
    }
  } catch (e) {
    signupError.value = e.message || 'Registration failed'
    signupLoading.value = false
  }
}

const googleSdkReady = ref(false)
const hasClientId = ref(!!import.meta.env.VITE_GOOGLE_CLIENT_ID)

const isLocalDev = computed(() => {
  if (typeof window === 'undefined') return false
  return window.location.hostname === 'localhost' || 
         window.location.hostname === '127.0.0.1' || 
         window.location.hostname.includes('ddev.site')
})

const handleCredentialResponse = async (response) => {
  const credential = response.credential
  if (!credential) return

  if (activeTab.value === 'signup') {
    signupLoading.value = true
    signupError.value = ''
  } else {
    loginLoading.value = true
    loginError.value = ''
  }

  try {
    const success = await store.loginWithGoogle(credential)
    if (success) {
      emit('auth-success')
    }
  } catch (error) {
    const msg = error.message || 'Google authentication failed'
    if (activeTab.value === 'signup') {
      signupError.value = msg
    } else {
      loginError.value = msg
    }
  } finally {
    loginLoading.value = false
    signupLoading.value = false
  }
}

const renderGoogleButtons = () => {
  console.log("renderGoogleButtons triggered. SDK ready:", googleSdkReady.value, "google object:", !!(typeof window !== 'undefined' && window.google))
  if (typeof window !== 'undefined' && window.google && googleSdkReady.value) {
    const options = {
      type: "icon",
      shape: "circle",
      size: "large",
      theme: "outline"
    }
    const btnSignin = document.getElementById("google-signin-btn-signin")
    console.log("google-signin-btn-signin element found:", !!btnSignin)
    if (btnSignin) {
      try {
        window.google.accounts.id.renderButton(btnSignin, options)
        console.log("Google sign-in button rendered for signin tab successfully")
      } catch (err) {
        console.error("Failed to render Google sign-in button for signin tab:", err)
      }
    }
    const btnSignup = document.getElementById("google-signin-btn-signup")
    console.log("google-signin-btn-signup element found:", !!btnSignup)
    if (btnSignup) {
      try {
        window.google.accounts.id.renderButton(btnSignup, options)
        console.log("Google sign-in button rendered for signup tab successfully")
      } catch (err) {
        console.error("Failed to render Google sign-in button for signup tab:", err)
      }
    }
  }
}

const initializeGoogleSignIn = () => {
  if (typeof window === 'undefined' || !window.google) return

  const clientId = import.meta.env.VITE_GOOGLE_CLIENT_ID
  hasClientId.value = !!clientId
  if (!clientId) {
    console.warn('VITE_GOOGLE_CLIENT_ID not configured. Google sign-in button will not render.')
    return
  }

  try {
    window.google.accounts.id.initialize({
      client_id: clientId,
      callback: handleCredentialResponse,
      auto_select: false,
      cancel_on_tap_outside: true,
    })

    googleSdkReady.value = true
    nextTick(() => {
      renderGoogleButtons()
    })
  } catch (error) {
    console.error('Failed to initialize Google Sign-In:', error)
  }
}

watch(activeTab, () => {
  loginError.value = ''
  signupError.value = ''
  if (activeTab.value !== 'signin') {
    loginSuccess.value = ''
  }
  nextTick(() => {
    renderGoogleButtons()
  })
})

onMounted(() => {
  loginUsername.value = ''
  loginPassword.value = ''
  registerName.value = ''
  registerUsername.value = ''
  registerPassword.value = ''
  setTimeout(() => {
    loginUsername.value = ''
    loginPassword.value = ''
    registerName.value = ''
    registerUsername.value = ''
    registerPassword.value = ''
  }, 100)
  setTimeout(() => {
    loginUsername.value = ''
    loginPassword.value = ''
    registerName.value = ''
    registerUsername.value = ''
    registerPassword.value = ''
  }, 500)

  if (typeof window !== 'undefined') {
    if (!window.google) {
      const script = document.createElement('script')
      script.src = 'https://accounts.google.com/gsi/client'
      script.async = true
      script.defer = true
      script.onload = () => {
        initializeGoogleSignIn()
      }
      document.head.appendChild(script)
    } else {
      initializeGoogleSignIn()
    }
  }
})
</script>

<template>
  <div class="auth-container scrollable-y animate-fade-in">
    <div v-if="activeTab === 'signin'" class="logo-header">
      <div class="logo-icon">⚡</div>
      <h1 class="brand-title">PlayConnect</h1>
      <p class="brand-subtitle">Sportigo Matchmaker Platform</p>
    </div>

    <!-- Tab Selector -->
    <div v-if="activeTab === 'signin'" class="auth-tabs">
      <button 
        class="auth-tab-btn" 
        :class="{ active: activeTab === 'signin' }"
        @click="activeTab = 'signin'"
      >
        Sign In
      </button>
      <button 
        class="auth-tab-btn" 
        :class="{ active: activeTab === 'signup' }"
        @click="activeTab = 'signup'"
      >
        Sign Up
      </button>
    </div>

    <!-- Sign In Panel -->
    <div v-if="activeTab === 'signin'" class="form-panel animate-fade-in">
      <h2 class="form-title">Welcome Back</h2>
      <p class="form-subtitle">Sign in to join your next match</p>

      <div v-if="loginError" class="error-banner">{{ loginError }}</div>
      <div v-if="loginSuccess" class="success-banner">{{ loginSuccess }}</div>

      <!-- Decoy inputs to trap browser autofill -->
      <input type="text" id="username" name="username" style="position: absolute; top: -9999px; left: -9999px;" tabindex="-1" />
      <input type="password" id="password" name="password" style="position: absolute; top: -9999px; left: -9999px;" tabindex="-1" />

      <div class="input-group">
        <label class="input-label">Username</label>
        <div class="input-wrapper">
          <span class="input-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="input-svg"><path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
          </span>
          <input 
            v-model="loginUsername" 
            type="text" 
            id="real-login-username-input"
            name="real_login_username_input"
            placeholder="Enter your username" 
            class="form-input"
            :readonly="isReadonly"
            @focus="removeReadonly"
            @mousedown="removeReadonly"
            @touchstart="removeReadonly"
            @keyup.enter="handleSignIn"
            autocomplete="off"
          />
        </div>
      </div>

      <div class="input-group">
        <label class="input-label">Password</label>
        <div class="input-wrapper">
          <span class="input-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="input-svg"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
          </span>
          <input 
            v-model="loginPassword" 
            :type="loginPasswordVisible ? 'text' : 'password'" 
            id="real-login-password-input"
            name="real_login_password_input"
            placeholder="Enter your password" 
            class="form-input"
            :readonly="isReadonly"
            @focus="removeReadonly"
            @mousedown="removeReadonly"
            @touchstart="removeReadonly"
            @keyup.enter="handleSignIn"
            autocomplete="off"
          />
          <button class="password-toggle-btn" @click="toggleLoginPassword">
            <svg v-if="loginPasswordVisible" xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="toggle-svg"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
            <svg v-else xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="toggle-svg"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
          </button>
        </div>
      </div>

      <div class="forgot-pwd">
        <a href="#" class="text-link">Forgot Password?</a>
      </div>

      <button type="button" class="submit-btn" :disabled="loginLoading" @click="handleSignIn">
        <span v-if="loginLoading" class="loader"></span>
        <span v-else>Sign In</span>
      </button>

      <!-- Social login divider -->
      <div class="social-divider">
        <span class="divider-line"></span>
        <span class="divider-text">or continue with</span>
        <span class="divider-line"></span>
      </div>

      <div class="social-buttons" style="justify-content: center;">
        <div id="google-signin-btn-signin" class="google-btn-container"></div>
      </div>
    </div>

    <!-- Sign Up Panel -->
    <div v-else class="form-panel signup-panel animate-fade-in">
      <button type="button" class="back-btn" @click="activeTab = 'signin'" aria-label="Back to Sign In">
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <line x1="19" y1="12" x2="5" y2="12"></line>
          <polyline points="12 19 5 12 12 5"></polyline>
        </svg>
      </button>

      <h2 class="form-title">Create Account</h2>
      <p class="form-subtitle">Join the Sportigo community</p>

      <div v-if="signupError" class="error-banner">{{ signupError }}</div>

      <!-- Decoy inputs to trap browser autofill on signup -->
      <input type="text" name="signup_name" style="position: absolute; top: -9999px; left: -9999px;" tabindex="-1" />
      <input type="text" name="signup_username" style="position: absolute; top: -9999px; left: -9999px;" tabindex="-1" />
      <input type="password" name="signup_password" style="position: absolute; top: -9999px; left: -9999px;" tabindex="-1" />

      <div class="input-group">
        <label class="input-label">Full Name</label>
        <div class="input-wrapper">
          <span class="input-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="input-svg">
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
              <circle cx="12" cy="7" r="4"></circle>
            </svg>
          </span>
          <input 
            v-model="registerName" 
            type="text"
            id="real-register-name-input"
            name="real_register_name_input"
            placeholder="Enter your full name" 
            class="form-input"
            :readonly="isReadonly"
            @focus="removeReadonly"
            @mousedown="removeReadonly"
            @touchstart="removeReadonly"
            autocomplete="off"
          />
        </div>
      </div>

      <div class="input-group">
        <label class="input-label">Username</label>
        <div class="input-wrapper">
          <span class="input-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="input-svg">
              <circle cx="12" cy="12" r="4"></circle>
              <path d="M16 8v5a3 3 0 0 0 6 0v-1a10 10 0 1 0-3.92 7.94"></path>
            </svg>
          </span>
          <input 
            v-model="registerUsername" 
            type="text"
            id="real-register-username-input"
            name="real_register_username_input"
            placeholder="Choose a username" 
            class="form-input"
            :readonly="isReadonly"
            @focus="removeReadonly"
            @mousedown="removeReadonly"
            @touchstart="removeReadonly"
            autocomplete="off"
          />
        </div>
      </div>

      <div class="input-group">
        <label class="input-label">Password</label>
        <div class="input-wrapper">
          <span class="input-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="input-svg">
              <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
              <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
            </svg>
          </span>
          <input 
            v-model="registerPassword" 
            :type="registerPasswordVisible ? 'text' : 'password'"
            id="real-register-password-input"
            name="real_register_password_input"
            placeholder="Create a password" 
            class="form-input"
            :readonly="isReadonly"
            @focus="removeReadonly"
            @mousedown="removeReadonly"
            @touchstart="removeReadonly"
            autocomplete="new-password"
          />
          <button type="button" class="password-toggle-btn" @click="toggleRegisterPassword" aria-label="Toggle password visibility">
            <svg v-if="registerPasswordVisible" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="toggle-svg">
              <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path>
              <line x1="1" y1="1" x2="23" y2="23"></line>
            </svg>
            <svg v-else xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="toggle-svg">
              <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
              <circle cx="12" cy="12" r="3"></circle>
            </svg>
          </button>
        </div>
      </div>

      <!-- Gender Selector -->
      <div class="gender-section">
        <label class="input-label">Gender Identity (Optional)</label>
        <div class="gender-cards">
          <div 
            class="gender-card male" 
            :class="{ active: selectedGender === 'male' }"
            @click="selectGender('male')"
          >
            <span class="gender-icon-wrapper">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="gender-svg">
                <circle cx="10" cy="14" r="5"></circle>
                <path d="M14 10l7-7"></path>
                <path d="M16 3h5v5"></path>
              </svg>
            </span>
            <span class="gender-label">Male</span>
          </div>
          <div 
            class="gender-card female" 
            :class="{ active: selectedGender === 'female' }"
            @click="selectGender('female')"
          >
            <span class="gender-icon-wrapper">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="gender-svg">
                <circle cx="12" cy="8" r="5"></circle>
                <path d="M12 13v8"></path>
                <path d="M9 18h6"></path>
              </svg>
            </span>
            <span class="gender-label">Female</span>
          </div>
          <div 
            class="gender-card other" 
            :class="{ active: selectedGender === 'other' }"
            @click="selectGender('other')"
          >
            <span class="gender-icon-wrapper">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="gender-svg">
                <circle cx="12" cy="12" r="4"></circle>
                <path d="M12 16v5"></path>
                <path d="M9.5 19h5"></path>
                <path d="M15 9l5-5"></path>
                <path d="M16 4h4v4"></path>
                <path d="M9 9L4 4"></path>
                <path d="M3 7l4-4"></path>
              </svg>
            </span>
            <span class="gender-label">Other</span>
          </div>
        </div>
      </div>

      <button type="button" class="submit-btn" :disabled="signupLoading" @click="handleSignUp">
        <span v-if="signupLoading" class="loader"></span>
        <span v-else>Sign Up</span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.auth-container {
  display: flex;
  flex-direction: column;
  width: 100%;
}

.logo-header {
  text-align: center;
  margin-top: 40px;
  margin-bottom: 32px;
}

.logo-icon {
  font-size: 3rem;
  margin-bottom: 12px;
  display: inline-block;
  animation: pulseGlow 2s infinite;
}

.brand-title {
  font-size: 1.8rem;
  font-weight: 800;
  color: var(--primary);
  margin-bottom: 4px;
}

.brand-subtitle {
  font-size: 0.85rem;
  color: var(--on-surface-variant);
  font-weight: 500;
}

.auth-tabs {
  display: flex;
  background-color: var(--surface-dim);
  border-radius: var(--radius-md);
  padding: 4px;
  margin-bottom: 32px;
}

.auth-tab-btn {
  flex: 1;
  border: none;
  background: none;
  padding: 10px;
  font-weight: 700;
  font-size: 0.9rem;
  border-radius: 12px;
  color: var(--on-surface-variant);
  cursor: pointer;
  transition: all 0.2s ease;
}

.auth-tab-btn.active {
  background-color: var(--surface);
  color: var(--primary);
  box-shadow: var(--shadow-sm);
}

.form-panel {
  display: flex;
  flex-direction: column;
}

.form-title {
  font-size: 1.5rem;
  font-weight: 700;
  margin-bottom: 6px;
}

.form-subtitle {
  font-size: 0.88rem;
  color: var(--on-surface-variant);
  margin-bottom: 28px;
}

.error-banner {
  background-color: rgba(186, 26, 26, 0.1);
  color: var(--error);
  padding: 12px;
  border-radius: var(--radius-sm);
  font-size: 0.8rem;
  font-weight: 600;
  margin-bottom: 16px;
  border: 1px solid rgba(186, 26, 26, 0.2);
}

.success-banner {
  background-color: rgba(16, 185, 129, 0.1);
  color: #10b981;
  padding: 12px;
  border-radius: var(--radius-sm);
  font-size: 0.8rem;
  font-weight: 600;
  margin-bottom: 16px;
  border: 1px solid rgba(16, 185, 129, 0.2);
}

.input-group {
  margin-bottom: 20px;
  display: flex;
  flex-direction: column;
}

.input-label {
  font-size: 0.85rem;
  font-weight: 700;
  color: var(--on-surface);
  margin-bottom: 8px;
}

.input-wrapper {
  position: relative;
  display: flex;
  align-items: center;
}

.input-icon {
  position: absolute;
  left: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--outline);
}

.input-svg {
  stroke: var(--outline);
  transition: stroke 0.2s ease;
}

.input-wrapper:focus-within .input-svg {
  stroke: var(--primary);
}

.form-input {
  width: 100%;
  padding: 14px 14px 14px 40px;
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  font-size: 0.95rem;
  font-weight: 500;
  color: var(--on-surface);
  outline: none;
  transition: border-color 0.2s ease, box-shadow 0.2s ease;
}

.form-input:focus {
  border-color: var(--primary);
  box-shadow: 0 0 0 3px rgba(26, 35, 126, 0.08);
}

.password-toggle-btn {
  position: absolute;
  right: 14px;
  background: none;
  border: none;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--outline);
}

.toggle-svg {
  stroke: var(--outline);
  transition: stroke 0.2s ease;
}

.password-toggle-btn:hover .toggle-svg {
  stroke: var(--primary);
}

.forgot-pwd {
  text-align: right;
  margin-bottom: 28px;
}

.text-link {
  font-size: 0.85rem;
  font-weight: 700;
  color: var(--primary);
  text-decoration: none;
}

.submit-btn {
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
  box-shadow: var(--shadow-sm);
  transition: filter 0.2s ease;
}

.submit-btn:hover {
  filter: brightness(1.1);
}

.submit-btn:disabled {
  background-color: var(--outline-variant);
  color: var(--outline);
  cursor: not-allowed;
}

/* Gender selector design */
.gender-section {
  margin-bottom: 28px;
}

.gender-cards {
  display: flex;
  gap: 10px;
}

.gender-card {
  flex: 1;
  background-color: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius-md);
  padding: 14px 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.gender-icon {
  font-size: 1.6rem;
  color: var(--on-surface-variant);
}

.gender-label {
  font-size: 0.78rem;
  font-weight: 700;
  color: var(--on-surface);
}

/* Active gender classes */
.gender-card.male.active {
  background-color: rgba(33, 150, 243, 0.08);
  border-color: #2196F3;
  box-shadow: 0 4px 10px rgba(33, 150, 243, 0.15);
}
.gender-card.male.active .gender-icon {
  color: #2196F3;
}

.gender-card.female.active {
  background-color: rgba(233, 30, 99, 0.08);
  border-color: #E91E63;
  box-shadow: 0 4px 10px rgba(233, 30, 99, 0.15);
}
.gender-card.female.active .gender-icon {
  color: #E91E63;
}

.gender-card.other.active {
  background-color: rgba(156, 39, 176, 0.08);
  border-color: #9C27B0;
  box-shadow: 0 4px 10px rgba(156, 39, 176, 0.15);
}
.gender-card.other.active .gender-icon {
  color: #9C27B0;
}

/* Loader animation spinner */
.loader {
  width: 20px;
  height: 20px;
  border: 2px solid var(--on-primary);
  border-bottom-color: transparent;
  border-radius: 50%;
  display: inline-block;
  animation: rotation 1s linear infinite;
}

@keyframes rotation {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* Social login section */
.social-divider {
  display: flex;
  align-items: center;
  gap: 14px;
  margin: 28px 0 20px;
}

.divider-line {
  flex: 1;
  height: 1px;
  background: var(--outline-variant);
}

.divider-text {
  font-size: 0.78rem;
  font-weight: 600;
  color: var(--outline);
  text-transform: uppercase;
  letter-spacing: 0.5px;
  white-space: nowrap;
}

.social-buttons {
  display: flex;
  gap: 12px;
}

.google-btn-wrapper {
  width: 100%;
  display: flex;
  justify-content: center;
}

.social-btn {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 13px 16px;
  border-radius: var(--radius-md);
  font-size: 0.88rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.25s ease;
  border: 1px solid var(--outline-variant);
  background-color: var(--surface);
  color: var(--on-surface);
  position: relative;
  overflow: hidden;
}

.social-btn::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  opacity: 0;
  transition: opacity 0.25s ease;
  border-radius: inherit;
}

.social-btn.google::before {
  background: linear-gradient(135deg, #4285F4, #34A853, #FBBC05, #EA4335);
}

.social-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.1);
}

.social-btn.google.circular {
  flex: none;
  width: 48px;
  height: 48px;
  border-radius: 50%;
  padding: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto;
}

.social-btn.google:hover {
  border-color: #4285F4;
  background-color: rgba(66, 133, 244, 0.04);
}

.social-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}

.social-icon {
  flex-shrink: 0;
}

.social-loader {
  width: 18px;
  height: 18px;
  border-width: 2px;
  border-color: var(--outline);
  border-bottom-color: transparent;
}

@media (min-width: 1025px) {
  .logo-header {
    display: none;
  }
}

.google-btn-container {
  display: flex;
  justify-content: center;
  align-items: center;
  margin: 0 auto;
  width: 46px;
  height: 46px;
  transition: transform 0.25s ease;
  border-radius: 50%;
  border: 1px solid var(--outline-variant);
  background-color: var(--surface);
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 24 24' width='22' height='22' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z' fill='%234285F4'/%3E%3Cpath d='M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z' fill='%2334A853'/%3E%3Cpath d='M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z' fill='%23FBBC05'/%3E%3Cpath d='M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z' fill='%23EA4335'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: center;
  background-size: 20px;
  cursor: pointer;
  position: relative;
}

.google-btn-container:hover {
  transform: translateY(-2px);
}

/* Make the Google SDK wrapper transparent and stretch to cover the wrapper */
.google-btn-container :deep() > * {
  opacity: 0.01 !important;
  width: 100% !important;
  height: 100% !important;
  position: absolute !important;
  top: 0 !important;
  left: 0 !important;
  background: transparent !important;
  border: none !important;
  border-radius: 50% !important;
  cursor: pointer !important;
}

/* Signup Panel Redesign Overrides */
.signup-panel {
  position: relative;
  padding-top: 10px;
}

.back-btn {
  background: none;
  border: none;
  cursor: pointer;
  padding: 8px 0;
  margin-bottom: 20px;
  align-self: flex-start;
  color: var(--on-surface);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: transform 0.2s ease, opacity 0.2s ease;
}

.back-btn:hover {
  transform: translateX(-4px);
  opacity: 0.8;
}

.signup-panel .form-title {
  font-size: 1.5rem;
  font-weight: 700;
  font-family: var(--font-display);
  color: var(--on-surface);
  margin-bottom: 6px;
}

.signup-panel .form-subtitle {
  font-size: 0.88rem;
  color: var(--on-surface-variant);
  margin-bottom: 28px;
}

.signup-panel .input-group {
  margin-bottom: 20px;
}

.signup-panel .input-label {
  font-size: 0.85rem;
  font-weight: 700;
  color: var(--on-surface);
  margin-bottom: 8px;
}

.signup-panel .form-input {
  background-color: #f3f2f8;
  border: none;
  border-radius: 16px;
  padding: 14px 14px 14px 48px;
  font-size: 0.95rem;
  color: var(--on-surface);
  transition: background-color 0.2s ease, box-shadow 0.2s ease;
}

.signup-panel .form-input:focus {
  background-color: #eae9f1;
  box-shadow: 0 0 0 2px var(--primary);
}

.signup-panel .input-icon {
  left: 18px;
  color: #7c7a8a;
  font-size: 1.1rem;
}

.signup-panel .password-toggle-btn {
  right: 18px;
  color: #7c7a8a;
}

.signup-panel .password-toggle-btn:hover .toggle-svg {
  stroke: var(--primary);
}

.signup-panel .gender-section {
  margin-bottom: 24px;
}

.signup-panel .gender-cards {
  display: flex;
  gap: 12px;
}

.signup-panel .gender-card {
  flex: 1;
  background-color: #f3f2f8;
  border: 2px solid transparent;
  border-radius: 16px;
  padding: 20px 10px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.signup-panel .gender-icon-wrapper {
  color: #7c7a8a;
  display: flex;
  align-items: center;
  justify-content: center;
}

.signup-panel .gender-label {
  font-size: 0.78rem;
  font-weight: 700;
  color: #7c7a8a;
}

/* Active states for Gender Cards matching the design */
.signup-panel .gender-card.male.active {
  background-color: rgba(33, 150, 243, 0.06);
  border-color: #2196F3;
}
.signup-panel .gender-card.male.active .gender-icon-wrapper {
  color: #2196F3;
}
.signup-panel .gender-card.male.active .gender-label {
  color: #2196F3;
}

.signup-panel .gender-card.female.active {
  background-color: rgba(233, 30, 99, 0.06);
  border-color: #E91E63;
}
.signup-panel .gender-card.female.active .gender-icon-wrapper {
  color: #E91E63;
}
.signup-panel .gender-card.female.active .gender-label {
  color: #E91E63;
}

.signup-panel .gender-card.other.active {
  background-color: rgba(156, 39, 176, 0.06);
  border-color: #9C27B0;
}
.signup-panel .gender-card.other.active .gender-icon-wrapper {
  color: #9C27B0;
}
.signup-panel .gender-card.other.active .gender-label {
  color: #9C27B0;
}

/* Submit button matching design */
.signup-panel .submit-btn {
  background-color: var(--primary);
  color: var(--on-primary);
  border: none;
  border-radius: 16px;
  padding: 16px;
  font-size: 1rem;
  font-weight: 700;
  cursor: pointer;
  display: flex;
  justify-content: center;
  align-items: center;
  width: 100%;
  margin-top: 8px;
  transition: opacity 0.2s ease, transform 0.1s ease;
}

.signup-panel .submit-btn:hover {
  opacity: 0.95;
  transform: translateY(-1px);
}

.signup-panel .submit-btn:active {
  transform: translateY(0);
}
</style>
