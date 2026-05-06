module Blog::RobotsTxt
  extend ActiveSupport::Concern

  MAX_CUSTOM_ROBOTS_TXT_BYTES = 10.kilobytes
  AI_CRAWLERS = [
    "Anthropic-AI",
    "Applebot-Extended",
    "Baiduspider",
    "Bytespider",
    "CCBot",
    "ChatGPT-User",
    "Claude-Crawler",
    "Claude-Web",
    "cohere-ai",
    "DotBot",
    "FacebookBot",
    "GPTBot",
    "Google-Extended",
    "Omgili",
    "Omgilibot",
    "Perplexity",
    "PetalBot"
  ].freeze

  included do
    before_validation :normalize_custom_robots_txt
    validate :custom_robots_txt_valid
  end

  def robots_txt(sitemap_url:)
    return "#{custom_robots_txt.chomp}\n" if custom_robots_txt_active?

    generated_robots_txt(sitemap_url:)
  end

  def generated_robots_txt(sitemap_url:)
    return "User-agent: *\nDisallow: /\n" unless allow_search_indexing && user.search_indexable?

    <<~ROBOTS
      # Blog robots.txt for #{subdomain}

      # Allow all user agents
      User-agent: *
      Allow: /

      # Sitemap location
      Sitemap: #{sitemap_url}

      # Block AI crawlers
      #{AI_CRAWLERS.map { |crawler| "User-agent: #{crawler}\nDisallow: /" }.join("\n\n")}
    ROBOTS
  end

  def custom_robots_txt_active?
    user.subscribed? && custom_robots_txt.present?
  end

  private

    def normalize_custom_robots_txt
      return if custom_robots_txt.nil?
      return unless custom_robots_txt.valid_encoding?

      normalized = custom_robots_txt.gsub(/\r\n?/, "\n")
      self.custom_robots_txt = normalized.blank? ? nil : normalized
    end

    def custom_robots_txt_valid
      return if custom_robots_txt.blank?

      unless custom_robots_txt.valid_encoding?
        errors.add(:custom_robots_txt, "must be valid UTF-8")
        return
      end

      if custom_robots_txt.bytesize > MAX_CUSTOM_ROBOTS_TXT_BYTES
        errors.add(:custom_robots_txt, "is too long (maximum 10 KB)")
      end

      if custom_robots_txt.each_char.any? { |char| char.ord < 32 && char != "\n" && char != "\t" }
        errors.add(:custom_robots_txt, "contains invalid control characters")
      end

      custom_robots_txt.each_line.with_index(1) do |line, line_number|
        validate_robots_txt_line(line.strip, line_number)
      end
    end

    def validate_robots_txt_line(line, line_number)
      return if line.blank? || line.start_with?("#")

      directive, value = line.split(":", 2)
      unless value
        errors.add(:custom_robots_txt, "has an invalid directive on line #{line_number}")
        return
      end

      case directive.downcase
      when "user-agent"
        validate_user_agent(value.strip, line_number)
      when "allow", "disallow"
        validate_path(value.strip, directive, line_number)
      when "sitemap"
        validate_sitemap(value.strip, line_number)
      when "crawl-delay"
        validate_crawl_delay(value.strip, line_number)
      else
        errors.add(:custom_robots_txt, "has an unsupported directive on line #{line_number}")
      end
    end

    def validate_user_agent(value, line_number)
      return if value.match?(/\A[\w.*+\/-]+\z/)

      errors.add(:custom_robots_txt, "has an invalid user agent on line #{line_number}")
    end

    def validate_path(value, directive, line_number)
      return if directive.casecmp("disallow").zero? && value.blank?
      return if value.start_with?("/")

      errors.add(:custom_robots_txt, "has an invalid path on line #{line_number}")
    end

    def validate_sitemap(value, line_number)
      uri = URI.parse(value)
      return if uri.is_a?(URI::HTTP) && uri.host.present?

      errors.add(:custom_robots_txt, "has an invalid sitemap URL on line #{line_number}")
    rescue URI::InvalidURIError
      errors.add(:custom_robots_txt, "has an invalid sitemap URL on line #{line_number}")
    end

    def validate_crawl_delay(value, line_number)
      return if value.match?(/\A\d+(\.\d+)?\z/)

      errors.add(:custom_robots_txt, "has an invalid crawl delay on line #{line_number}")
    end
end
