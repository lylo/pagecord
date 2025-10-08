class NavigationItem < ApplicationRecord
  belongs_to :blog
  belongs_to :post, optional: true

  validates :label, presence: true

  scope :ordered, -> { order(:position, :id) }
  scope :social_links, -> { where(type: "SocialNavigationItem") }

  def link_url
    raise NotImplementedError, "Subclass must implement link_url"
  end

  def reorder(new_position)
    old_position = position

    update_column(:position, -1)

    if new_position > old_position
      blog.navigation_items.where("position > ? AND position <= ?", old_position, new_position)
           .update_all("position = position - 1")
    elsif new_position < old_position
      blog.navigation_items.where("position >= ? AND position < ?", new_position, old_position)
           .update_all("position = position + 1")
    end

    update_column(:position, new_position)
  end
end
