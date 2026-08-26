class Api::BaseController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  wrap_parameters false

  before_action :authenticate
  before_action :require_premium

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Not found" }, status: :not_found
  end

  rescue_from Api::BadRequestError do |e|
    render json: { error: e.message }, status: :bad_request
  end

  rescue_from Post::FrontMatter::InvalidError do |e|
    render json: { error: "Invalid front matter: #{e.message}" }, status: :unprocessable_entity
  end

  rescue_from Pagy::RangeError do
    render json: { error: "Page out of range" }, status: :bad_request
  end

  rate_limit to: 60, within: 1.minute, by: -> { Current.blog&.id || request.remote_ip }, with: :rate_limit_reached

  private

    def authenticate
      authenticate_with_http_token do |token, _options|
        Current.blog = Blog.find_by_api_key(token)
      end

      authenticate_with_access_token if allow_access_token_parameter? && !Current.blog

      unauthorized unless Current.blog
    end

    def allow_access_token_parameter?
      false
    end

    def unauthorized
      render json: { error: "Unauthorized" }, status: :unauthorized
    end

    def authenticate_with_access_token
      token = request.request_parameters[:access_token]
      Current.blog = Blog.find_by_api_key(token) if token.present?
    end

    def require_premium
      unless Current.blog.user.has_premium_access?
        render json: { error: "API access requires a premium subscription" }, status: :forbidden
      end
    end

    def rate_limit_reached
      render json: { error: "Rate limit exceeded" }, status: :too_many_requests
    end

    def unchanged_content_skipped(params, record)
      if params[:content] && record.content.body.present?
        if ActionText::Content.new(params[:content]).to_html == record.content.body.to_html
          return params.except(:content)
        end
      end
      params
    end

    def set_pagination_headers(pagy)
      response.headers.merge!(pagy.headers_hash(headers_map: { page: nil, limit: nil, count: "X-Total-Count", pages: nil }))
    end

    def parse_iso8601_timestamp(value)
      Time.iso8601(value)
    rescue ArgumentError
      raise Api::BadRequestError, "Invalid timestamp"
    end
end
