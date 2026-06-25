import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import mkcert from 'vite-plugin-mkcert'

export default defineConfig({
  plugins: [vue(), mkcert()],
  server: {
    https: true,
    watch: {
      usePolling: true
    },
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