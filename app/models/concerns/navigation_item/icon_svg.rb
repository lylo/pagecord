module NavigationItem::IconSvg
  extend ActiveSupport::Concern

  MAX_SIZE = 8.kilobytes
  ELEMENTS = %w[ svg g path circle ellipse line polyline polygon rect ].freeze
  ATTRIBUTES = %w[ viewBox d cx cy r rx ry x y x1 y1 x2 y2 width height points transform
                   fill fill-rule fill-opacity opacity
                   stroke stroke-width stroke-linecap stroke-linejoin stroke-miterlimit stroke-opacity ].freeze

  included do
    attribute :use_icon, :boolean

    normalizes :icon_svg, with: ->(svg) { clean_icon_svg(svg.strip) }
    before_validation :clear_icon_svg, if: -> { use_icon == false }

    validates :icon_svg, length: { maximum: MAX_SIZE }
    validate :icon_svg_has_view_box, if: :icon_svg?
  end

  class_methods do
    private

      # A non-SVG passes through untouched for validation to reject.
      def clean_icon_svg(svg)
        document = Nokogiri::XML(svg)
        root = document.root
        return svg.presence unless root&.name == "svg"

        document.internal_subset&.remove
        document.remove_namespaces!
        root.xpath(".//node()").each do |node|
          node.element? && ELEMENTS.include?(node.name) ? clean_icon_svg_attributes(node) : node.remove
        end

        clean_icon_svg_attributes(root)
        root.remove_attribute("width")
        root.remove_attribute("height")
        root["fill"] ||= "currentColor"
        root.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
      end

      def clean_icon_svg_attributes(element)
        element.attribute_nodes.each do |attribute|
          if ATTRIBUTES.exclude?(attribute.name)
            attribute.remove
          elsif attribute.name.in?(%w[ fill stroke ]) && attribute.value != "none"
            attribute.value = "currentColor"
          end
        end
      end
  end

  def label_hidden?
    icon_svg? && !show_label?
  end

  private

    def clear_icon_svg
      self.icon_svg = nil
    end

    def icon_svg_has_view_box
      root = Nokogiri::XML(icon_svg).root
      errors.add(:icon_svg, "must be an SVG with a viewBox") unless root&.name == "svg" && root["viewBox"]
    end
end
