module Html
  class YoutubeEmailPreview
    YOUTUBE_REGEX = %r{\Ahttps://(?:www\.)?(?:youtube\.com/(?:watch\?v=|live/|shorts/)|youtu\.be/)([a-zA-Z0-9_-]+)}

    def thumbnail_url(url)
      video_id = url.match(YOUTUBE_REGEX)&.[](1)
      "https://img.youtube.com/vi/#{video_id}/hqdefault.jpg" if video_id
    end
  end
end
