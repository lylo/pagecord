import MediaSite from "media_site"

class Image extends MediaSite {
  constructor() {
    super(
      // Match URLs ending with common image extensions
      /^https?:\/\/.*\.(jpg|jpeg|png|gif|webp|svg|bmp|ico)(\?.*)?$/i,

      (url) => url,

      (imageUrl) => {
        const img = document.createElement("img")
        img.loading = "lazy"
        img.alt = "Embedded image"
        img.addEventListener("error", () => img.replaceWith(linkTo(imageUrl)), { once: true })
        img.src = imageUrl
        return img
      }
    )
  }
}

function linkTo(url) {
  const link = document.createElement("a")
  link.href = url
  link.textContent = url
  return link
}

export default Image
