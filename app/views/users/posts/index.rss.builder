xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title "Posts by #{@user.username}"
    xml.description "Latest posts by #{@user.username}"
    xml.link user_posts_url(@user.username)

    @posts.each do |post|
      link = if post.url_title.present?
        post_with_title_url(@user.username, post.url_title, post.url_id)
      else
        post_without_title_url(@user.username, post.url_id)
      end

      xml.item do
        xml.title post.title
        xml.description post.content
        xml.pubDate post.published_at.to_formatted_s(:rfc822)
        xml.link link
        xml.guid link
      end
    end
  end
end