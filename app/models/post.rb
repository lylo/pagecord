class Post < ApplicationRecord
  include OpaqueId

  belongs_to :user, inverse_of: nil

  has_one :open_graph_image, dependent: :destroy
  has_rich_text :body
  has_many_attached :attachments, dependent: :destroy

  before_create :set_published_at, :limit_content_size
  after_create  :detect_open_graph_image
  before_save   :trim_content

  validate :body_or_title

  def body_or_title
    errors.add(:base, "Either body or title must be present") unless body.body.present? || title.present?
  end

  private

    def set_published_at
      self.published_at ||= created_at
    end

    def limit_content_size
      self.body = body.to_s.slice(0, 64.kilobytes)
    end

    def detect_open_graph_image
      if Rails.env.production?
        GenerateOpenGraphImageJob.perform_later(self)
      else
        GenerateOpenGraphImageJob.perform_now(self)
      end
    end

    # Removes empty tags from the end of HTML content
    def trim_content
      if html? && body.present?
        doc = Nokogiri::HTML::DocumentFragment.parse(body.body.to_s)

        doc.children.reverse_each do |node|
          node.remove if node.text? && node.text.strip.empty?
          node.remove if node.element? && node.children.empty?
          break unless node.text.strip.empty? && node.children.empty?
        end

        body.body = doc.to_html
      end
    end
end
