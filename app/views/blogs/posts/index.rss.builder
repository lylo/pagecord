cache([@blog, @posts.maximum(:updated_at), @posts.count, @current_tag]) do
  xml.instruct! :xml, version: "1.0"
  xml.rss version: "2.0" do
    xml.channel do
      xml.title "#{@blog.display_name}"
      xml.description "Latest posts from #{@blog.display_name}"
      xml.link blog_home_url(@blog)

      @posts.each do |post|
        link = post_url(post)
        publication_time = post.published_at_in_user_timezone

        xml.item do
          if post.title.blank?
            xml.title "#{@blog.display_name} - #{publication_time.to_formatted_s(:long)}"
          else
            xml.title post.title
          end
          xml.description do
            xml.cdata! without_action_text_image_wrapper(post.content.to_s)
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
