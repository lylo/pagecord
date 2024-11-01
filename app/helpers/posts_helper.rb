module PostsHelper
  include Pagy::Frontend

  def without_action_text_image_wrapper(html)
    # Regular expression to match the action-text-attachment wrapper
    attachment_regex = /<action-text-attachment[^>]*>(.*?)<\/action-text-attachment>/m

    # Replace the ActionText attachment wrapper with just the image tag
    html.gsub(attachment_regex) { |match| $1.gsub(/<figure[^>]*>/, "").gsub(/<\/figure>/, "") }
  end
end
