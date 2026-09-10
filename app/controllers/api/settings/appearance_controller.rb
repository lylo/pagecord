class Api::Settings::AppearanceController < Api::BaseController
  FIELDS = %i[
    theme font width layout
    custom_theme_bg_light custom_theme_text_light custom_theme_accent_light
    custom_theme_bg_dark custom_theme_text_dark custom_theme_accent_dark
  ].freeze
  SUBSCRIBER_FIELDS = %i[ show_branding ].freeze

  def show
    render json: appearance_json
  end

  def update
    if Current.blog.update(settings_params(*FIELDS, subscriber_only: SUBSCRIBER_FIELDS))
      render json: appearance_json
    else
      render json: { errors: Current.blog.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

    def appearance_json
      Current.blog.as_json(only: FIELDS + SUBSCRIBER_FIELDS + [ :updated_at ])
    end
end
