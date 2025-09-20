module Trimmable
  extend ActiveSupport::Concern

  included do
    before_save :trim_rich_text
  end

  class_methods do
    def rich_text_attribute_name
      rich_text_association = reflect_on_all_associations.find do |association|
        association.name.to_s.start_with?("rich_text_")
      end
      rich_text_association.name.to_s.gsub(/^rich_text_/, "") if rich_text_association
    end
  end

  def trim_rich_text
    rich_text_attribute = self.class.rich_text_attribute_name
    if rich_text_attribute.present?
      if send(rich_text_attribute).body.present?
        doc = trim(send(rich_text_attribute).body.to_html)
        send("#{rich_text_attribute}=", doc)  # just assign the string
      end
    end
  end

  private

    def trim(html)
      document = Nokogiri::HTML.fragment(html)

      remove_trailing_empty_nodes(document)

      document.to_html(save_with: Nokogiri::XML::Node::SaveOptions::AS_HTML)
    end

    def remove_trailing_empty_nodes(node)
      # Traverse the node's children in reverse
      while node.children.any?
        last_child = node.children.last

        if last_child.text? && last_child.text.gsub(/\u00A0/, "").strip.empty?
          last_child.remove # Remove empty text nodes (including non-breaking spaces)
        elsif last_child.element?
          if last_child.name == "br"
            last_child.remove  # Remove <br> tags
          elsif [ "div", "p" ].include?(last_child.name)
            # First clean up inside this element
            remove_trailing_empty_nodes(last_child)

            # Then check if it became empty after cleanup and remove it
            if last_child.children.empty? && last_child.text.gsub(/\u00A0/, "").strip.empty?
              last_child.remove
            else
              # Stop if the element has content
              break
            end
          else
            remove_trailing_empty_nodes(last_child)

            # Stop if the child was not completely removed
            break if node.children.last == last_child
          end
        else
          break
        end
      end
    end
end
