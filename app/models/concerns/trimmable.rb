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
      rich_text_association.name.to_s.gsub(/^rich_text_/, '') if rich_text_association
    end
  end

  def trim_rich_text
    rich_text_attribute = self.class.rich_text_attribute_name
    if rich_text_attribute.present?
      if send(rich_text_attribute).body.present?
        doc = remove_trailing_empty_nodes(send(rich_text_attribute).body.to_s)
        send(rich_text_attribute).body = doc
      end
    end
  end

  private

    def remove_trailing_empty_nodes(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)

      nodes = []
      doc.traverse do |node|
        if node.text? || node.element?
          nodes << node
        end
      end
      nodes.reverse!

      nodes.each_with_index do |node, index|
        empty_nodes_to_remove = %w[p br div]
        if node.text? && node.content.strip.empty?
          node.remove
        elsif empty_nodes_to_remove.include?(node.name) && node.element? && node.children.empty?
          node.remove
        else
          break
        end
      end

      doc
    end
end