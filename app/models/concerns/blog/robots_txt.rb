module Blog::RobotsTxt
  extend ActiveSupport::Concern

  MAX_CUSTOM_ROBOTS_TXT_BYTES = 32.kilobytes

  included do
    attribute :use_custom_robots_txt, :boolean

    before_validation :clear_custom_robots_txt, if: -> { use_custom_robots_txt == false }
    before_validation :normalize_custom_robots_txt
    validate :custom_robots_txt_valid
  end

  def custom_robots_txt_active?
    user.subscribed? && custom_robots_txt.present?
  end

  private

    def clear_custom_robots_txt
      self.custom_robots_txt = nil
    end

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
        errors.add(:custom_robots_txt, "is too long (maximum #{ActiveSupport::NumberHelper.number_to_human_size(MAX_CUSTOM_ROBOTS_TXT_BYTES)})")
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
      when "crawl-delay"
        validate_crawl_delay(value.strip, line_number)
      else
        errors.add(:custom_robots_txt, "has an unsupported directive on line #{line_number}")
      end
    end

    def validate_user_agent(value, line_number)
      return if value.match?(/\A[\w.*+ \/-]+\z/)

      errors.add(:custom_robots_txt, "has an invalid user agent on line #{line_number}")
    end

    def validate_path(value, directive, line_number)
      return if directive.casecmp?("disallow") && value.blank?
      return if value.start_with?("/")

      errors.add(:custom_robots_txt, "has an invalid path on line #{line_number}")
    end

    def validate_crawl_delay(value, line_number)
      return if value.match?(/\A\d+(\.\d+)?\z/)

      errors.add(:custom_robots_txt, "has an invalid crawl delay on line #{line_number}")
    end
end
