module Localisable
  extend ActiveSupport::Concern

  SUPPORTED_LOCALES = %w[en es fr de pt].freeze

  included do
    validates :locale, inclusion: { in: SUPPORTED_LOCALES, message: "%{value} is not a supported locale" }
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
  end
end
