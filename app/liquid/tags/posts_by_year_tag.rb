module Tags
  class PostsByYearTag < Liquid::Tag
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

      posts = relation.all

      # Render the partial
      view = context.registers[:view]
      view.render(partial: "blogs/liquid/posts_by_year", locals: { posts: posts })
    rescue => e
      Rails.logger.error("PostsByYearTag error: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
      raise
    end

    private

      def parse_params(markup)
        params = {}

        # Parse tag: "ruby"
        if markup =~ /tag:\s*["']([^"']+)["']/
          params[:tag] = $1
        end

        params
      end
  end
end
