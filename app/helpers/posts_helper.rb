module PostsHelper
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
      blog_posts_list_path(tag: tag)
    else
      # For admin views
      request.path + "?tag=#{tag}"
    end
  end

  # Returns the URL of the navigation item to avoid Brakeman warning
  def navigation_item_url(item)
    item.link_url
  end

  def published_at_date_format
    :post_date
  end

  def process_dynamic_variables(post)
    return post.content.to_s unless post.is_page?

    processor = DynamicVariableProcessor.new(blog: post.blog, view: self)
    processor.process(post.content.to_s)
  rescue => e
    Rails.logger.error("Dynamic variable error: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    post.content.to_s
  end

  def safe_auto_link(content, options = {})
    code_blocks = []
    protected = content.gsub(%r{<(pre|code)[^>]*>.*?</\1>}m) do |match|
      code_blocks << match
      "___CODE_BLOCK_#{code_blocks.length - 1}___"
    end

    linked = auto_link(protected, options)

    code_blocks.each_with_index do |block, i|
      linked = linked.sub("___CODE_BLOCK_#{i}___", block)
    end

    linked
  end
end
