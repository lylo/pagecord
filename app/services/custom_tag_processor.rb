class CustomTagProcessor
  attr_reader :blog, :view

  def initialize(blog:, view:)
    @blog = blog
    @view = view
  end

  def process(content)
    content.gsub(tag_pattern) do
      tag_name = $1
      params_string = $2.strip

      render_tag(tag_name, params_string)
    end
  end

  private

    def tag_pattern
      /\{\{\s*(\w+)([^}]*)\}\}/
    end

    def render_tag(tag_name, params_string)
      case tag_name
      when "posts"
        render_posts_tag(params_string)
      when "posts_by_year"
        render_posts_by_year_tag(params_string)
      when "tags"
        render_tags_tag(params_string)
      when "email_subscription"
        render_email_subscription_tag(params_string)
      else
        unknown_tag = "#{tag_name} #{params_string}".strip
        "{{ #{unknown_tag} }}"
      end
    end

    def render_posts_tag(params_string)
      params = parse_params(params_string)
      relation = blog.posts.visible.order(published_at: :desc)
      relation = relation.tagged_with(params[:tag]) if params[:tag]

      if params[:year]
        start_date = Date.new(params[:year], 1, 1)
        end_date = Date.new(params[:year], 12, 31).end_of_day
        relation = relation.where(published_at: start_date..end_date)
      end

      posts = params[:limit] ? relation.limit(params[:limit]) : relation.all
      view.render(partial: "blogs/custom_tags/posts", locals: { posts: posts, limit: params[:limit] })
    end

    def render_posts_by_year_tag(params_string)
      params = parse_params(params_string)
      relation = blog.posts.visible.order(published_at: :desc)
      relation = relation.tagged_with(params[:tag]) if params[:tag]
      posts = relation.all

      view.render(partial: "blogs/custom_tags/posts_by_year", locals: { posts: posts })
    end

    def render_tags_tag(params_string)
      tags = blog.posts.visible.all_tags
      view.render(partial: "blogs/custom_tags/tags", locals: { tags: tags, blog: blog })
    end

    def render_email_subscription_tag(params_string)
      view.render(partial: "blogs/email_subscriber_form", locals: {})
    end

    def parse_params(params_string)
      params = {}

      # Match key: value or key: 'value' or key: "value"
      params_string.scan(/(\w+):\s*(?:'([^']*)'|"([^"]*)"|(\w+))/) do |key, single_quoted, double_quoted, unquoted|
        value = single_quoted || double_quoted || unquoted

        # Convert to appropriate type
        params[key.to_sym] = if value =~ /^\d+$/
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
