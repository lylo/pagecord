class Mcp::Tools::GetPageMarkup < Mcp::Tool
  REPEATS_SHOWN = 3
  TEXT_LIMIT = 80
  ATTRIBUTE_LIMIT = 120

  describe "Get the rendered HTML body of a blog page, to write CSS against the real markup. home is the blog's front page " \
    "(its post list in the chosen layout, or its home page). Without a slug, post is the newest post and page the newest page. " \
    "Scripts, styles and SVG paths are removed, long text is cut short, and after #{REPEATS_SHOWN} similar siblings the rest " \
    "are replaced by a comment. Also returns the stylesheets the page loads, in order; custom CSS comes after them.",
    properties: {
      page_type: { type: "string", enum: %w[ home post page ], default: "home" },
      slug: { type: "string", description: "The post or page slug, from list_posts." }
    },
    read_only: true

  def self.perform(blog, page_type: "home", slug: nil)
    url = page_type == "home" ? blog_home_url(blog) : published_post_url(find_published(blog, page_type == "page", slug))
    status, headers, html = render_page(blog, url)
    document = Nokogiri::HTML5(html)

    {
      url: url,
      status: status,
      location: headers["location"],
      stylesheets: document.css("link[rel=stylesheet]").map { URI.join(url, it[:href]).to_s },
      html: outline(document.at("body"))
    }.compact
  end

  class << self
    private
      def find_published(blog, is_page, slug)
        posts = blog.all_posts.kept.published.released.where(is_page: is_page)
        slug ? posts.find_by!(slug: slug) : posts.order(published_at: :desc).first!
      end

      # The router, not the app, so the executor middleware doesn't reset Current mid-request.
      def render_page(blog, url)
        env = Rack::MockRequest.env_for(url, "action_dispatch.remote_ip" => "mcp-#{blog.id}", Blogs::AccessControl::OWNER_RENDER_KEY => blog.id)
          .merge(Rails.application.env_config)
        status, headers, body = I18n.with_locale(I18n.locale) { Rails.application.routes.call(env) }

        html = +""
        body.each { html << it }
        body.close if body.respond_to?(:close)

        [ status, headers, html ]
      end

      def outline(body)
        return "" unless body

        body.css("script, style, template, noscript").remove
        body.css("svg").each { it.children.remove }
        body.xpath(".//text()").each { it.content = it.content.truncate(TEXT_LIMIT) unless it.blank? }
        body.css("*").each { |element| element.attribute_nodes.each { it.value = it.value.truncate(ATTRIBUTE_LIMIT) } }
        shorten_repeats(body)

        body.to_html.gsub(/^\s*\n/, "")
      end

      def shorten_repeats(element)
        element.element_children.group_by { [ it.name, it[:class] ] }.each do |(name, classes), siblings|
          extras = siblings.drop(REPEATS_SHOWN)
          next if extras.empty?

          selector = [ name, *classes&.split ].join(".")
          extras.first.add_previous_sibling(Nokogiri::XML::Comment.new(element.document, " #{extras.size} more #{selector} "))
          extras.each(&:remove)
        end

        element.element_children.each { shorten_repeats(it) }
      end
  end
end
