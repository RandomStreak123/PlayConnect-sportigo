import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import fs from 'fs'

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue()],
  server: {
    https: {
      key: fs.readFileSync('/home/ajith/.ssl/localhost+2-key.pem'),
      cert: fs.readFileSync('/home/ajith/.ssl/localhost+2.pem'),
    },
    proxy: {
      '/api': {
        target: 'https://playconnect-backend.ddev.site',
        changeOrigin: true,
        secure: false, // Accept self-signed DDEV certs
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

