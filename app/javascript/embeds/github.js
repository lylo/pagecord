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
    container.className = "gist-embed-container"
    container.style.cssText = `
      margin-block: 0 var(--lexxy-content-margin, 1em);
      border: 1px solid var(--border-color, rgba(128, 128, 128, 0.3));
      border-radius: 6px;
      overflow: hidden;
    `

    const iframe = document.createElement("iframe")
    iframe.className = "gist-embed-iframe"
    iframe.style.cssText = "margin-block: 0; width: 100%; border: none;"

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
              -webkit-text-size-adjust: 100%;
              text-size-adjust: 100%;
            }
            /* Only remove outer margins, preserve internal content spacing */
            body > .gist {
              margin: 0 !important;
            }
            .gist > .gist-file {
              margin-bottom: 0 !important;
            }
            /* Ensure paragraph spacing in markdown content */
            .markdown-body p {
              margin-top: 0 !important;
              margin-bottom: 16px !important;
            }
            /* Add spacing between gist content and meta footer */
            .gist-data {
              margin-block-end: 8px !important;
            }
            /* Scale down font size on mobile to prevent oversized text on iOS Safari */
            @media (max-width: 767px) {
              .gist .blob-wrapper,
              .gist .blob-code,
              .gist .blob-num {
                font-size: 12px !important;
                line-height: 1.4 !important;
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
