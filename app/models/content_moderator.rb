class ContentModerator
  Result = Struct.new(:status, :flags, :scores, :model_version, keyword_init: true)

  SCORE_THRESHOLD = 0.8

  CATEGORIES = %w[
    sexual sexual/minors harassment harassment/threatening
    hate hate/threatening self-harm self-harm/intent
    self-harm/instructions violence violence/graphic illicit
    illicit/violent
  ].freeze

  MODEL = "omni-moderation-latest"

  attr_reader :result

  def initialize(post)
    @post = post
    @access_token = ENV["OPENAI_ACCESS_TOKEN"] ||
                    Rails.application.credentials.dig(:openai_access_token)
    @client = OpenAI::Client.new(access_token: @access_token) if @access_token.present?
  end

  def moderate
    return error_result("Missing OpenAI access token") if @client.nil?
    return error_result("No content to moderate") unless has_content?

    response = call_moderation_api
    parse_response(response)
  end

  def flagged?
    result&.status == :flagged
  end

  def clean?
    result&.status == :clean
  end

  def error?
    result&.status == :error
  end

  private

    def has_content?
      @post.moderation_text_payload.present? || @post.moderation_image_payloads.any?
    end

    def call_moderation_api
      inputs = build_inputs

      @client.moderations(
        parameters: {
          model: MODEL,
          input: inputs
        }
      )
    end

    # Build inputs array for OpenAI moderation API (text + images)
    def build_inputs
      inputs = []
      inputs << { type: "text", text: @post.moderation_text_payload } if @post.moderation_text_payload.present?
      inputs.concat(@post.moderation_image_payloads)
    end

    def parse_response(response)
      results = response.dig("results")
      return error_result("Empty response from API") if results.blank?

      aggregated = aggregate_scores(results)
      flagged = aggregated[:flags].values.any?

      @result = Result.new(
        status: flagged ? :flagged : :clean,
        flags: aggregated[:flags],
        scores: aggregated[:scores],
        model_version: response.dig("model") || MODEL
      )
    end

    def aggregate_scores(results)
      scores = CATEGORIES.to_h { |cat| [ cat, 0.0 ] }

      results.each do |result|
        category_scores = result.dig("category_scores") || {}
        category_scores.each do |category, score|
          scores[category] = [ scores[category], score ].max if CATEGORIES.include?(category)
        end
      end

      flags = scores.transform_values { |score| score >= SCORE_THRESHOLD }
      { flags: flags, scores: scores }
    end

    def error_result(reason)
      @result = Result.new(
        status: :error,
        flags: { error: reason },
        scores: {},
        model_version: nil
      )
    end
end
