import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import basicSsl from '@vitejs/plugin-basic-ssl'

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue(), basicSsl()],
  server: {
    https: true,
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

