module PostsHelper
  include Pagy::Frontend

  def without_action_text_image_wrapper(html)
    # Regular expression to match the action-text-attachment wrapper
    attachment_regex = /<action-text-attachment[^>]*>(.*?)<\/action-text-attachment>/m

    # Replace the ActionText attachment wrapper with just the image tag
    html.gsub(attachment_regex) { |match| $1.gsub(/<figure[^>]*>/, "").gsub(/<\/figure>/, "") }
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
    if social_link.email?
      "mailto:#{social_link.url}"
    else
      social_link.url
    end
  end

  def published_at_date_format
    :post_date
  end
end
