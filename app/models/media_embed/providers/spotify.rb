module MediaEmbed
  module Providers
    class Spotify < Base
      REGEX = %r{\Ahttps://open\.spotify\.com/(track|album|artist|playlist|episode|show)/([a-zA-Z0-9]+)}i

      def render(url)
        match = url.match(REGEX)
        return unless match

        type, id = match.captures
        embed_url = "https://open.spotify.com/embed/#{type}/#{id}?utm_source=generator&theme=0"

        iframe(embed_url,
          width: "100%",
          height: type == "album" ? "450" : "152",
          allow: "autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture",
          style: style("border-radius: 12px", "max-width: 660px", "margin-inline: auto"))
      end
    end
  end
end
