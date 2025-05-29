class Subdomain
  RESERVED = %w[ about admin app api careers contact faq feed
                 help jobs login pagecord privacy pricing rails rss
                 sidekiq signup support terms ]

  FORMAT_REGEX = /\A[a-zA-Z0-9]+\z/
  MIN_LENGTH = 3
  MAX_LENGTH = 20

  def self.reserved?(subdomain)
    RESERVED.include?(subdomain)
  end

  def self.valid_format?(subdomain)
    subdomain =~ FORMAT_REGEX
  end
end
