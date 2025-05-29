xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title "Pagecord feed for @#{@user.blog.subdomain}"
    xml.description "All the latest articles from the Pagecords you're following"
    xml.link app_feed_url

    @posts.each do |post|
      link = post_url(post)

      xml.item do
        if post.title.blank?
          xml.title "#{post.blog.display_name} - #{post.published_at.to_formatted_s(:long)}"
        else
          xml.title "#{post.blog.display_name} - #{post.title}"
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
