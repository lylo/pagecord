class SpamDetector
  Result = Struct.new(:status, :reason, :model_version, keyword_init: true)

  MODEL = "gpt-4o-mini"

  attr_reader :result

  def initialize(blog)
    @blog = blog
    @access_token = ENV["OPENAI_ACCESS_TOKEN"] ||
                    Rails.application.credentials.dig(:openai_access_token)
    @client = OpenAI::Client.new(access_token: @access_token) if @access_token.present?
  end

  def detect
    return skip_result if should_skip?
    return error_result("Missing OpenAI access token") if @client.nil?

    response = @client.chat(
      parameters: {
        model: MODEL,
        temperature: 0.2,
        response_format: { type: "json_object" },
        messages: [ { role: "user", content: prompt } ]
      }
    )

    parse_response(response)
  rescue JSON::ParserError => e
    Rails.logger.warn("[SpamDetector] JSON parse error for blog #{@blog.id}: #{e.message}")
    error_result("Failed to parse AI response")
  rescue StandardError => e
    Rails.logger.error("[SpamDetector] Error for blog #{@blog.id}: #{e.class} - #{e.message}")
    error_result("Detection error")
  end

  private

    def should_skip?
      @blog.bio.to_plain_text.blank? &&
        @blog.posts.published.none? &&
        @blog.pages.published.none? &&
        @blog.navigation_items.none?
    end

    def skip_result
      @result = Result.new(
        status: :skipped,
        reason: "Empty blog - no content to analyze",
        model_version: nil
      )
    end

    def error_result(reason)
      @result = Result.new(
        status: :error,
        reason: reason,
        model_version: nil
      )
    end

    def parse_response(response)
      content = response.dig("choices", 0, "message", "content")
      data = JSON.parse(content)

      status = normalize_status(data["classification"])
      reason = data["reason"].to_s.strip.presence || "No reason provided"

      @result = Result.new(
        status: status,
        reason: reason,
        model_version: response.dig("model") || MODEL
      )
    end

    def normalize_status(value)
      case value
      when "spam" then :spam
      when "not_spam" then :clean
      when "uncertain" then :uncertain
      else :uncertain
      end
    end

    def prompt
      <<~PROMPT
        Analyze this blog for spam. This is a personal blogging platform where users post via email.

        Blog Title: #{@blog.title.presence || "(none)"}
        Subdomain: #{@blog.subdomain}
        Bio: #{bio_content}
        Posts: #{recent_posts_content}

        SPAM (classify as "spam" only if multiple signals present):
        - Bio has commercial/promotional links (gambling, pharma, SEO, financial services, backlinks)
        - Posts read like advertisements or SEO landing pages
        - Keyword stuffing in titles or content
        - Single post with only commercial affiliate links

        NOT SPAM (classify as "not_spam"):
        - Test posts, "hello world", formatting experiments
        - Personal blogs linking to relevant content (recipes, tutorials, news, other blogs)
        - Empty or minimal content (users exploring the platform)
        - Short bios, even with a personal website link
        - Links to YouTube, social media, or non-commercial content sites

        Only use "uncertain" when signals are genuinely ambiguous. Default to "not_spam" when in doubt.

        Return JSON only: {"classification": "spam" | "not_spam" | "uncertain", "reason": "brief explanation"}
      PROMPT
    end

    def bio_content
      text = @blog.bio.to_plain_text.strip
      text.presence || "(empty)"
    end

    def recent_posts_content
      posts = @blog.posts.published.order(published_at: :desc).limit(3)
      return "(no posts)" if posts.empty?

      posts.map.with_index(1) do |post, i|
        "#{i}. #{post.title.presence || "(no title)"}: #{post.text_summary.to_s.truncate(200)}"
      end.join("\n")
    end
end
