class Post::Reply < ApplicationRecord
  include SpamCheckable

  self.table_name = "post_replies"

  belongs_to :post

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :subject, presence: true
  validates :message, presence: true, length: { maximum: 8.kilobytes }

  scope :recent, -> { order(created_at: :desc) }

  def display_name
    "Reply from #{name}"
  end

  def spam_check_url
    "https://#{post.blog.host}/#{post.slug}"
  end
end
