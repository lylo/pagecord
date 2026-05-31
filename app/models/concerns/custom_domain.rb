module CustomDomain
  extend ActiveSupport::Concern

  included do
    has_many :custom_domain_changes, dependent: :destroy

    before_validation :normalize_custom_domain
    after_update :record_custom_domain_change

    validates :custom_domain, uniqueness: true, allow_blank: true, format: { with: /\A(?!:\/\/)([a-zA-Z0-9](?:[a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,63}\z/ }

    validate :restricted_domain
  end

  class_methods do
    # Look up the configured custom domain, treating apex and www as variants of
    # the same customer domain so Rails can redirect to the canonical stored value.
    def find_by_domain_with_www_fallback(domain)
      return unless domain.present?

      variant = www_variant(domain)

      find_by(custom_domain: domain) || (find_by(custom_domain: variant) if variant.present?)
    end

    # Hostnames that must exist at the edge for this custom domain to preserve
    # the existing apex/www redirect behaviour.
    def custom_domain_hostnames(domain)
      domain = domain.to_s.strip.downcase
      return [] if domain.blank?

      [ domain, www_variant(domain) ].compact.uniq
    end

    private

      # Only apex domains and their immediate www variant get paired. Deeper
      # subdomains like blog.example.com stand alone.
      def www_variant(domain)
        parts = domain.to_s.split(".")
        return unless parts.length == 2 || (parts.length == 3 && parts.first == "www")

        if domain.start_with?("www.")
          domain.delete_prefix("www.")
        else
          "www.#{domain}"
        end
      end
  end

  def domain_changed?
    # we don't want a nil to "" to be considered a domain change
    nil_to_blank_change = (custom_domain_previously_was.nil? && custom_domain.blank?) ||
      (custom_domain_previously_was.blank? && custom_domain.nil?)

    custom_domain_previously_changed? && !nil_to_blank_change
  end

  private

    def restricted_domain
      domain = custom_domain.to_s.downcase

      if domain == "pagecord.com" || domain.end_with?(".pagecord.com")
        errors.add(:custom_domain, "is restricted")
      end
    end

    def record_custom_domain_change
      if domain_changed?
        self.custom_domain_changes.create!(custom_domain: custom_domain)
      end
    end

    def normalize_custom_domain
      self.custom_domain = custom_domain.to_s.strip.downcase.presence
    end
end
