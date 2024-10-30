class MediaSite {
  constructor(regex, getEmbedUrl, createEmbedIframe) {
    this.regex = regex;
    this.getEmbedUrl = getEmbedUrl;
    this.createEmbedIframe = createEmbedIframe;
  }

  async transform(url) {
    const embedUrl = await this.getEmbedUrl(url);
    if (!embedUrl) return null;
    return this.createEmbedIframe(embedUrl);
  }
}

export default MediaSite;