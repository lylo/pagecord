class DynamicVariableProcessor
  TAGS = {
    "posts"              => DynamicVariable::PostsTag,
    "posts_by_year"      => DynamicVariable::PostsByYearTag,
    "tags"               => DynamicVariable::TagsTag,
    "email_subscription" => DynamicVariable::EmailSubscriptionTag,
    "contact_form"       => DynamicVariable::ContactFormTag
  }.freeze

  LEXXY_CONTENT_OPEN = '<div class="lexxy-content e-content" data-controller="syntax-highlight">'
  LEXXY_CONTENT_CLOSE = "</div>"

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

    processed = protected_content.gsub(tag_pattern) do
      tag_name = $1
      params_string = $2.strip
      render_tag(tag_name, params_string)
    end

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
        output = tag_class.new(blog: @blog, view: @view, params_string: params_string).render
        "#{LEXXY_CONTENT_CLOSE}#{output}#{LEXXY_CONTENT_OPEN}"
      else
        unknown_tag = "#{tag_name} #{params_string}".strip
        "{{ #{unknown_tag} }}"
      end
    end
end
