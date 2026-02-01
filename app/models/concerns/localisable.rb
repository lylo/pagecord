module Localisable
  extend ActiveSupport::Concern

  SUPPORTED_LOCALES = %w[en es fr de pt].freeze

  included do
    class_attribute :locale_optional, default: false

    validates :locale, inclusion: { in: SUPPORTED_LOCALES, message: "%{value} is not a supported locale" }, allow_nil: true
    validates :locale, presence: true, unless: -> { self.class.locale_optional }
  end

  class_methods do
    def available_locales
      [
        [ "English", "en" ],
        [ "Español", "es" ],
        [ "Français", "fr" ],
        [ "Deutsch", "de" ],
        [ "Português", "pt" ]
      ]
    end

    def locale_name(code)
      available_locales.find { |_, c| c == code }&.first
    end
  end
end
