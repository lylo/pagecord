import MediaSite from "media_site"

class AppleMusic extends MediaSite {
  constructor() {
    super(
      /(https:\/\/(music|podcasts)\.apple\.com\/(..)\/(album|playlist|podcast)\/[^\/]+\/(id)?([0-9]+))(\?.*)?/,

      async (url) => {
        const match = url.match(this.regex)
        if (match) {
          const country = match[1]
          const type = match[2]
          const id = match[3]
          const track_id = match[4]
          return `https://embed.music.apple.com/${country}/${type}/${id}${track_id}`
        }
        return null
      },

      (embedUrl) => {
        const iframe = document.createElement('iframe')
        iframe.src = embedUrl
        iframe.width = "100%"

        const isTrack = /\?i=\d+$/.test(embedUrl)
        iframe.height = isTrack ? "175" : "450"
        iframe.allow = "autoplay *; encrypted-media *; fullscreen *"
        iframe.loading = "lazy"
        iframe.style.borderRadius = "12px"
        iframe.style.border = "0"
        iframe.style.maxWidth = "660px"
        return iframe
      }
    )
  }
}

export default AppleMusic