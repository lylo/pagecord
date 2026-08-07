module PostsHelper
  def strip_video_tags(html)
    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    doc.css("figure").each do |figure|
      figure.remove if figure.at_css("video")
    end
    doc.to_html
  end

  def tag_filter_url(tag)
    if @blog
      # For public blog views
      @blog.posts_list_path(tag: tag)
    else
      # For admin views
      request.path + "?tag=#{tag}"
    end
  end

  # Returns the URL of the navigation item to avoid Brakeman warning
  def navigation_item_url(item)
    item.link_url
  end

  def filter_description
    parts = []
    parts << "tagged with <strong>#{h @current_tags.join(", ")}</strong>" if @current_tags.present?
    parts << (params[:title] == "true" ? "with titles" : "without titles") if params[:title].present?
    parts << "in <strong>#{h Post.locale_name(@current_lang)}</strong>" if @current_lang.present?
    safe_join([ "Posts ", parts.join(", ").html_safe ])
  end

  def post_tag_data(post)
    { tags: post.tag_list.join(" ") } if post.tag_list.present?
  end

  def post_thumbnail(post)
    if post.open_graph_image.attached?
      post.open_graph_image
    elsif post.first_image.present?
      post.first_image
    end
  end

  def published_at_date_format
    :post_date
  end

  def render_post_content(post)
    content = process_dynamic_variables(post)
    content = Html::StripActionTextAttachments.new.transform(content)
    content = process_blog_links(content, post.blog)
    ExcerptBreak.strip(content).html_safe
  end

  def render_post_excerpt(post)
    content = Html::StripActionTextAttachments.new.transform(post.excerpt_html)
    content = Html::StripFootnotes.new.transform(content)
    process_blog_links(content, post.blog).html_safe
  end

  def render_digest_post_content(post)
    content = Html::StripActionTextAttachments.new.transform(post.content.to_s)
    content = ExcerptBreak.strip(content)
    content = Html::EmailMediaPreview.new.transform(content)
    strip_video_tags(content).html_safe
  end

  def process_dynamic_variables(post)
    return post.content.to_s unless post.is_page?

    processor = DynamicVariableProcessor.new(post: post, view: self)
    processor.process(post.content.to_s)
  rescue StandardError => e
    Rails.logger.error "Dynamic variable processing failed for post #{post.id}: #{e.class}: #{e.message}"
    post.content.to_s
  end

  private

    def safe_auto_link(content, options = {})
      # The placeholder carries a per-run nonce so post text containing the
      # literal placeholder cannot collide with it.
      nonce = SecureRandom.hex(8)

      code_blocks = []
      protected = content.gsub(%r{<(pre|code)[^>]*>.*?</\1>}m) do |match|
        code_blocks << match
        "___CODE_BLOCK_#{nonce}_#{code_blocks.length - 1}___"
      end

      linked = auto_link(protected, options)

      code_blocks.each_with_index do |block, i|
        # Block form, so backreference sequences in code content stay literal.
        linked = linked.sub("___CODE_BLOCK_#{nonce}_#{i}___") { block }
      end

      linked
    end

    def process_blog_links(content, blog)
      content = safe_auto_link(content, sanitize: false)
      content = Html::ExternalLinksInNewTab.new(blog).transform(content) if blog.external_links_in_new_tab?
      content
    end
end
