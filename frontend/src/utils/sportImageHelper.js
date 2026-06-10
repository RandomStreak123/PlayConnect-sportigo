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
  // If it's already a real remote absolute URL (e.g. AWS S3 bucket), use it directly
  if (cleaned && cleaned.startsWith('http') && 
      !cleaned.includes('ddev.site') && 
      !cleaned.includes('localhost') && 
      !cleaned.includes('127.0.0.1')) {
    return cleaned
  }

  // Otherwise, use high-quality seeded random portraits from randomuser.me.
  // Seed the index using the profilePicture path or gender to keep the avatar stable for each user.
  let hash = 0
  const seedString = String(profilePicture || gender || 'player')
  for (let i = 0; i < seedString.length; i++) {
    hash = seedString.charCodeAt(i) + ((hash << 5) - hash)
  }

  const isFemale = String(gender || '').toLowerCase() === 'female' || seedString.toLowerCase().includes('female')
  const genderDir = isFemale ? 'women' : 'men'
  const index = (Math.abs(hash) % 90) + 1 // randomuser.me has portraits 1-99

  return `https://randomuser.me/api/portraits/${genderDir}/${index}.jpg`
}
