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
        @blog.all_posts.published.none? &&
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
        Posts and pages (as stored HTML, so you can see the links):
        #{recent_posts_content}
        Outbound link summary (counted across the full content, which the excerpts above may cut short): #{link_summary}

        Judge this blog on where its links point and what they are for, not on how many there are or how little writing surrounds them. Links to #{domain} are internal to this platform and are not outbound links.

        Most posts here are short. Sharing a video, image, song or article with a one-line comment, or no comment at all, is the normal shape of a post on this platform. It is never spam on its own, however often the blog does it.

        These are never backlinks, no matter how many appear or how often the same one repeats:
        - Media and image hosts: YouTube, Vimeo, imgur, gyazo, tenor, giphy, streamable, Apple Music, Spotify, SoundCloud, Bandcamp, Midjourney and similar CDNs
        - Social platforms: Instagram, Bluesky, Mastodon, X, Threads, TikTok, Reddit, GitHub, LinkedIn
        - Sharing sites for photos, film, music and books: glass.photo, Flickr, 500px, VSCO, Behance, Letterboxd, Goodreads and their equivalents
        - News sites, magazines, articles and other people's blogs. Collecting links to these with no commentary at all is link blogging, a normal form here
        - The author's own site, shop, portfolio, newsletter or employer, including a bio or links page that is nothing but these

        Apply that as a rule, not a hint: repetition of those hosts across many posts is exactly what a normal blog looks like here, and counts for nothing. A blog whose outbound links are all of those kinds is not a link farm. Read the rest before answering all the same.

        SPAM (classify as "spam" only when the links point at an unrelated business the blog is being used to promote):
        - The same external commercial host repeats across several posts, with filler writing wrapped around the links
        - A single post or page carries many links to unrelated commercial sites, such as a "links" or "resources" page that is really a business directory. Concentration in one place counts as much as repetition across several
        - Links, anchor text or titles push gambling, pharmacy or pills, crypto trading, loans, essay writing, cheap flights or tickets, escorts, piracy, or SEO, backlink and guest post services
        - Keyword-stuffed anchor text or titles, such as "best cheap movers dubai 2025"
        - Content reads like a press release, product landing page or SEO article rather than personal writing
        - Title, bio and posts all funnel to one commercial site that is not the author's own personal presence

        NOT SPAM (classify as "not_spam"):
        - Test posts, "hello world", formatting experiments, or a blog with no posts at all
        - A blog whose only links are in the bio, however commercial they look – that is a new user, not a link farm
        - Posts that are mostly links, where the destinations are media, social, news, recipes, tutorials or other people's blogs
        - An affiliate or product link inside a post that also contains real personal writing
        - Writing that is unpolished, or about a commercial subject but written personally. Language is not a signal either way: judge writing in any language on the same criteria

        Link density alone is never enough, and neither is a lack of writing. A blog that posts twenty YouTube links with no commentary is a normal blog. A blog that posts three times about the same unrelated online shop is not.

        Both "spam" and "uncertain" send the blog to a human moderator, who decides what happens to it. Neither removes anything on its own, and the difference between them is small. "not_spam" closes the case with nobody looking, so it is the only answer that is expensive to get wrong. When you cannot tell, answer "uncertain" – in particular when the destinations look commercial but you cannot tell whether they are the author's own.

        Return JSON only: {"classification": "spam" | "not_spam" | "uncertain", "reason": "brief explanation naming the deciding signal"}
      PROMPT
    end

    def bio_content
      text = @blog.bio.to_plain_text.strip
      text.presence || "(empty)"
    end

    def recent_posts
      @recent_posts ||= @blog.all_posts.published.with_rich_text_content
                             .order(published_at: :desc).limit(POST_SAMPLE_SIZE).to_a
    end

    def recent_posts_content
      return "(no posts)" if recent_posts.empty?

      recent_posts.map.with_index(1) do |post, i|
        "#{i}. #{post.title.presence || "(no title)"}: #{post_html(post)}"
      end.join("\n")
    end

    # The stored HTML rather than the plain text summary, which strips links out
    # entirely. Attachment sgids are dropped as most of the markup by volume and
    # meaningless to the model, and src attributes so that an embedded image is
    # not mistaken for an outbound link.
    def stripped_html(post)
      post.content.body.to_html.gsub(/ (sgid|src|srcset)="[^"]*"/, "").squish
    end

    # Only the excerpt shown to the model is truncated. Counting links from a
    # truncated body would miss exactly the shape we are looking for: filler
    # writing first, then the links.
    def post_html(post)
      stripped_html(post).truncate(POST_HTML_LIMIT)
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
        sources = [ @blog.bio.body&.to_html.to_s, *@blog.navigation_items.map(&:link_url), *recent_posts.map { |post| stripped_html(post) } ]

        sources.join(" ").scan(%r{https?://(?:www\.)?([^/"'\s<>]+)}i).flatten.map(&:downcase)
               .reject { |host| host == domain || host.end_with?(".#{domain}") }
      end
    end

    def domain
      Rails.application.config.x.domain
    end
end
