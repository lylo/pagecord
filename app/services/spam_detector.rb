class SpamDetector
  attr_reader :reason

  def initialize(blog)
    @blog = blog
    # Use environment variable directly or fetch from credentials
    # Assuming credentials might be used in production
    @access_token = ENV["OPENAI_ACCESS_TOKEN"] || Rails.application.credentials.dig(:openai_access_token)
    @client = OpenAI::Client.new(access_token: @access_token)
  end

  def detect
    return false if @access_token.blank?

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [ { role: "user", content: prompt } ],
        temperature: 0.2,
        response_format: { type: "json_object" }
      }
    )

    content = response.dig("choices", 0, "message", "content")
    data = JSON.parse(content).symbolize_keys
    @reason = data[:reason]
    data[:spam] == true
  rescue JSON::ParserError
    @reason = "Failed to parse AI response"
    false
  rescue StandardError => e
    Rails.logger.error("SpamDetector Error: #{e.message}")
    @reason = "Error: #{e.message}"
    false
  end

  private

    def prompt
      <<~PROMPT
        You are a spam detection system for a blogging platform.#{' '}
        Analyze the following blog content.#{' '}
        Look for SEO spam, backlinks to gambling/pharmaceuticals/adult sites, or nonsensical content generated for SEO.

        Blog Title: #{@blog.title}
        Blog Subdomain: #{@blog.subdomain}
        Bio: #{@blog.bio.to_plain_text}

        Recent Posts:
        #{recent_posts_content}

        Return valid JSON with no markdown formatting:#{' '}
        { "spam": boolean, "reason": "concise reason" }
      PROMPT
    end

    def recent_posts_content
      posts = @blog.posts.published.limit(3)
      return "No posts yet." if posts.empty?

      posts.map do |post|
        "- Title: #{post.title}\n  Summary: #{post.text_summary}"
      end.join("\n\n")
    end
end
