module CustomDomain
  extend ActiveSupport::Concern

  included do
    has_many :custom_domain_changes, dependent: :destroy

    before_save :normalize_custom_domain
    after_update :record_custom_domain_change

    validates :custom_domain, uniqueness: true, allow_blank: true, format: { with: /\A(?!:\/\/)([a-zA-Z0-9](?:[a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,63}\z/ }

    validate :restricted_domain
  end

  def domain_changed?
    # we don't want a nil to "" to be considered a domain change
    nil_to_blank_change = (custom_domain_previously_was.nil? && custom_domain.blank?) ||
      (custom_domain_previously_was.blank? && custom_domain.nil?)

    custom_domain_previously_changed? && !nil_to_blank_change
  end

  private

    def restricted_domain
      restricted_domains = %w[pagecord.com proxy.pagecord.com]

      if restricted_domains.include?(custom_domain)
        errors.add(:custom_domain, "is restricted")
      end
    end

    def record_custom_domain_change
      if domain_changed?
        self.custom_domain_changes.create!(custom_domain: custom_domain)
      end
    end

    def normalize_custom_domain
      self.custom_domain = nil if custom_domain.blank?
    end
end
