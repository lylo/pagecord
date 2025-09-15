module PostsHelper
  include Pagy::Frontend

  def without_action_text_image_wrapper(html)
    # Regular expression to match the action-text-attachment wrapper
    attachment_regex = /<action-text-attachment[^>]*>(.*?)<\/action-text-attachment>/m

    # Replace the ActionText attachment wrapper with its inner HTML (preserving <figure>)
    html.gsub(attachment_regex) { |match| $1 }
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
end
