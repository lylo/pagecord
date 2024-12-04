xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title "Posts by @#{@blog.user.username}"
    xml.description "Latest posts by @#{@blog.user.username}"
    xml.link blog_home_url(@blog)

    @posts.each do |post|
      link = post_url(post)

      xml.item do
        if post.title.blank?
          xml.title "@#{@blog.user.username} - #{post.published_at.to_formatted_s(:long)}"
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
