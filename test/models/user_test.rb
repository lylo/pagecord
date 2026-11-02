require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should validate format of email" do
    user = User.new(email: "joel")
    assert_not user.valid?

    user = User.new(email: "joel@blah.blahhhhh")
    assert user.valid?
  end

  test "should store in lowercase" do
    user = User.create!(email: "nEwUser@NewUser.COM")
    assert_equal "newuser@newuser.com", user.email
  end

  test "should strip whitespace" do
    user = User.create!(email: "newuser@newuser.com ")
    assert_equal "newuser@newuser.com", user.email
  end

  # Free trial tests
  test "on_trial? returns true when user created within 14 days and not subscribed" do
    user = User.create!(email: "trial@example.com", created_at: 5.days.ago)
    assert user.on_trial?
  end

  test "on_trial? returns false when user is subscribed" do
    user = users(:joel) # has subscription
    user.update!(created_at: 5.days.ago)
    assert_not user.on_trial?
  end

  test "on_trial? returns false when user created more than 14 days ago" do
    user = users(:vivian) # no subscription
    assert_not user.on_trial?
  end

  test "trial_days_remaining returns correct number of days" do
    user = User.create!(email: "trial@example.com", trial_ends_at: 9.days.from_now.to_date)
    assert_equal 9, user.trial_days_remaining
  end

  test "trial_days_remaining returns 0 when not on trial" do
    user = users(:vivian) # created 30 days ago, no subscription
    assert_equal 0, user.trial_days_remaining
  end

  test "trial_days_remaining returns 0 when subscribed" do
    user = users(:joel) # has subscription
    user.update!(created_at: 5.days.ago)
    assert_equal 0, user.trial_days_remaining
  end

  test "on_free_plan? returns true when not subscribed and not on trial" do
    user = users(:vivian) # created 30 days ago, no subscription
    assert user.on_free_plan?
  end

  test "on_free_plan? returns false when subscribed" do
    user = users(:joel) # has subscription
    assert_not user.on_free_plan?
  end

  test "on_free_plan? returns false when on trial" do
    user = User.create!(email: "trial@example.com", created_at: 5.days.ago)
    assert_not user.on_free_plan?
  end

  test "nested blog attributes cannot exceed the user blog limit" do
    user = User.new(
      email: "two-blogs@example.com",
      blogs_attributes: [
        { subdomain: "twoblogsone" },
        { subdomain: "twoblogstwo" }
      ]
    )

    assert_not user.valid?
    assert user.blogs.any? { |blog| blog.errors[:base].include?("You can't add another blog because you've already reached your blog limit") }
  end

  test "destroy removes kept and discarded blogs" do
    user = users(:annie)
    kept_blog = user.blog
    discarded_blog = user.blogs.create!(subdomain: "anniediscarded")
    discarded_blog.discard!

    assert_difference "Blog.with_discarded.count", -2 do
      user.destroy!
    end

    assert_not Blog.with_discarded.exists?(kept_blog.id)
    assert_not Blog.with_discarded.exists?(discarded_blog.id)
  end

  test "purgeable_discarded includes old discarded users without subscriptions" do
    user = users(:elliot)
    user.discard!
    user.update_columns(discarded_at: 8.days.ago)

    assert_includes User.purgeable_discarded(before: 7.days.ago), user
  end

  test "purgeable_discarded excludes discarded paid users before paid access ends" do
    user = users(:joel)
    user.discard!
    user.update_columns(discarded_at: 8.days.ago)
    user.subscription.update!(cancelled_at: 1.day.ago, next_billed_at: 1.month.from_now)

    assert_not_includes User.purgeable_discarded(before: 7.days.ago), user
  end

  test "purgeable_discarded includes discarded paid users after paid access ends" do
    user = users(:joel)
    user.discard!
    user.update_columns(discarded_at: 8.days.ago)
    user.subscription.update!(cancelled_at: 2.months.ago, next_billed_at: 1.month.ago)

    assert_includes User.purgeable_discarded(before: 7.days.ago), user
  end

  test "purgeable_discarded excludes discarded paid users with unknown paid access end" do
    user = users(:joel)
    user.discard!
    user.update_columns(discarded_at: 8.days.ago)
    user.subscription.update!(cancelled_at: 1.day.ago, next_billed_at: nil)

    assert_not_includes User.purgeable_discarded(before: 7.days.ago), user
  end

  test "custom_domain_access? allows active subscribers" do
    assert users(:joel).custom_domain_access?
  end

  test "custom_domain_access? allows lapsed subscribers during grace period" do
    users(:joel).subscription.update!(next_billed_at: (Subscribable::CUSTOM_DOMAIN_GRACE_PERIOD - 1).days.ago)

    assert users(:joel).custom_domain_access?
  end

  test "custom_domain_access? rejects subscribers after grace period" do
    users(:joel).subscription.update!(next_billed_at: (Subscribable::CUSTOM_DOMAIN_GRACE_PERIOD + 1).days.ago)

    assert_not users(:joel).custom_domain_access?
  end

  test "individual sends are capped per week across all of an account's blogs" do
    user = users(:joel)
    user.update!(admin: false)
    PostDigest.create!(blog: blogs(:joel), kind: :individual)
    PostDigest.create!(blog: blogs(:joel_notes), kind: :individual)

    assert user.individual_send_allowed?

    PostDigest.create!(blog: blogs(:joel_notes), kind: :individual)

    assert_not user.individual_send_allowed?
  end

  test "individual sends older than a week no longer count" do
    user = users(:joel)
    user.update!(admin: false)
    oldest = PostDigest.create!(blog: blogs(:joel), kind: :individual, created_at: 6.days.ago)
    2.times { PostDigest.create!(blog: blogs(:joel), kind: :individual) }

    assert_not user.individual_send_allowed?
    assert_equal oldest.created_at + 1.week, user.next_individual_send_at

    travel 2.days

    assert user.individual_send_allowed?
  end

  test "admins are not capped on individual sends" do
    user = users(:joel)
    User::NewsletterSending::INDIVIDUAL_SENDS_PER_WEEK.times { PostDigest.create!(blog: blogs(:joel), kind: :individual) }

    assert user.individual_send_allowed?
  end
end
