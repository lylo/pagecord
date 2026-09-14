class Api::Settings::CustomCodeController < Api::BaseController
  FIELDS = %i[ custom_css custom_footer_html ].freeze
  SUBSCRIBER_FIELDS = %i[ custom_head_html custom_body_html custom_code_enabled ].freeze

  def show
    render json: custom_code_json
  end

  def update
    if Current.blog.update(settings_params(*FIELDS, subscriber_only: SUBSCRIBER_FIELDS))
      render json: custom_code_json
    else
      render json: { errors: Current.blog.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

    def custom_code_json
      Current.blog.as_json(only: FIELDS + SUBSCRIBER_FIELDS + [ :updated_at ])
    end
end
