import MediaSite from "media_site"

class Image extends MediaSite {
  constructor() {
    super(
      // Match URLs ending with common image extensions
      /^https?:\/\/.*\.(jpg|jpeg|png|gif|webp|svg|bmp|ico)(\?.*)?$/i,

      async (url) => {
        // Verify the URL actually points to an image by attempting to load it
        try {
          return new Promise((resolve) => {
            const img = new window.Image()
            img.onload = () => resolve(url)
            img.onerror = () => resolve(null)
            img.src = url
          })
        } catch (error) {
          console.error('Error checking image URL:', error)
          return null
        }
      },

      (imageUrl) => {
        const img = document.createElement('img')
        img.src = imageUrl
        img.loading = "lazy"
        img.alt = "Embedded image"
        return img
      }
    )
  }
}

export default Image
