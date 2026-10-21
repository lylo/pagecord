module Admin::ModerationHelper
  SCREENING_CODES = {
    "BL" => "IP or email on CleanTalk's blacklist",
    "EMAIL_DOMAIN_NOT_EXISTS" => "email domain doesn't exist",
    "EMAIL_NOT_EXISTS" => "email address doesn't exist"
  }.freeze

  QUEUE_FILTER_LABELS = {
    "all" => "All",
    "posts" => "Posts",
    "links" => "Links",
    "screening" => "Screening",
    "unverified" => "Unverified"
  }.freeze

  def content_moderation_count
    @content_moderation_count ||= Post.kept
                                      .moderation_flagged
                                      .published
                                      .joins(blog: :user)
                                      .where(users: { discarded_at: nil })
                                      .count
  end

  def blogs_to_review_count
    @blogs_to_review_count ||= Blog.unreviewed.count
  end

  def screening_reasons(screening)
    codes = screening.failed_checks.values.flat_map { it.to_s.split } - [ "FORBIDDEN" ]
    codes.map { SCREENING_CODES.fetch(it) { it.humanize(capitalize: false) } }.presence || [ "failed screening" ]
  end

  def review_flags(review)
    flags = []
    flags += screening_reasons(review.user.screening).map { [ "Screening: #{it}", :danger ] } if review.user.screening_failed?
    flags << [ "Links to #{pluralize(review.link_hosts.size, "site")}", :warning ] if review.link_hosts.any?
    flags << [ "#{review.burst_count} other signups in this timezone within #{Blog::Review::BURST_WINDOW.inspect}", :info ] if review.burst?
    flags
  end

  def signup_source(user)
    user.signup_source_note.presence || user.signup_referrer.to_s[%r{\Ahttps?://(?:www\.)?([^/?#:]+)}i, 1] || "direct"
  end
end
