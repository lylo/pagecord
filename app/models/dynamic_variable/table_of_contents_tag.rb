class DynamicVariable::TableOfContentsTag
  include DynamicVariable::Params

  HEADING_SELECTOR = "h2, h3, h4, h5, h6"

  def initialize(post:, view:, params_string:)
    @post = post
    @view = view
    @params = parse_params(params_string)
  end

  def render
    headings = Nokogiri::HTML::DocumentFragment.parse(@post.content.to_s).css(HEADING_SELECTOR).select do |heading|
      heading["id"].present? && heading.text.strip.present?
    end

    return "" if headings.empty?

    @view.render(partial: "blogs/custom_tags/table_of_contents", locals: { heading: @params[:heading], items: tree_for(headings) })
  end

  private

    def tree_for(headings)
      root = []
      stack = [ { level: 1, children: root } ]

      headings.each do |heading|
        item = {
          heading: heading,
          level: heading.name.delete_prefix("h").to_i,
          children: []
        }

        stack.pop while stack.last[:level] >= item[:level]
        stack.last[:children] << item
        stack << item
      end

      root
    end
end
