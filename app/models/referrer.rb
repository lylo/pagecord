class Referrer
  # Normalize domains that should be aggregated together
  DOMAIN_ALIASES = {
    "twitter.com" => "x.com",
    "t.co" => "x.com",
    "go.bsky.app" => "bsky.app",
    "old.reddit.com" => "reddit.com",
    "com.reddit.frontpage" => "reddit.com",
    "google.co.uk" => "google.com",
    "google.de" => "google.com",
    "google.fr" => "google.com",
    "google.es" => "google.com",
    "google.it" => "google.com",
    "google.nl" => "google.com",
    "google.ca" => "google.com",
    "google.com.au" => "google.com",
    "google.co.jp" => "google.com",
    "google.com.br" => "google.com",
    "google.co.in" => "google.com"
  }.freeze

  KNOWN_SOURCES = {
    "google.com" => { name: "Google", icon: "search" },
    "bing.com" => { name: "Bing", icon: "search" },
    "duckduckgo.com" => { name: "DuckDuckGo", icon: "search" },
    "ecosia.org" => { name: "Ecosia", icon: "search" },
    "kagi.com" => { name: "Kagi", icon: "search" },
    "baidu.com" => { name: "Baidu", icon: "search" },
    "yahoo.com" => { name: "Yahoo", icon: "search" },
    "perplexity.ai" => { name: "Perplexity", icon: "search" },
    "chatgpt.com" => { name: "ChatGPT", icon: "search" },
    "claude.ai" => { name: "Claude", icon: "search" },
    "gemini.google.com" => { name: "Gemini", icon: "search" },
    "copilot.microsoft.com" => { name: "Copilot", icon: "search" },
    "you.com" => { name: "You.com", icon: "search" },
    "phind.com" => { name: "Phind", icon: "search" },
    "x.com" => { name: "X", icon: "social/x" },
    "facebook.com" => { name: "Facebook", icon: "person" },
    "instagram.com" => { name: "Instagram", icon: "social/instagram" },
    "linkedin.com" => { name: "LinkedIn", icon: "social/linkedin" },
    "reddit.com" => { name: "Reddit", icon: "social/reddit" },
    "news.ycombinator.com" => { name: "Hacker News", icon: "social/web" },
    "ycombinator.com" => { name: "Hacker News", icon: "social/web" },
    "github.com" => { name: "GitHub", icon: "social/github" },
    "youtube.com" => { name: "YouTube", icon: "social/youtube" },
    "tiktok.com" => { name: "TikTok", icon: "social/tiktok" },
    "threads.net" => { name: "Threads", icon: "social/threads" },
    "bsky.app" => { name: "Bluesky", icon: "social/bluesky" },
    "mastodon.social" => { name: "Mastodon", icon: "social/mastodon" },
    "substack.com" => { name: "Substack", icon: "social/rss" },
    "medium.com" => { name: "Medium", icon: "social/web" },
    "pinterest.com" => { name: "Pinterest", icon: "social/web" },
    "tumblr.com" => { name: "Tumblr", icon: "social/web" },
    "slack.com" => { name: "Slack", icon: "social/web" },
    "discord.com" => { name: "Discord", icon: "social/web" },
    "whatsapp.com" => { name: "WhatsApp", icon: "social/web" },
    "t.me" => { name: "Telegram", icon: "social/web" },
    "mail.google.com" => { name: "Gmail", icon: "social/email" },
    "outlook.live.com" => { name: "Outlook", icon: "social/email" },
    "outlook.office.com" => { name: "Outlook", icon: "social/email" }
  }.freeze

  attr_reader :url

  def initialize(url)
    @url = url
  end

  def domain
    return nil if url.blank?

    uri = URI.parse(url)
    host = uri.host&.downcase
    return nil if host.blank?

    # Remove www. prefix and normalize aliases
    normalized = host.sub(/\Awww\./, "")
    DOMAIN_ALIASES.fetch(normalized, normalized)
  rescue URI::InvalidURIError
    nil
  end

  def friendly_name
    return "Direct" if direct?

    source = KNOWN_SOURCES[domain]
    source ? source[:name] : domain
  end

  def icon_path
    return "icons/person.svg" if direct?

    source = KNOWN_SOURCES[domain]
    icon = source ? source[:icon] : "social/web"
    "icons/#{icon}.svg"
  end

  def direct?
    url.blank? || domain.nil?
  end

  def search_engine?
    return false if direct?

    source = KNOWN_SOURCES[domain]
    source && source[:icon] == "search"
  end

  def social?
    return false if direct?

    source = KNOWN_SOURCES[domain]
    source && source[:icon]&.start_with?("social/")
  end
end
