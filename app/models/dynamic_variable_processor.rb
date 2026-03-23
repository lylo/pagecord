class DynamicVariableProcessor
  TAGS = {
    "posts"              => DynamicVariable::PostsTag,
    "posts_by_year"      => DynamicVariable::PostsByYearTag,
    "tags"               => DynamicVariable::TagsTag,
    "email_subscription" => DynamicVariable::EmailSubscriptionTag,
    "contact_form"       => DynamicVariable::ContactFormTag
  }.freeze

  def initialize(blog:, view:)
    @blog = blog
    @view = view
  end

  def process(content)
    code_blocks = []
    protected_content = content.gsub(%r{<(pre|code)[^>]*>.*?</\1>}m) do |match|
      code_blocks << match
      "___CODE_BLOCK_#{code_blocks.length - 1}___"
    end

    result = +""
    remaining_content = protected_content

    while (match = remaining_content.match(tag_pattern))
      result << wrap_content(match.pre_match)
      result << render_tag(match[1], match[2].strip)
      remaining_content = match.post_match
    end

    result << wrap_content(remaining_content)
    processed = result.presence || wrap_content("")

    code_blocks.each_with_index do |block, i|
      processed = processed.sub("___CODE_BLOCK_#{i}___", block)
    end

    processed
  end

  private

    def tag_pattern
      /\{\{\s*(\w+)([^}]*)\}\}/
    end

    def render_tag(tag_name, params_string)
      if (tag_class = TAGS[tag_name])
        tag_class.new(blog: @blog, view: @view, params_string: params_string).render
      else
        unknown_tag = "#{tag_name} #{params_string}".strip
        wrap_content("{{ #{unknown_tag} }}")
      end
    rescue
      ""
    end

    def wrap_content(content)
      return "" if content.blank?

      @view.render(partial: "blogs/posts/page_content", locals: { content: content })
    end
end
