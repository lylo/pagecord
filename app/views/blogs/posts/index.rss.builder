xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title "#{@blog.display_name}"
    xml.description "Latest posts from #{@blog.display_name}"
    xml.link blog_home_url(@blog)

    @posts.each do |post|
      link = post_url(post)

      xml.item do
        if post.title.blank?
          xml.title "#{@blog.display_name} - #{post.published_at.to_formatted_s(:long)}"
        else
          xml.title post.title
        end
        xml.description do
          xml.cdata! without_action_text_image_wrapper(post.content.to_s)
        end
        xml.pubDate post.published_at.to_formatted_s(:rfc822)
        xml.link link
        xml.guid link
      end
    end
  end
end
