module Html
  class YoutubeEmailPreview
    YOUTUBE_REGEX = %r{\Ahttps://(?:www\.)?(?:youtube\.com/(?:watch\?v=|live/|shorts/)|youtu\.be/)([a-zA-Z0-9_-]+)}

    def preview_link(doc, url)
      video_id = youtube_video_id(url)
      thumbnail_link(doc, url, video_id) if video_id
    end

    private

      def youtube_video_id(url)
        url.match(YOUTUBE_REGEX)&.[](1)
      end

      def thumbnail_link(doc, url, video_id)
        link = Nokogiri::XML::Node.new("a", doc)
        link["href"] = url
        link["class"] = "email-media-preview"
        link.add_child(thumbnail_image(doc, video_id))
        link
      end

      def thumbnail_image(doc, video_id)
        image = Nokogiri::XML::Node.new("img", doc)
        image["src"] = "https://img.youtube.com/vi/#{video_id}/hqdefault.jpg"
        image["alt"] = "YouTube video thumbnail"
        image["style"] = "display:block;margin:0 auto;max-width:100%;height:auto;"
        image
      end
  end
end
