import MediaSite from "media_site"

class Tidal extends MediaSite {
  constructor() {
    super(
      /https:\/\/tidal\.com\/(playlist\/([a-zA-Z0-9\-]+)|browse\/(track|album)\/([0-9]+))(\?.*)?/,

      async (url) => {
        const match = url.match(this.regex)
        if (match) {
          if (match[2]) {
            // Playlist format: https://tidal.com/playlist/id
            const playlistId = match[2]
            return `https://embed.tidal.com/playlists/${playlistId}`
          } else if (match[3] && match[4]) {
            // Track/Album format: https://tidal.com/browse/track/id or https://tidal.com/browse/album/id
            const type = match[3]
            const id = match[4]
            const pluralType = type === 'track' ? 'tracks' : 'albums'
            return `https://embed.tidal.com/${pluralType}/${id}`
          }
        }
        return null
      },

      (embedUrl) => {
        const iframe = document.createElement('iframe')
        iframe.src = embedUrl
        iframe.width = "100%"
        iframe.allow = "encrypted-media"
        iframe.sandbox = "allow-same-origin allow-scripts allow-forms allow-popups"
        iframe.title = "TIDAL Embed Player"
        iframe.loading = "lazy"
        iframe.style.border = "none"

        // Set height based on content type
        if (embedUrl.includes('/playlists/')) {
          iframe.height = "600"
        } else if (embedUrl.includes('/albums/')) {
          iframe.height = "300"
        } else {
          iframe.height = "200" // tracks
        }

        return iframe
      }
    )
  }
}

export default Tidal
