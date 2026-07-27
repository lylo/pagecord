module SpamCheckable
  extend ActiveSupport::Concern

  # Reader-submitted messages all go through CleanTalk before we act on them.
  # Including models supply spam_check_url, and email where they collect one.
  def spam?
    detector = MessageSpamDetector.new(name: name, email: email, message: message, page_url: spam_check_url)
    detector.detect

    Rails.logger.info("[#{self.class.name}] Spam check: #{detector.result.status} - #{detector.result.reason}")

    detector.spam?
  rescue => e
    Rails.logger.error("[#{self.class.name}] Spam check failed: #{e.message}")
    false
  end
end
