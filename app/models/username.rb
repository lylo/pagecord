class Username
  RESERVED = %w{ about admin blog careers contact faq feed
                 help login pagecord privacy pricing rss
                 signup support terms }

  def self.reserved?(username)
    RESERVED.include?(username)
  end
end
