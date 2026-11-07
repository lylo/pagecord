module User::NewsletterSending
  extend ActiveSupport::Concern

  MONTHLY_EMAIL_ALLOWANCE = 2_500

  def individual_send_allowed?
    admin? || emails_sent_this_month < MONTHLY_EMAIL_ALLOWANCE
  end

  def emails_sent_this_month
    PostDigestDelivery.where(post_digest: post_digests.individual.where(created_at: Time.current.all_month)).count
  end

  def next_individual_send_at
    Date.current.next_month.beginning_of_month
  end
end
