module MediaEmbed
  module Providers
    class Strava < Base
      REGEX = %r{\Ahttps://www\.strava\.com/activities/([0-9]+)}i

      def render(url)
        match = url.match(REGEX)
        return unless match

        placeholder = @view.tag.div(
          "",
          class: "strava-embed-placeholder",
          data: { embed_type: "activity", embed_id: match[1], style: "standard", from_embed: "false" }
        )
        script = @view.content_tag(:script, "", src: "https://strava-embeds.com/embed.js")

        @view.tag.div(@view.safe_join([ placeholder, script ]), style: "display: flex; justify-content: center")
      end
    end
  end
end
