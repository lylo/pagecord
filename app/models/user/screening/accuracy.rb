# How screening verdicts compare with the manual review, over a window.
class User::Screening::Accuracy
  def initialize(since: 30.days.ago)
    @since = since
  end

  def measured?
    reviewed_count.positive?
  end

  def reviewed_count
    @reviewed_count ||= spam_tombstones.count + not_spam_screenings.count
  end

  def false_positives
    @false_positives ||= not_spam_screenings.failed.preload(user: :blogs).order(created_at: :desc).to_a
  end

  def missed_spam
    @missed_spam ||= spam_tombstones.where(failed_checks: {}).preload(:user).order(deleted_at: :desc).to_a
  end

  private

    def spam_tombstones
      AccountTombstone.spam.where(deleted_at: @since..).where.not(failed_checks: nil)
    end

    def not_spam_screenings
      User::Screening.joins(user: :blogs).merge(User.kept).where(blogs: { reviewed_at: @since.. }).distinct
    end
end
