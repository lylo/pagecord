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
        const iframe = document.createElement('iframe');
        iframe.src = embedUrl;
        iframe.width = "100%";
        iframe.height = "315";
        iframe.allow = "autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture";
        iframe.loading = "lazy";
        return iframe;
      }
    );
  }
}

export default YouTube;