import MediaSite from "media_site"

class Bandcamp extends MediaSite {
  constructor() {
    super(
      /https:\/\/.*\.bandcamp\.com\/.*/,

      async (url) => {
        try {
          const response = await fetch('/api/embeds/bandcamp', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
            },
            body: JSON.stringify({ url })
          })

          if (!response.ok) return null
          const data = await response.json()
          return data.embed_url
        } catch (error) {
          console.error('Error fetching embed URL:', error)
          return null
        }
      },

      (embedUrl) => {
        const iframe = document.createElement('iframe')
        iframe.src = embedUrl
        iframe.width = "100%"
        iframe.height = "120"
        iframe.seamless = true
        iframe.style.border = "0"
        iframe.style.maxWidth = "660px"
        iframe.style.marginInline = "auto"
        return iframe
      }
    )
  }
}

export default Bandcamp
