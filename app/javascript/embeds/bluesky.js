import MediaSite from "media_site"

class Bluesky extends MediaSite {
  constructor() {
    super(
      /https:\/\/bsky\.app\/profile\/([^/]+)\/post\/([a-zA-Z0-9]+)/,

      async (url) => {
        const match = url.match(this.regex)
        if (!match) return null

        let identifier = match[1]
        const rkey = match[2]

        if (!identifier.startsWith("did:")) {
          try {
            const response = await fetch(`https://public.api.bsky.app/xrpc/com.atproto.identity.resolveHandle?handle=${encodeURIComponent(identifier)}`)
            if (!response.ok) return null
            const { did } = await response.json()
            identifier = did
          } catch {
            return null
          }
        }

        return `https://embed.bsky.app/embed/${identifier}/app.bsky.feed.post/${rkey}`
      },

      (embedUrl) => {
        const iframe = document.createElement('iframe')
        iframe.src = embedUrl
        iframe.width = "100%"
        iframe.height = "350"
        iframe.style.overflow = "hidden"
        iframe.loading = "lazy"
        iframe.style.border = "0"
        iframe.style.borderRadius = "12px"
        iframe.style.maxWidth = "600px"
        iframe.style.marginInline = "auto"

        window.addEventListener('message', ({ origin, source, data }) => {
          if (origin !== 'https://embed.bsky.app') return
          if (source !== iframe.contentWindow) return
          if (typeof data?.height === 'number') iframe.height = data.height
        }, { passive: true })

        return iframe
      }
    )
  }
}

export default Bluesky
