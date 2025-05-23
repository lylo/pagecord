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
        doc = trim(send(rich_text_attribute).body.to_s)
        send(rich_text_attribute).body = doc
      end
    end
  end

  private

    def trim(html)
      document = Nokogiri::HTML.fragment(html)

      remove_trailing_empty_nodes(document)

      document.to_html
    end

    def remove_trailing_empty_nodes(node)
      # Traverse the node's children in reverse
      while node.children.any?
        last_child = node.children.last

        if last_child.text? && last_child.text.strip.empty?
          last_child.remove # Remove empty text nodes
        elsif last_child.element?
          if last_child.name == "br" ||
             ([ "div", "p" ].include?(last_child.name) && last_child.children.empty? && last_child.text.strip.empty?)

            last_child.remove  # Remove <br> tags or empty <div>/<p> elements
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
