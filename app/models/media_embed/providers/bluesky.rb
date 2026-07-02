require "cgi"
require "json"
require "open-uri"

module MediaEmbed
  module Providers
    class Bluesky < Base
      REGEX = %r{\Ahttps://bsky\.app/profile/([^/]+)/post/([a-zA-Z0-9]+)}i

      def render(url)
        match = url.match(REGEX)
        return unless match

        identifier, rkey = match.captures
        identifier = resolve_identifier(identifier)
        return if identifier.blank?

        iframe("https://embed.bsky.app/embed/#{identifier}/app.bsky.feed.post/#{rkey}",
          width: "100%",
          height: "350",
          style: style("overflow: hidden", "border: 0", "border-radius: 12px", "max-width: 600px", "margin-inline: auto"))
      end

      private

        def resolve_identifier(identifier)
          return identifier if identifier.start_with?("did:")

          Rails.cache.fetch([ "bluesky_embed_did", identifier ], expires_in: 7.days, race_condition_ttl: 10.seconds) do
            response = URI.open(
              "https://public.api.bsky.app/xrpc/com.atproto.identity.resolveHandle?handle=#{CGI.escape(identifier)}",
              open_timeout: 2,
              read_timeout: 3
            )
            JSON.parse(response.read)["did"]
          end
        rescue
          nil
        end
    end
  end
end
