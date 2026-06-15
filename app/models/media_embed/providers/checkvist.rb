module MediaEmbed
  module Providers
    class Checkvist < Base
      REGEX = %r{\Ahttps://checkvist\.com/p/[a-zA-Z0-9]+}i

      def render(url)
        return unless url.match?(REGEX)

        iframe(url, width: "100%", height: "400")
      end
    end
  end
end
