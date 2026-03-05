module Blog::Contactable
  extend ActiveSupport::Concern

  included do
    has_many :contact_messages, class_name: "Blog::ContactMessage", dependent: :destroy
  end

  def contactable?
    Rails.features.for(blog: self).enabled?(:contact_form) && user.has_premium_access?
  end
end
