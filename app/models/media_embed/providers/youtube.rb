module MediaEmbed
  module Providers
    class Youtube < Base
      REGEX = %r{\A(?:https://(?:www\.)?youtube\.com/(?:watch\?v=|live/|shorts/)|https://youtu\.be/)([a-zA-Z0-9_-]+)}i

      def render(url)
        match = url.match(REGEX)
        return unless match

        iframe = iframe("https://www.youtube-nocookie.com/embed/#{match[1]}",
          allow: "autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture")

        @view.tag.div(iframe, class: "video-embed-container")
      end
    end
  end
end
