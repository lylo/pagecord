class OpenGraphImage < ApplicationRecord
  belongs_to :post

  def self.from_post(post)
    return if post.attachments.any? || post.content.body.attachments.select { |attachment| attachment.try(:image?) }.any?

    doc = Nokogiri::HTML(post.content.to_s)
    img_tags = doc.css("img")

    if img_tags.any?
      OpenGraphImage.new(post: post, url: img_tags.first["src"])
    end
  end
end
