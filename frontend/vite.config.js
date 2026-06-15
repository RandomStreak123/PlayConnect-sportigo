import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    proxy: {
      '/api': {
        target: 'https://playconnect-backend.ddev.site',
        changeOrigin: true,
        secure: false,
        rewrite: (path) => path
      },
      '/storage': {
        target: 'https://playconnect-backend.ddev.site',
        changeOrigin: true,
        secure: false
      }
    }
  }
})