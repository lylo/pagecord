module Blog::Spotlit
  extend ActiveSupport::Concern

  included do
    has_one :spotlight_exclusion, dependent: :destroy, class_name: "Blog::SpotlightExclusion"

    scope :spotlit, -> {
      joins(:user)
        .where(allow_search_indexing: true)
        .where(users: { discarded_at: nil })
        .where.missing(:spotlight_exclusion)
    }
  end

  def spotlit?
    allow_search_indexing? && user.discarded_at.nil? && spotlight_exclusion.nil?
  end

  def exclude_from_spotlight
    create_spotlight_exclusion! unless spotlight_exclusion
  end

  def include_in_spotlight
    spotlight_exclusion&.destroy
  end
end
