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
      doc = Nokogiri::HTML::DocumentFragment.parse(html)

      # Process top-level nodes
      remove_trailing_empty_nodes(doc)

      # Process the last top-level element
      last_element = doc.children.last
      remove_trailing_empty_nodes(last_element) if last_element

      # Remove trailing empty top-level elements
      doc.children.reverse.each do |node|
        if node.element? && node.children.empty? && %w[p div].include?(node.name)
          node.remove
        else
          break
        end
      end

      doc
    end

    # Function to remove trailing empty nodes
    def remove_trailing_empty_nodes(element)
      nodes = element.children.reverse

      nodes.each do |node|
        if node.text? && node.content.strip.empty?
          node.remove
        elsif node.name == "br" && node.element?
          node.remove
        elsif node.element? && node.children.empty? && %w[p div].include?(node.name)
          node.remove
        else
          break
        end
      end
    end
end
