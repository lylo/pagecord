class Subdomain
  RESERVED = %w[ about abuse account accounts admin app api archive assets auth
                 billing blog careers cdn cfmail checkout community contact dev
                 discover docs domains email faq feed files guide help home images
                 inbound jobs login mail mailer media metrics monitoring mx news
                 newsletters notifications oauth og pagecord pm-bounces post press
                 pricing privacy proxy rails rss security settings shuffle sidekiq
                 signup smtp staging static status storage support terms test
                 uploads webhooks www ]

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
