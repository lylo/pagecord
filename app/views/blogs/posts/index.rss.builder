xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title "#{@blog.display_name}"
    xml.description "Latest posts from #{@blog.display_name}"
    xml.link blog_home_url(@blog)

    @posts.each do |post|
      link = post_url(post)
      publication_time = post.published_at.in_time_zone(@blog.user.timezone || "UTC")

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
      end
    end
  end
end
