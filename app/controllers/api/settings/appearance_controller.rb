class Api::Settings::AppearanceController < Api::BaseController
  SUBSCRIBER_FIELDS = %i[ show_branding ].freeze

  def show
    render json: appearance_json
  end

  def update
    if Current.blog.update(settings_params(*Themeable::ATTRIBUTES, subscriber_only: SUBSCRIBER_FIELDS))
      render json: appearance_json
    else
      render json: { errors: Current.blog.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

    def appearance_json
      Current.blog.as_json(only: Themeable::ATTRIBUTES + SUBSCRIBER_FIELDS + [ :updated_at ])
    end
end
