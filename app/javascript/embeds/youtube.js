import MediaSite from './media_site'

class YouTube extends MediaSite {
  constructor() {
    super(
      /(?:https:\/\/www\.youtube\.com\/watch\?v=|https:\/\/youtu\.be\/)([a-zA-Z0-9_-]+)/,
      (url) => {
        const match = url.match(this.regex);
        if (match) {
          const videoId = match[1];
          return `https://www.youtube.com/embed/${videoId}`;
        }
        return null;
      },
      (embedUrl) => {
        const div = document.createElement('div');
        div.className = "aspect-w-16 aspect-h-9";

        const iframe = document.createElement('iframe');
        iframe.className = "mx-auto w-full h-full";
        iframe.src = embedUrl;
        iframe.allow = "autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture";
        iframe.loading = "lazy";

        div.appendChild(iframe);

        return div;
      }
    );
  }
}

export default YouTube;