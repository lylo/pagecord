module MediaEmbed
  module Providers
    class Image < Base
      REGEX = %r{\Ahttps?://.+\.(?:jpg|jpeg|png|gif|webp|svg|bmp|ico)(?:\?.*)?\z}i

      def render(url)
        return unless url.match?(REGEX)

        @view.image_tag(url, alt: "", loading: "lazy")
      end
    end
  end
end
