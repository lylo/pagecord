class DynamicVariableProcessor
  RENDERERS = {
    "posts" => :render_posts_tag,
    "posts_by_year" => :render_posts_by_year_tag,
    "tags" => :render_tags_tag,
    "email_subscription" => :render_email_subscription_tag,
    "contact_form" => :render_contact_form_tag,
    "updated_at" => :render_updated_at_tag
  }.freeze

  attr_reader :blog, :view

  def initialize(view:, post:)
    @post = post
    @blog = post.blog
    @view = view
  end

  def process(content)
    # Protect code blocks from processing
    code_blocks = []
    protected_content = content.gsub(%r{<(pre|code)[^>]*>.*?</\1>}m) do |match|
      code_blocks << match
      "___CODE_BLOCK_#{code_blocks.length - 1}___"
    end

    # Process tags in the remaining content
    processed = protected_content.gsub(tag_pattern) do
      tag_name = $1
      params_string = $2.strip
      render_tag(tag_name, params_string)
    end

    # Restore code blocks
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
      if (renderer = RENDERERS[tag_name])
        send(renderer, params_string)
      else
        unknown_tag = "#{tag_name} #{params_string}".strip
        "{{ #{unknown_tag} }}"
      end
    end

    def render_posts_tag(params_string)
      params = parse_params(params_string)
      relation = filtered_posts(params)

      if params[:year]
        start_date = Date.new(params[:year], 1, 1)
        end_date = Date.new(params[:year], 12, 31).end_of_day
        relation = relation.where(published_at: start_date..end_date)
      end

      posts = params[:limit] ? relation.limit(params[:limit]) : relation.all
      view.render(partial: "blogs/custom_tags/posts", locals: { posts: posts })
    end

    def render_posts_by_year_tag(params_string)
      params = parse_params(params_string)
      posts = filtered_posts(params).all
      view.render(partial: "blogs/custom_tags/posts_by_year", locals: { posts: posts })
    end

    def filtered_posts(params)
      order_direction = params[:sort] == "asc" ? :asc : :desc
      relation = blog.posts.visible.order(published_at: order_direction)
      relation = relation.tagged_with_any(*Array(params[:tag])) if params[:tag]
      relation = relation.tagged_without_any(*Array(params[:without_tag])) if params[:without_tag]
      relation = relation.where.not(title: [ nil, "" ]) if params[:title] == true
      relation = relation.where(title: [ nil, "" ]) if params[:title] == false
      relation = relation.emailed if params[:emailed] == true
      relation = relation.not_emailed if params[:emailed] == false
      relation = filter_by_language(relation, params[:lang]) if params[:lang]
      relation
    end

    def render_tags_tag(params_string)
      params = parse_params(params_string)
      tags = blog.posts.visible.all_tags
      partial = params[:style] == "inline" ? "blogs/custom_tags/tags_inline" : "blogs/custom_tags/tags"
      view.render(partial: partial, locals: { tags: tags, blog: blog })
    end

    def render_email_subscription_tag(params_string)
      view.render(partial: "blogs/email_subscriber_form")
    end

    def render_contact_form_tag(params_string)
      return "" unless blog.contactable?

      view.render(partial: "blogs/contact_messages/form")
    end

    def render_updated_at_tag(params_string)
      params = parse_params(params_string)
      format = if params[:format] == "datetime"
        "#{I18n.t("date.formats.post_date", locale: @blog.locale)} %H:%M"
      else
        :post_date
      end
      view.local_time(@post.updated_at, format: format, class: "updated-at")
    end

    def filter_by_language(relation, lang)
      locale = lang.to_s.downcase.split("-").first
      if blog.locale == locale
        relation.where(locale: [ locale, nil ])
      else
        relation.where(locale: locale)
      end
    end

    def parse_params(params_string)
      params = {}
      return params if params_string.blank?

      params_string.split("|").each do |param|
        param = param.strip
        next if param.blank?

        key, value = param.split(":", 2).map(&:strip)
        next if key.blank? || value.blank?

        value = value[1..-2] if value.start_with?('"', "'") && value.end_with?('"', "'")

        if key.in?(%w[tag without_tag]) && value.include?(",")
          value = value.split(",").map(&:strip)
        end

        params[key.to_sym] = if value.is_a?(Array)
          value
        elsif value =~ /^\d+$/
          value.to_i
        elsif value == "true"
          true
        elsif value == "false"
          false
        else
          value
        end
      end

      params
    end
end
