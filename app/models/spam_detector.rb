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
        You are an expert spam detection system for a personal blogging platform.
        Your goal is to identify blogs created by bots or content farms for SEO and backlink harvesting, while protecting legitimate new users.

        Blog Context:
        Title: #{@blog.title}
        Subdomain: #{@blog.subdomain}
        Bio (HTML): #{@blog.bio}

        Recent Posts (HTML):
        #{recent_posts_content}

        Strong Indicators of SEO/Backlink Spam:
        - **Impersonal / Generic Content:** "Spun" articles, encyclopedia-style entries, or generic "how-to" guides lacking personal voice.
        - **Keyword-Mashup Subdomains:** Random word combinations (e.g., "totosafereult") or specific "Toto" / gambling / verification / scam site keywords.
        - **Commercial/SEO Focus:** Mentions of pharmaceuticals, gambling, financial products, SEO services, backlinks, or trades.
        - **Suspicious Linking:**
            - External commercial or promotional links in the Bio.
            - Links with commercial anchor text in generic articles (e.g., linking "safety standards" to a betting site).
            - Hidden links or links to unrelated domains.
        - **Mismatched Context:** Title says "Sports" but content is vague business advice.

        Strong Indicators of Legitimate Use:
        - **Personal Voice:** First-person narrative ("I", "me", "my"), casual tone, personal anecdotes.
        - **Exploratory Content:** "Hello world", "Test post", empty bios, or formatting experiments (common for new users).
        - **Relevant Linking:** Links to non-commercial resources (GitHub, personal blogs, news) that fit the context.
        - **Minimalism:** Default titles (e.g., "@subdomain") or short, casual bios.

        Guidance:
        - **Primary Signal:** Look for the *combination* of generic/spun content AND commercial/irrelevant links.
        - **Be Conservative:** Many legitimate users create low-quality or empty test blogs. Do not flag them unless there is clear SEO intent.
        - **Uncertainty:** If signals are mixed or weak (e.g., empty blog, simple test post), return "uncertain". Prefer false negatives over false positives.

        Return valid JSON only:
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
          Content (HTML):
          #{post.content}
        POST
      end.join("\n")
    end
end
