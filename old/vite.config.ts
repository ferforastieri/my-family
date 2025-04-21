import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { VitePWA } from 'vite-plugin-pwa'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), VitePWA({
    registerType: 'autoUpdate',
    includeAssets: ['icons/*', 'screenshots/*'],
    manifest: {
      name: 'Love Page',
      short_name: 'Love',
      description: 'Uma página especial de amor',
      theme_color: '#ff69b4',
      background_color: '#fff8fa',
      display: 'standalone',
      start_url: '/',
      icons: [
        {
          src: 'icons/icon-192x192.png',
          sizes: '192x192',
          type: 'image/png'
        },
        {
          src: 'icons/icon-512x512.png',
          sizes: '512x512',
          type: 'image/png'
        }
      ],
      screenshots: [
        {
          src: 'screenshots/desktop.png',
          sizes: '1873x924',
          type: 'image/png',
          form_factor: 'wide',
          label: 'Tela inicial no desktop'
        },
        {
          src: 'screenshots/mobile.png',
          sizes: '1402x592',
          type: 'image/png',
          form_factor: 'narrow',
          label: 'Tela inicial no celular'
        }
      ]
    },
    workbox: {
      globPatterns: ['**/*.{js,css,html,ico,png,svg,jpg}'],
      runtimeCaching: [
        {
          urlPattern: /^https:\/\/fonts\.googleapis\.com\/.*/i,
          handler: 'CacheFirst',
          options: {
            cacheName: 'google-fonts-cache',
            expiration: {
              maxEntries: 10,
              maxAgeSeconds: 60 * 60 * 24 * 365 // <== 365 dias
            },
            cacheableResponse: {
              statuses: [0, 200]
            }
          }
        }
      ]
    },
    devOptions: {
      enabled: true,
      type: 'module'
    }
  })],
})
