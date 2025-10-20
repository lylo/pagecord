import MediaSite from "media_site"

class Tidal extends MediaSite {
  constructor() {
    super(
      /https:\/\/tidal\.com\/(playlist\/([a-zA-Z0-9\-]+)|(browse\/)?(track|album)\/([0-9]+))(\?.*)?/,

      async (url) => {
        const match = url.match(this.regex)
        if (match) {
          if (match[2]) {
            // Playlist format: https://tidal.com/playlist/id
            const playlistId = match[2]
            return `https://embed.tidal.com/playlists/${playlistId}`
          } else if (match[4] && match[5]) {
            // Track/Album format: https://tidal.com/browse/track/id or https://tidal.com/track/id
            const type = match[4]
            const id = match[5]
            const pluralType = type === 'track' ? 'tracks' : 'albums'
            return `https://embed.tidal.com/${pluralType}/${id}`
          }
        }
        return null
      },

      (embedUrl) => {
        const iframe = document.createElement('iframe')
        iframe.src = embedUrl
        iframe.allow = "encrypted-media"
        iframe.sandbox = "allow-same-origin allow-scripts allow-forms allow-popups"
        iframe.title = "TIDAL Embed Player"
        iframe.loading = "lazy"
        iframe.style.display = "block"

        // Set height based on content type
        // Tidal embeds have internal 100vh sizing, so these need to be generous
        if (embedUrl.includes('/playlists/')) {
          iframe.height = "600"
        } else if (embedUrl.includes('/albums/')) {
          iframe.height = "450"
        } else {
          iframe.height = "120" // tracks - compact player
        }

        return iframe
      }
    )
  }
}

export default Tidal
