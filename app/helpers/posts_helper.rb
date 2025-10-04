module PostsHelper
  include Pagy::Frontend

  def without_action_text_image_wrapper(html)
    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    doc.css("action-text-attachment").each do |attachment|
      figure = attachment.at_css("figure")
      attachment.replace(figure) if figure
    end
    doc.to_html
  end

  def strip_video_tags(html)
    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    doc.css("figure").each do |figure|
      figure.remove if figure.at_css("video")
    end
    doc.to_html
  end

  # Generate URL for filtering posts by tag
  def tag_filter_url(tag)
    if @blog
      # For public blog views
      blog_home_path(@blog, tag: tag)
    else
      # For admin views
      request.path + "?tag=#{tag}"
    end
  end

  # Returns the URL of the social link to avoid Brakeman warning
  # This is fine since the URL is sanitized by the SocialLink model
  def social_link_url(social_link)
    # Hack to allow people to link to their own contact form and get
    # an email social link icon
    if social_link.email? && !social_link.url.starts_with?("http")
      "mailto:#{social_link.url}"
    else
      social_link.url
    end
  end

  def published_at_date_format
    :post_date
  end

  def process_liquid_tags(content, blog)
    template = Liquid::Template.parse(content.to_s, environment: BlogLiquid)

    template.registers[:blog] = blog
    template.registers[:view] = self
    template.registers[:posts_relation] = blog.posts.visible.order(published_at: :desc)

    template.render({})
  rescue Liquid::SyntaxError => e
    Rails.logger.error("Liquid syntax error: #{e.message}")
    content.to_s
  end
end
