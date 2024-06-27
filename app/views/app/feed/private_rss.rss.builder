xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title "Pagecord feed for @#{@user.username}"
    xml.description "All the latest articles from the Pagecords you're following"
    xml.link app_feed_url

    @posts.each do |post|
      link = post_url(post)

      xml.item do
        if post.title.blank?
          xml.title "@#{post.user.username} - #{post.published_at.to_formatted_s(:long)}"
        else
          xml.title "@#{post.user.username} - #{post.title}"
        end
        xml.description do
          if post.html?
            xml.cdata! without_action_text_image_wrapper(post.content.to_s)
          else
            xml.cdata! simple_format(auto_link post.content)
          end
        end
        xml.pubDate post.published_at.to_formatted_s(:rfc822)
        xml.link link
        xml.guid link
      end
    end
  end
end