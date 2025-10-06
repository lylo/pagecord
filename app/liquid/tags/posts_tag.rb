module Tags
  class PostsTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      @markup = markup.strip
    end

    def render(context)
      params = parse_params(@markup)

      relation = context.registers[:posts_relation]
      return "" unless relation

      # Apply tag filter if specified
      relation = relation.tagged_with(params[:tag]) if params[:tag]

      # Apply year filter if specified
      if params[:year]
        start_date = Date.new(params[:year], 1, 1)
        end_date = Date.new(params[:year], 12, 31).end_of_day
        relation = relation.where(published_at: start_date..end_date)
      end

      posts = params[:limit] ? relation.limit(params[:limit]) : relation.all

      # Render the partial
      view = context.registers[:view]
      view.render(partial: "blogs/liquid/posts", locals: { posts: posts })
    rescue => e
      Rails.logger.error("PostsTag error: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
      raise
    end

    private

      def parse_params(markup)
        params = {}

        # Parse limit: 5
        if markup =~ /limit:\s*(\d+)/
          params[:limit] = $1.to_i
        end

        # Parse tag: "ruby"
        if markup =~ /tag:\s*["']([^"']+)["']/
          params[:tag] = $1
        end

        # Parse year: 2025
        if markup =~ /year:\s*(\d{4})/
          params[:year] = $1.to_i
        end

        params
      end
  end
end
