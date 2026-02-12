class DynamicVariableProcessor
  RENDERERS = {
    "posts" => :render_posts_tag,
    "posts_by_year" => :render_posts_by_year_tag,
    "tags" => :render_tags_tag,
    "email_subscription" => :render_email_subscription_tag
  }.freeze

  attr_reader :blog, :view

  def initialize(blog:, view:)
    @blog = blog
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
      order_direction = params[:sort] == "asc" ? :asc : :desc
      relation = blog.posts.visible.order(published_at: order_direction)
      relation = relation.tagged_with_any(*Array(params[:tag])) if params[:tag]

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
      order_direction = params[:sort] == "asc" ? :asc : :desc
      relation = blog.posts.visible.order(published_at: order_direction)
      relation = relation.tagged_with_any(*Array(params[:tag])) if params[:tag]

      posts = relation.all

      view.render(partial: "blogs/custom_tags/posts_by_year", locals: { posts: posts })
    end

    def render_tags_tag(params_string)
      params = parse_params(params_string)
      tags = blog.posts.visible.all_tags
      partial = params[:style] == "inline" ? "blogs/custom_tags/tags_inline" : "blogs/custom_tags/tags"
      view.render(partial: partial, locals: { tags: tags, blog: blog })
    end

    def render_email_subscription_tag(params_string)
      view.render(partial: "blogs/email_subscriber_form", locals: {})
    end

    def parse_params(params_string)
      params = {}
      return params if params_string.blank?

      # Split by pipe, each part is a parameter
      params_string.split("|").each do |param|
        param = param.strip
        next if param.blank?

        # Split on first colon to get key and value
        key, value = param.split(":", 2).map(&:strip)
        next if key.blank? || value.blank?

        # Remove quotes if present
        value = value[1..-2] if value.start_with?('"', "'") && value.end_with?('"', "'")

        # Handle comma-separated values (only for 'tag' parameter)
        if key == "tag" && value.include?(",")
          value = value.split(",").map(&:strip)
        end

        # Convert to appropriate type
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
