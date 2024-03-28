class Username
  RESERVED = %w{ about admin blog careers contact faq feed
                 help login pagecord privacy pricing rss
                 signup support terms }

  FORMAT = /\A[a-zA-Z0-9_]+\z/
  MIN_LENGTH = 4
  MAX_LENGTH = 20

  def self.reserved?(username)
    RESERVED.include?(username)
  end
end
