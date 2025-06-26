# frozen_string_literal: true

module Taggable
  extend ActiveSupport::Concern

  included do
    validates :tag_list, presence: true, allow_blank: true
    validate :validate_tag_format
    before_save :normalize_tags
  end

  # Convert tag_list array to comma-separated string for forms
  def tags_string
    tag_list.join(", ")
  end

  # Parse comma or space-separated string into tag_list array
  def tags_string=(value)
    if value.blank?
      self.tag_list = [] # Clear tags if the input is blank
    else
      self.tag_list = parse_tags(value)
    end
  end

  # Get all unique tags across all posts (class method when included)
  module ClassMethods
    def all_tags
      where.not(tag_list: []).pluck(:tag_list).flatten.uniq.sort
    end

    def tagged_with(*tags)
      where("tag_list @> ARRAY[?]::varchar[]", Array(tags).flatten)
    end

    def tagged_with_any(*tags)
      where("tag_list && ARRAY[?]::varchar[]", Array(tags).flatten)
    end
  end

  private

  def parse_tags(value)
    seen = Set.new
    value.to_s
         .split(/[,\s]+/)
         .map(&:strip)
         .map(&:downcase)
         .reject(&:blank?)
         .select { |tag| valid_tag_format?(tag) && seen.add?(tag) }
         .sort
  end

  def normalize_tags
    self.tag_list = tag_list.map(&:strip).map(&:downcase).uniq.sort if tag_list.present?
  end

  def validate_tag_format
    return if tag_list.blank?

    invalid_tags = tag_list.reject { |tag| valid_tag_format?(tag) }
    return if invalid_tags.empty?

    errors.add(:tag_list, "contains invalid tags: #{invalid_tags.join(', ')}. Tags can only contain letters, numbers, and hyphens.")
  end

  def valid_tag_format?(tag)
    tag.match?(/\A[a-zA-Z0-9-]+\z/)
  end
end
