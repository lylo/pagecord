module Blog::Spotlit
  extend ActiveSupport::Concern

  MINIMUM_ACCOUNT_AGE = 7.days

  included do
    has_one :spotlight_exclusion, dependent: :destroy, class_name: "Blog::SpotlightExclusion"

    scope :spotlit, -> {
      joins(:user)
        .where(allow_search_indexing: true)
        .where(users: { discarded_at: nil })
        .where("users.created_at <= ?", MINIMUM_ACCOUNT_AGE.ago)
        .where.missing(:spotlight_exclusion)
    }
  end

  def spotlit?
    allow_search_indexing? &&
      user.created_at <= MINIMUM_ACCOUNT_AGE.ago &&
      user.discarded_at.nil? &&
      spotlight_exclusion.nil?
  end

  def exclude_from_spotlight
    create_spotlight_exclusion! unless spotlight_exclusion
  end

  def include_in_spotlight
    spotlight_exclusion&.destroy
  end
end
