class BlogSpamDetector
  Result = Struct.new(:status, :reason, :model_version, keyword_init: true)

  MODEL = "gpt-4o-mini"
  POST_SAMPLE_SIZE = 10
  POST_HTML_LIMIT = 1_000
  MAX_HOSTS = 20

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
    Rails.logger.warn("[BlogSpamDetector] JSON parse error for blog #{@blog.id}: #{e.message}")
    error_result("Failed to parse AI response")
  rescue StandardError => e
    Rails.logger.error("[BlogSpamDetector] Error for blog #{@blog.id}: #{e.class} - #{e.message}")
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
        status: :no_content,
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
        Analyse this blog for spam. This is a personal blogging platform where people publish short personal writing, often by email. Most blogs are genuine. The minority that are not exist to host outbound links for SEO backlinks, and often look superficially harmless.

        Blog Title: #{@blog.title.presence || "(none)"}
        Subdomain: #{@blog.subdomain}
        Bio: #{bio_content}
        Navigation links: #{@blog.navigation_items.map(&:link_url).join(", ").presence || "(none)"}
        Posts (as stored HTML, so you can see the links):
        #{recent_posts_content}
        Outbound link summary: #{link_summary}

        Judge this blog on what it links to and how much of it is link, not on how well it is written. Links to #{domain} are internal to this platform and are not outbound links.

        SPAM (classify as "spam"):
        - Posts exist mainly to carry outbound links: little or no writing around them, or filler written around the links
        - The same external commercial host repeats across several posts, or many times within one post
        - Links, anchor text or titles push gambling, pharmacy or pills, crypto trading, loans, essay writing, cheap flights or tickets, escorts, streaming or piracy, or SEO, backlink and guest post services
        - Keyword-stuffed anchor text or titles, such as "best cheap movers dubai 2025"
        - The bio or navigation is a list of commercial links to unrelated businesses
        - Content reads like a press release, product landing page or SEO article rather than personal writing

        NOT SPAM (classify as "not_spam"):
        - Test posts, "hello world", formatting experiments, or a near-empty blog with no outbound links
        - Personal writing that links out to sources, recipes, tutorials, news, other people's blogs, YouTube or social media
        - A bio linking to the author's own site, social profiles or employer
        - An affiliate or product link inside a post that also contains real personal writing
        - Writing that is unpolished, non-English, or about a commercial subject but written personally

        A blog with no outbound links is not spam, however thin it is. A blog whose posts are mostly links to unrelated commercial hosts is spam even if it is short and politely written.

        Use "uncertain" when the links look commercial but there is genuine writing around them, or when there is too little content to tell either way.

        Return JSON only: {"classification": "spam" | "not_spam" | "uncertain", "reason": "brief explanation naming the deciding signal"}
      PROMPT
    end

    def bio_content
      text = @blog.bio.to_plain_text.strip
      text.presence || "(empty)"
    end

    def recent_posts
      @recent_posts ||= @blog.posts.published.with_rich_text_content
                             .order(published_at: :desc).limit(POST_SAMPLE_SIZE).to_a
    end

    def recent_posts_content
      return "(no posts)" if recent_posts.empty?

      recent_posts.map.with_index(1) do |post, i|
        "#{i}. #{post.title.presence || "(no title)"}: #{post_html(post)}"
      end.join("\n")
    end

    # The stored HTML rather than the plain text summary, which strips links out
    # entirely. Attachment sgids are dropped: they are most of the markup by
    # volume and are meaningless to the model.
    def post_html(post)
      post.content.body.to_html.gsub(/ sgid="[^"]*"/, "").squish.truncate(POST_HTML_LIMIT)
    end

    # Repetition of the same host is the link farm signal, and a small model
    # counts it poorly across ten documents, so tally it here.
    def link_summary
      hosts = link_hosts.tally
      return "no outbound links" if hosts.empty?

      "#{link_hosts.size} outbound links, #{hosts.size} distinct hosts – " +
        hosts.sort_by { |_host, count| -count }.first(MAX_HOSTS).map { |host, count| "#{host} x#{count}" }.join(", ")
    end

    def link_hosts
      @link_hosts ||= begin
        sources = [ @blog.bio.body&.to_html.to_s, *@blog.navigation_items.map(&:link_url), *recent_posts.map { |post| post_html(post) } ]

        sources.join(" ").scan(%r{https?://(?:www\.)?([^/"'\s<>]+)}i).flatten.map(&:downcase)
               .reject { |host| host == domain || host.end_with?(".#{domain}") }
      end
    end

    def domain
      Rails.application.config.x.domain
    end
end
