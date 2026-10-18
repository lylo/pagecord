class Api::Settings::CustomCodeController < Api::BaseController
  def show
    render json: custom_code_json
  end

  def update
    if Current.blog.update(settings_params(*Blog::CustomCode::ATTRIBUTES, subscriber_only: Blog::CustomCode::SUBSCRIBER_ATTRIBUTES))
      render json: custom_code_json
    else
      render json: { errors: Current.blog.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

    def custom_code_json
      Current.blog.as_json(only: Blog::CustomCode::ATTRIBUTES + Blog::CustomCode::SUBSCRIBER_ATTRIBUTES + [ :updated_at ])
    end
end
