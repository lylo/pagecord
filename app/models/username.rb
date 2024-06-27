class Username
  RESERVED = %w{ about admin app blog careers contact faq feed
                 help jobs login pagecord privacy pricing rss
                 sidekiq signup support terms  }

  FORMAT = /\A[a-zA-Z0-9_\.]+\z/
  MIN_LENGTH = 3
  MAX_LENGTH = 20

  def self.reserved?(username)
    RESERVED.include?(username)
  end

  def self.valid_format?(username)
    # specifically allowed characters
    return false unless username =~ /\A[a-zA-Z0-9_.]+\z/

    # cannot start or end with a period
    return false if username.start_with?('.') || username.end_with?('.')

    # Only one period allowed
    return false if username.count('.') > 1

    # Only one underscore allowed
    return false if username.count('_') > 1

    # Period must be between alphanumeric characters if present
    if username.include?('.')
      return false unless username =~ /[a-zA-Z0-9]\.[a-zA-Z0-9]/
    end

    true
  end
end
