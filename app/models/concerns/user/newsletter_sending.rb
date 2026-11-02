module User::NewsletterSending
  extend ActiveSupport::Concern

  INDIVIDUAL_SENDS_PER_WEEK = 3

  def individual_send_allowed?
    admin? || recent_individual_sends.count < INDIVIDUAL_SENDS_PER_WEEK
  end

  def next_individual_send_at
    recent_individual_sends.minimum(:created_at) + 1.week
  end

  private

    def recent_individual_sends
      post_digests.individual.where(created_at: 1.week.ago..)
    end
end
