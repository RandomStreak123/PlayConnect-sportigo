import { ref } from 'vue'

// Reactive state for user location
export const userLocation = ref(null)

// Initialize user location from localStorage if available
const cachedLocation = localStorage.getItem('user_coords')
if (cachedLocation) {
  try {
    userLocation.value = JSON.parse(cachedLocation)
  } catch (e) {
    // Ignore invalid cache
  }
}

/**
 * Request and cache user geolocation
 */
export const getUserLocation = () => {
  return new Promise((resolve, reject) => {
    if (!navigator.geolocation) {
      reject(new Error('Geolocation not supported'))
      return
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const coords = {
          latitude: position.coords.latitude,
          longitude: position.coords.longitude
        }
        userLocation.value = coords
        localStorage.setItem('user_coords', JSON.stringify(coords))
        resolve(coords)
      },
      (error) => {
        reject(error)
      },
      {
        enableHighAccuracy: true,
        timeout: 5000,
        maximumAge: 0
      }
    )
  })
}

/**
 * Calculate Haversine distance between two coordinates in kilometers
 */
export const calculateDistance = (lat1, lon1, lat2, lon2) => {
  if (lat1 === null || lat1 === undefined || lon1 === null || lon1 === undefined ||
      lat2 === null || lat2 === undefined || lon2 === null || lon2 === undefined) {
    return null
  }

  const R = 6371 // Radius of the Earth in km
  const dLat = (lat2 - lat1) * Math.PI / 180
  const dLon = (lon2 - lon1) * Math.PI / 180
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2)
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  return R * c
}
