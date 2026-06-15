module MediaEmbed
  module Providers
    class Tidal < Base
      REGEX = %r{\Ahttps://tidal\.com/(?:playlist/([a-zA-Z0-9-]+)|(?:browse/)?(track|album)/([0-9]+))}i

      def render(url)
        match = url.match(REGEX)
        return unless match

        playlist_id, type, id = match.captures
        embed_url = if playlist_id
          "https://embed.tidal.com/playlists/#{playlist_id}"
        else
          "https://embed.tidal.com/#{type == "track" ? "tracks" : "albums"}/#{id}"
        end

        iframe(embed_url,
          height: tidal_height(embed_url),
          allow: "encrypted-media",
          sandbox: "allow-same-origin allow-scripts allow-forms allow-popups",
          title: "TIDAL Embed Player",
          style: style("display: block", "max-width: 660px", "margin-inline: auto"))
      end

      private

        def tidal_height(embed_url)
          return "600" if embed_url.include?("/playlists/")
          return "450" if embed_url.include?("/albums/")

          "120"
        end
    end
  end
end
