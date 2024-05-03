class OpenGraphImage < ApplicationRecord
  belongs_to :post

  def self.from_post(post)
    return if post.attachments.any?

    doc = Nokogiri::HTML(post.body.to_s)
    img_tags = doc.css("img")

    if img_tags.any?
      OpenGraphImage.new(post: post, url: img_tags.first["src"])
    end
  end
end
