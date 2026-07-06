module Localisable
  extend ActiveSupport::Concern

  SUPPORTED_LOCALES = %w[en id de es fr nl pl pt fi ja].freeze

  included do
    class_attribute :locale_optional, default: false

    normalizes :locale, with: -> { _1.presence }
    validates :locale, inclusion: { in: SUPPORTED_LOCALES, message: "%{value} is not a supported locale" }, allow_nil: true
    validates :locale, presence: true, unless: -> { self.class.locale_optional }
  end

  class_methods do
    def available_locales
      [
        [ "English", "en" ],
        [ "Bahasa Indonesia", "id" ],
        [ "Deutsch", "de" ],
        [ "Español", "es" ],
        [ "Français", "fr" ],
        [ "Nederlands", "nl" ],
        [ "Polski", "pl" ],
        [ "Português", "pt" ],
        [ "Suomi", "fi" ],
        [ "日本語", "ja" ]
      ]
    end

    def locale_name(code)
      available_locales.find { |_, c| c == code }&.first
    end
  end
end
