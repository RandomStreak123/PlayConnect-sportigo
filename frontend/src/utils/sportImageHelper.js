export const getSportImage = (sport, matchId = '') => {
  const lowerSport = (sport || '').toLowerCase().trim()
  const mappings = {
    football:   '/assets/images/football/images (4).jpg',
    cricket:    '/assets/images/cricket/images (3).jpg',
    badminton:  '/assets/images/badminton/download (6).jpg',
    basketball: '/assets/images/basketball/download (5).jpg',
    tennis:     '/assets/images/tennis/download (4).jpg',
    padel:      '/assets/images/padel/match_bg.png'
  }
  return mappings[lowerSport] || '/assets/images/match_bg.png'
}

export const cleanAvatarUrl = (url) => {
  if (!url) return null

  // Clean up any double-prepended storage URLs
  // E.g. https://playconnect-backend.ddev.site/storage/https://hbgfpnhcixrfgvzpjqvw.supabase.co/...
  // or /storage/https://hbgfpnhcixrfgvzpjqvw.supabase.co/...
  const match = url.match(/(https:\/\/hbgfpnhcixrfgvzpjqvw\.supabase\.co\/.*)/)
  if (match) {
    return match[1]
  }

  const genericMatch = url.match(/https?:\/\/[^\/]+\/storage\/(https?:\/\/.*)/)
  if (genericMatch) {
    return genericMatch[1]
  }

  const relativeMatch = url.match(/\/storage\/(https?:\/\/.*)/)
  if (relativeMatch) {
    return relativeMatch[1]
  }

  return url
}

export const fixImageUrl = (url) => {
  if (!url) return null
  const cleaned = cleanAvatarUrl(url)
  if (cleaned.startsWith('http')) return cleaned
  if (cleaned.startsWith('/')) return cleaned
  try {
    const parsed = new URL(cleaned)
    // Strip the origin, keep only /storage/... path
    return parsed.pathname
  } catch {
    return cleaned
  }
}

export const getPlayerAvatar = (profilePicture, gender) => {
  const cleaned = cleanAvatarUrl(profilePicture)
  
  if (cleaned) {
    const isLocal = !cleaned.includes('supabase.co') &&
                    (cleaned.includes('profile-images/') || 
                     cleaned.includes('/storage/') || 
                     cleaned.includes('localhost') || 
                     cleaned.includes('127.0.0.1') || 
                     cleaned.includes('ddev.site'))

    if (!isLocal && cleaned.startsWith('http')) {
      return cleaned
    }

    if (isLocal) {
      const match = cleaned.match(/(profile-images\/.*)/)
      if (match) {
        return `/storage/${match[1]}`
      }
      if (cleaned.includes('/storage/')) {
        const index = cleaned.indexOf('/storage/')
        return cleaned.substring(index)
      }
      if (cleaned.startsWith('/')) {
        return cleaned
      }
    }
  }

  // Otherwise, use a clean static SVG placeholder for users without a profile picture
  return 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0iI2NiZDVlMSI+PHBhdGggZD0iTTEyIDJDNi40OCAyIDIgNi40OCAyIDEyczQuNDggMTAgMTAgMTAgMTAtNC40OCAxMC0xMFMxNy41MiAyIDEyIDJ6bTAgM2MxLjY2IDAgMyAxLjM0IDMgM3MtMS4zNCAzLTMgMy0zLTEuMzQtMy0zIDEuMzQtMyAzLTN6bTAgMTQuMmMtMi41IDAtNC43MS0xLjI4LTYtMy4yMi4wMy0xLjk5IDQtMy4wOCA2LTMuMDggMS45OSAwIDUuOTcgMS4wOSA2IDMuMDgtMS4yOSAxLjk0LTMuNSAzLjIyLTYgMy4yMnoiLz48L3N2Zz4='
}

export const getSportIconUrl = (sportOrType) => {
  const lower = String(sportOrType || '').toLowerCase().trim()
  const mappings = {
    football:   'https://cdn-icons-png.flaticon.com/128/1165/1165187.png',
    basketball: 'https://cdn-icons-png.flaticon.com/128/1041/1041168.png',
    tennis:     'https://cdn-icons-png.flaticon.com/128/7430/7430195.png',
    padel:      'https://cdn-icons-png.flaticon.com/128/19030/19030325.png',
    pedal:      'https://cdn-icons-png.flaticon.com/128/19030/19030325.png',
    badminton:  'https://cdn-icons-png.flaticon.com/128/11865/11865449.png',
    cricket:    'https://cdn-icons-png.flaticon.com/128/2160/2160064.png',
    // Actions & Notifications
    left:       'https://cdn-icons-png.flaticon.com/128/1828/1828490.png',
    wave:       'https://cdn-icons-png.flaticon.com/128/9437/9437514.png',
    bell:       'https://cdn-icons-png.flaticon.com/128/3602/3602145.png',
    default:    'https://cdn-icons-png.flaticon.com/128/3602/3602145.png'
  }
  return mappings[lower] || mappings.default
}

