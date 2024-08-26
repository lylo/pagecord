class MediaSite {
  constructor(regex, getEmbedUrl, createEmbedIframe) {
    this.regex = regex;
    this.getEmbedUrl = getEmbedUrl;
    this.createEmbedIframe = createEmbedIframe;
  }
}

export default MediaSite;