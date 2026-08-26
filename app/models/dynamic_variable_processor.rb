class DynamicVariableProcessor
  include DynamicVariable::Params

  TAGS = {
    "posts"              => DynamicVariable::PostsTag,
    "posts_by_year"      => DynamicVariable::PostsByYearTag,
    "tags"               => DynamicVariable::TagsTag,
    "table_of_contents"  => :render_table_of_contents_tag,
    "email_subscription" => DynamicVariable::EmailSubscriptionTag,
    "contact_form"       => DynamicVariable::ContactFormTag,
    "search"             => DynamicVariable::SearchTag,
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
    # The placeholder carries a per-run nonce so a post containing the literal
    # placeholder text cannot collide with it.
    nonce = SecureRandom.hex(8)

    code_blocks = []
    protected_content = content.gsub(%r{<(pre|code)[^>]*>.*?</\1>}m) do |match|
      code_blocks << match
      "___CODE_BLOCK_#{nonce}_#{code_blocks.length - 1}___"
    end

    processed = protected_content.gsub(tag_pattern) do
      render_tag($1, $2.strip)
    end

    code_blocks.each_with_index do |block, i|
      # Block form, so backreference sequences in code content stay literal.
      processed = processed.sub("___CODE_BLOCK_#{nonce}_#{i}___") { block }
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
      # The page still renders, minus the tag, but the failure is a real error:
      # silent empty output is how a broken tag goes unnoticed for months.
      Sentry.capture_exception(e, extra: { tag: tag_name, post_id: @post.id }) if Sentry.initialized?
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

    def render_table_of_contents_tag(params_string)
      DynamicVariable::TableOfContentsTag.new(post: @post, view: @view, params_string: params_string).render
    end
end
