module SpamCheckable
  extend ActiveSupport::Concern

  # A CleanTalk call with a five second timeout, despite the shape. Background
  # jobs only. Including models supply spam_check_url, and email if they have one.
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
