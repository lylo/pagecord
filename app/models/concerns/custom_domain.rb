module CustomDomain
  extend ActiveSupport::Concern

  included do
    has_many :custom_domain_changes, dependent: :destroy

    before_save :normalize_custom_domain
    after_update :record_custom_domain_change

    validates :custom_domain, uniqueness: true, allow_blank: true, format: { with: /\A(?!:\/\/)([a-zA-Z0-9](?:[a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,63}\z/ }

    validate :restricted_domain
  end

  class_methods do
    def find_by_domain_with_www_fallback(domain)
      return unless domain.present?

      blog = find_by(custom_domain: domain)
      return blog if blog

      return unless root_domain?(domain)

      find_by(custom_domain: variant_domain(domain))
    end

    private

      def root_domain?(domain)
        host = extract_host(domain)
        return false unless host

        parts = host.split(".")

        # Root domain: example.com (2 parts) or www.example.com (3 parts starting with www)
        parts.length == 2 || (parts.length == 3 && parts.first == "www")
      end

      def variant_domain(domain)
        host = extract_host(domain)
        return nil unless host

        if host.start_with?("www.")
          host.delete_prefix("www.")
        else
          "www.#{host}"
        end
      end

      def extract_host(domain)
        if domain.start_with?("http")
          URI.parse(domain).host
        else
          domain
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
