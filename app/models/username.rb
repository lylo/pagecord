class Username
  RESERVED = %w[ about admin app api careers contact faq feed
                 help jobs login pagecord privacy pricing rails rss
                 sidekiq signup support terms ]

  FORMAT_REGEX = /\A[a-zA-Z0-9]+\z/
  MIN_LENGTH = 3
  MAX_LENGTH = 20

  def self.reserved?(username)
    RESERVED.include?(username)
  end

  def self.valid_format?(username)
    username =~ FORMAT_REGEX
  end
end
