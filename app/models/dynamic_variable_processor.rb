class DynamicVariableProcessor
  include DynamicVariable::Params

  TAGS = {
    "posts"              => DynamicVariable::PostsTag,
    "posts_by_year"      => DynamicVariable::PostsByYearTag,
    "tags"               => DynamicVariable::TagsTag,
    "email_subscription" => DynamicVariable::EmailSubscriptionTag,
    "contact_form"       => DynamicVariable::ContactFormTag,
    "updated_at"         => :render_updated_at_tag
  }.freeze

  UPDATED_AT_FORMATS = {
    "long"          => "%d %B %Y",
    "long_datetime" => "%d %B %Y %H:%M",
    "dd_mm_yyyy"    => "%d/%m/%Y",
    "mm_dd_yyyy"    => "%m/%d/%Y",
    "yyyy_mm_dd"    => "%Y-%m-%d"
  }.freeze

  def initialize(post:, view:)
    @post = post
    @blog = post.blog
    @view = view
  end

  def process(content)
    code_blocks = []
    protected_content = content.gsub(%r{<(pre|code)[^>]*>.*?</\1>}m) do |match|
      code_blocks << match
      "___CODE_BLOCK_#{code_blocks.length - 1}___"
    end

    processed = protected_content.gsub(tag_pattern) do
      render_tag($1, $2.strip)
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
      if (tag_handler = TAGS[tag_name])
        tag_handler.is_a?(Symbol) ? send(tag_handler, params_string) : tag_handler.new(blog: @blog, view: @view, params_string: params_string).render
      else
        unknown_tag = "#{tag_name} #{params_string}".strip
        "{{ #{unknown_tag} }}"
      end
    rescue StandardError => e
      Rails.logger.error(
        "[DynamicVariableProcessor] Failed to render #{tag_name} " \
        "for post #{@post.id}: #{e.class} - #{e.message}"
      )
      ""
    end

    def render_updated_at_tag(params_string)
      params = parse_params(params_string)
      format = if params[:format] == "datetime"
        "#{I18n.t("date.formats.post_date", locale: @blog.locale)} %H:%M"
      else
        UPDATED_AT_FORMATS[params[:format]] || :post_date
      end

      @view.local_time(@post.updated_at, format: format, class: "updated-at")
    end

end
