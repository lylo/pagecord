class Username
  RESERVED = %w{ about admin app blog careers contact faq feed
                 help jobs login pagecord privacy pricing rss
                 sidekiq signup support terms  }

  FORMAT = /\A[a-zA-Z0-9_]+\z/
  MIN_LENGTH = 3
  MAX_LENGTH = 20

  def self.reserved?(username)
    RESERVED.include?(username)
  end
end
