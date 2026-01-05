class SpamDetector
  attr_reader :classification, :reason

  def initialize(blog)
    @blog = blog
    @access_token =
      ENV["OPENAI_ACCESS_TOKEN"] ||
      Rails.application.credentials.dig(:openai_access_token)

    @client = OpenAI::Client.new(access_token: @access_token) if @access_token.present?
  end

  def detect
    return unknown!("Missing OpenAI access token") if @client.nil?

    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        temperature: 0.2,
        response_format: { type: "json_object" },
        messages: [
          { role: "user", content: prompt }
        ]
      }
    )

    content = response.dig("choices", 0, "message", "content")
    data = JSON.parse(content)

    @classification = normalize_classification(data["classification"])
    @reason = data["reason"].to_s.strip.presence || "No reason provided"

    @classification
  rescue JSON::ParserError => e
    Rails.logger.warn("SpamDetector JSON parse error: #{e.message}")
    unknown!("Failed to parse AI response")
  rescue StandardError => e
    Rails.logger.error("SpamDetector error: #{e.class} – #{e.message}")
    unknown!("Detection error")
  end

  def spam?
    classification == "spam"
  end

  def not_spam?
    classification == "not_spam"
  end

  def uncertain?
    classification == "uncertain"
  end

  private

  def unknown!(reason)
    @classification = "uncertain"
    @reason = reason
    @classification
  end

  def normalize_classification(value)
    case value
    when "spam", "not_spam", "uncertain"
      value
    else
      "uncertain"
    end
  end

  def prompt
    <<~PROMPT
      You are an automated spam detection system for a personal blogging platform.

      The platform is commonly used by individuals experimenting with blogs.
      Many legitimate users create test posts, leave bios empty, or publish unfinished content.

      Blog Title: #{@blog.title}
      Blog Subdomain: #{@blog.subdomain}
      Bio: #{@blog.bio.to_plain_text}

      Recent Posts:
      #{recent_posts_content}

      Strong indicators of spam include:
      - External commercial or promotional links in the bio
      - Long or marketing-style bios
      - Mentions of services such as pharmaceuticals, gambling, financial products, SEO, backlinks, or trades
      - Only a single post that contains one or more external commercial link (not youtube or social media)
      - Posts written like advertisements or SEO landing pages
      - Keyword-stuffed titles, subdomains, or content

      Strong indicators of legitimate use include:
      - Posts containing the word "test" in the title or body
      - Minimal or default titles (e.g. just "@subdomain")
      - Short, empty, or casual first-person bios
      - Posts without any external links
      - Placeholder or exploratory content ("Hello world", formatting tests)

      Guidance:
      - No single signal is decisive; weigh multiple signals
      - Be conservative when marking spam
      - When signals are weak or mixed, return "uncertain"
      - Prefer false negatives over false positives

      Return valid JSON only, with no markdown or extra text:

      {
        "classification": "spam" | "not_spam" | "uncertain",
        "reason": "concise reason"
      }
    PROMPT
  end

  def recent_posts_content
    posts = @blog.posts.published.limit(3)

    return "No posts yet." if posts.empty?

    posts.map.with_index(1) do |post, i|
      <<~POST
        Post #{i}:
        Title: #{post.title.presence || "(no title)"}
        Summary: #{post.text_summary}
      POST
    end.join("\n")
  end
end
