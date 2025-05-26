import MediaSite from "media_site"

class GitHub extends MediaSite {
  constructor() {
    const gistRegex = /https:\/\/gist\.github\.com\/([a-zA-Z0-9_.-]+)\/([a-zA-Z0-9]+)/

    super(
      gistRegex,
      async (url) => (gistRegex.test(url) ? url : null),
      (url) => {
        const match = url.match(gistRegex)
        return match ? GitHub.createIframeEmbed(match[1], match[2]) : null
      }
    )
  }

  static createIframeEmbed(username, gistId) {
    const container = document.createElement("div")
    container.className = "border border-slate-300 dark:border-slate-700 rounded-lg overflow-hidden"

    const iframe = document.createElement("iframe")
    iframe.className = "w-full rounded-lg"
    iframe.style.border = "none"
    iframe.style.overflow = "hidden"

    iframe.srcdoc = `
      <!DOCTYPE html>
      <html>
        <head>
          <base target="_parent">
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            html, body {
              margin: 0;
              padding: 0;
              overflow: hidden;
            }
            .gist, .gist-file {
              margin: 0 !important;
              padding: 0 !important;
            }
            /* Mobile optimizations */
            @media (max-width: 640px) {
              .gist .blob-code {
                font-size: 12px !important;
                line-height: 1.4 !important;
              }
              .gist .gist-meta {
                font-size: 11px !important;
              }
            }
          </style>
        </head>
        <body>
          <script src="https://gist.github.com/${username}/${gistId}.js"></script>
        </body>
      </html>`

    // Fallback height
    iframe.style.height = "400px"

    // Optional: resize iframe height based on content
    iframe.onload = () => {
      try {
        const doc = iframe.contentDocument || iframe.contentWindow.document
        iframe.style.height = doc.body.scrollHeight + "px"
      } catch (_) {
        // Silent fail if cross-origin issues
      }
    }

    container.appendChild(iframe)
    return container
  }
}

export default GitHub
