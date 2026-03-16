cache([ @blog, @posts.map(&:id), @current_tags, params[:title], @current_lang ]) do
  xml.instruct! :xml, version: "1.0"
  xml.rss version: "2.0" do
    xml.channel do
      title_parts = []
      title_parts << @current_tags.join(", ") if @current_tags.present?
      title_parts << Post.locale_name(@current_lang) if @current_lang.present?
      xml.title title_parts.any? ? "#{@blog.display_name} - #{title_parts.join(" / ")}" : @blog.display_name
      xml.description @blog.bio.to_plain_text.presence || "Latest posts from #{@blog.display_name}"
      xml.link blog_home_url(@blog)

      @posts.each do |post|
        link = post_url(post)
        publication_time = post.published_at_in_user_timezone
        rendered_content = Html::StripActionTextAttachments.new.transform(post.content.to_s)

        xml.item do
          if post.title.blank?
            xml.title "#{@blog.display_name} - #{publication_time.to_formatted_s(:long)}"
          else
            xml.title post.title
          end
          xml.description do
            xml.cdata! rendered_content
          end

          xml.pubDate publication_time.to_formatted_s(:rfc822)
          xml.link link
          xml.guid link

          post.tag_list.each do |tag|
            xml.category tag
          end
        end
      end
    end
  end
end
