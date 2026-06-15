module MediaEmbed
  module Providers
    class Base
      def initialize(view:)
        @view = view
      end

      private

        def iframe(src, **attributes)
          @view.tag.iframe(**attributes.reverse_merge(src: src, loading: "lazy"))
        end

        def style(*rules)
          rules.compact.join("; ")
        end
    end
  end
end
