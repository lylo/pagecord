module NavigationItem::IconSvg
  extend ActiveSupport::Concern

  MAX_SIZE = 4.kilobytes
  # Only an icon in this exact shape can be saved, so navigation_item_icon can render it with html_safe.
  FORMAT = %r{\A<svg viewBox="[\d.,\s-]+" fill="currentColor"><path d="[MmZzLlHhVvCcSsQqTtAaEe\d.,+\s-]+"/></svg>\z}

  included do
    attribute :use_icon, :boolean

    normalizes :icon_svg, with: ->(svg) { rebuild_icon_svg(svg.strip) }
    before_validation :clear_icon_svg, if: -> { use_icon == false }

    validates :icon_svg, allow_nil: true, length: { maximum: MAX_SIZE },
      format: { with: FORMAT, message: "must be an SVG with a viewBox and a single path, like the icons on Simple Icons and Phosphor" }
  end

  class_methods do
    private

      # A paste without a viewBox and exactly one path passes through untouched for the format validation to reject.
      def rebuild_icon_svg(svg)
        view_box = svg[/viewBox="([^"]*)"/i, 1]
        paths = svg.scan(/<path\b[^>]*\sd="([^"]*)"/i).flatten
        return svg.presence unless view_box && paths.one?

        %(<svg viewBox="#{view_box}" fill="currentColor"><path d="#{paths.first}"/></svg>)
      end
  end

  def label_hidden?
    icon_svg? && !show_label?
  end

  private

    def clear_icon_svg
      self.icon_svg = nil
    end
end
