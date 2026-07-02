module MediaEmbed
  module Providers
    class AppleMusic < Base
      REGEX = %r{\Ahttps://(?:music|podcasts)\.apple\.com/([a-z]{2})/(album|song|playlist|podcast)/[^/]+/(?:id)?([0-9]+)(\?i=[0-9]+)?}i

      def render(url)
        match = url.match(REGEX)
        return unless match

        country, type, id, track_id = match.captures
        embed_url = "https://embed.music.apple.com/#{country}/#{type}/#{id}#{track_id}"
        is_track = track_id.present? || type == "song"

        iframe(embed_url,
          width: "100%",
          height: is_track ? "175" : "450",
          allow: "autoplay *; encrypted-media *; fullscreen *",
          style: style("border-radius: 12px", "border: 0", "max-width: 660px", "margin-inline: auto"))
      end
    end
  end
end
