module SpamCheckable
  extend ActiveSupport::Concern

  # Reader-submitted messages all go through CleanTalk before we act on them.
  # Including models supply spam_check_url, and email where they collect one.
  #
  # Despite the shape, this is a network call with a five second timeout, not a
  # cheap predicate — call it from a background job, never a request.
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
