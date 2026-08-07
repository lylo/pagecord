module Blog::Redirects
  extend ActiveSupport::Concern

  MAX_REDIRECT_RULES_BYTES = 32.kilobytes
  FEED_ALIASES = %w[feed feed.xml rss rss.xml].freeze

  included do
    attribute :use_redirect_rules, :boolean

    before_validation :clear_redirect_rules, if: -> { use_redirect_rules == false }
    before_validation :normalize_redirect_rules
    validate :redirect_rules_valid
  end

  # Resolves a 404ing request path to a redirect destination, or nil.
  # Explicit rules win, then a slug-based fallback for multi-segment paths
  # (e.g. /2024/01/my-post -> /my-post). Single hop only: destinations are
  # never re-resolved.
  def resolve_redirect(path)
    path = normalize_redirect_path(path)
    rule_destination_for(path) || fallback_destination_for(path)
  end

  private

    def rule_destination_for(path)
      return nil if redirect_rules.blank?

      each_redirect_rule do |source, destination|
        if source.end_with?("*")
          prefix = source.delete_suffix("*")
          next unless path.start_with?(prefix)
          destination = destination.sub("*", path.delete_prefix(prefix))
        else
          next unless path == source
        end

        next if destination.start_with?("//") # substitution must not produce a protocol-relative URL
        next if normalize_redirect_path(destination) == path
        return destination
      end
      nil
    end

    def fallback_destination_for(path)
      segments = path.split("/").reject(&:blank?)
      return nil unless segments.size >= 2

      candidate = segments.last
      return "/feed.xml" if FEED_ALIASES.include?(candidate)

      candidate = candidate.delete_suffix(".html")
      return nil unless candidate.match?(Sluggable::SLUG_FORMAT)
      return nil unless all_posts.kept.published.released.exists?(slug: candidate)

      "/#{candidate}"
    end

    def each_redirect_rule
      redirect_rules.each_line do |line|
        source, destination = parse_redirect_rule(line)
        yield normalize_redirect_path(source), destination if source
      end
    end

    # Returns [source, destination], or nil for blank, comment, or invalid lines.
    def parse_redirect_rule(line)
      tokens = line.strip.split
      return nil if tokens.empty? || tokens.first.start_with?("#")
      return nil unless tokens.size == 2

      source, destination = tokens
      return nil unless valid_redirect_path?(source) && valid_redirect_path?(destination)
      return nil if source.include?("*") && !source.end_with?("*")
      return nil if destination.include?("*") && !source.end_with?("*")

      [ source, destination ]
    end

    def valid_redirect_path?(path)
      path.start_with?("/") && !path.start_with?("//") && path.count("*") <= 1
    end

    def normalize_redirect_path(path)
      path = path.downcase
      path == "/" ? path : path.chomp("/")
    end

    def clear_redirect_rules
      self.redirect_rules = nil
    end

    def normalize_redirect_rules
      return if redirect_rules.nil?
      return unless redirect_rules.valid_encoding?

      normalized = redirect_rules.gsub(/\r\n?/, "\n")
      self.redirect_rules = normalized.blank? ? nil : normalized
    end

    def redirect_rules_valid
      return if redirect_rules.blank?

      unless redirect_rules.valid_encoding?
        errors.add(:redirect_rules, "must be valid UTF-8")
        return
      end

      if redirect_rules.bytesize > MAX_REDIRECT_RULES_BYTES
        errors.add(:redirect_rules, "is too long (maximum #{ActiveSupport::NumberHelper.number_to_human_size(MAX_REDIRECT_RULES_BYTES)})")
      end

      sources = []
      redirect_rules.each_line.with_index(1) do |line, line_number|
        stripped = line.strip
        next if stripped.blank? || stripped.start_with?("#")

        source, _destination = parse_redirect_rule(stripped)
        source = normalize_redirect_path(source) if source
        if source.nil?
          errors.add(:redirect_rules, "has an invalid rule on line #{line_number}")
        elsif sources.include?(source)
          errors.add(:redirect_rules, "has a duplicate source on line #{line_number}")
        else
          sources << source
        end
      end
    end
end
