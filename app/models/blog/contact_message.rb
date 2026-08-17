class Blog::ContactMessage < ApplicationRecord
  include SpamCheckable

  self.table_name = "contact_messages"

  belongs_to :blog

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, presence: true, length: { maximum: 8.kilobytes }

  def spam_check_url
    "https://#{blog.host}"
  end
end
