xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/" do
  xml.channel do
    xml.title "Pagecord Spotlight"
    xml.description "Trending posts from independent bloggers on Pagecord"
    xml.link spotlight_url

    @posts.each do |post|
      link = post_url(post)
      publication_time = post.published_at_in_user_timezone
      rendered_content = Html::StripActionTextAttachments.new.transform(post.content.to_s)
      rendered_content = ExcerptBreak.strip(rendered_content)

      xml.item do
        xml.title post.display_title
        xml.description do
          xml.cdata! rendered_content
        end

        xml.pubDate publication_time.to_formatted_s(:rfc822)
        xml.link link
        xml.guid link
        xml.dc :creator, post.blog.display_name
        xml.source post.blog.display_name, url: rss_feed_url(post.blog)

        post.tag_list.each do |tag|
          xml.category tag
        end
      end
    end
  end
end
