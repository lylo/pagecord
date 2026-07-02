require "nokogiri"
require "open-uri"

module MediaEmbed
  module Providers
    class Bandcamp < Base
      REGEX = %r{\Ahttps://(?:bandcamp\.com|[^/]+\.bandcamp\.com)/.+}i

      def render(url)
        return unless url.match?(REGEX)

        embed_url = Rails.cache.fetch([ "bandcamp_embed", url ], expires_in: 7.days, race_condition_ttl: 10.seconds) do
          doc = Nokogiri::HTML(URI.open(url, open_timeout: 2, read_timeout: 3))
          doc.at("meta[property=\"og:video\"]")&.attr("content")
        end
        return if embed_url.blank?

        iframe(embed_url,
          width: "100%",
          height: "120",
          seamless: true,
          style: style("border: 0", "max-width: 660px", "margin-inline: auto"))
      rescue
        nil
      end
    end
  end
end
