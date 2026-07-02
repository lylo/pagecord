module MediaEmbed
  module Providers
    class Transistor < Base
      REGEX = %r{\Ahttps://share\.transistor\.fm/[se]/([a-zA-Z0-9-]+)(?:/(latest|playlist|[a-zA-Z0-9-]+))?}i

      def render(url)
        match = url.match(REGEX)
        return unless match

        show_slug, episode_or_type = match.captures
        embed_url = "https://share.transistor.fm/e/#{show_slug}"
        embed_url += "/#{episode_or_type}" if episode_or_type.present?

        iframe("#{embed_url}?color=444444&background=ffffff",
          width: "100%",
          height: episode_or_type == "playlist" ? "390" : "180",
          seamless: true,
          style: "border: none")
      end
    end
  end
end
