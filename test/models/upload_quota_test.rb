require "test_helper"

class UploadQuotaTest < ActiveSupport::TestCase
  setup do
    @user = users(:vivian)
    @blog = @user.blog
  end

  test "counts images embedded in post content" do
    @blog.posts.create!(title: "Gallery", content: image_attachment_html(3), status: :published)

    assert_equal 3, @user.upload_quota.used
  end

  test "counts the same blob once even when embedded twice" do
    blob = create_image_blob
    node = attachment_node_for(blob)

    @blog.posts.create!(title: "One", content: node, status: :published)
    @blog.posts.create!(title: "Two", content: node, status: :published)

    assert_equal 1, @user.upload_quota.used
  end

  test "counts images across all of a user's blogs" do
    @blog.posts.create!(title: "Gallery", content: image_attachment_html(2), status: :published)
    @user.stubs(:blog_limit).returns(2)
    second = @user.blogs.create!(subdomain: "viviantwo")
    second.posts.create!(title: "Gallery", content: image_attachment_html(1), status: :published)

    assert_equal 3, @user.upload_quota.used
  end

  test "counts images in discarded posts" do
    post = @blog.posts.create!(title: "Gallery", content: image_attachment_html(2), status: :published)
    post.discard

    assert_equal 2, @user.upload_quota.used
  end

  test "counts images in discarded blogs" do
    @blog.posts.create!(title: "Gallery", content: image_attachment_html(2), status: :published)
    @blog.discard

    assert_equal 2, @user.upload_quota.used
  end

  test "counts emailed attachments on a post" do
    post = @blog.posts.create!(title: "Emailed", content: "Hello", status: :published)
    post.attachments.attach(create_image_blob)

    assert_equal 1, @user.upload_quota.used
  end

  test "excludes the avatar and export files" do
    @blog.avatar.attach(io: File.open(Rails.root.join("test/fixtures/files/avatar.png")), filename: "avatar.png", content_type: "image/png")
    @blog.exports.create!(format: :html).file.attach(io: StringIO.new("zip"), filename: "export.zip", content_type: "application/zip")

    assert_equal 0, @user.upload_quota.used
  end

  test "a subscriber is unlimited" do
    assert users(:joel).upload_quota.unlimited?
  end

  test "a trial user is capped, not unlimited" do
    @user.update!(trial_ends_at: 7.days.from_now)

    assert @user.on_trial?
    assert_not @user.upload_quota.unlimited?
  end

  test "a lapsed subscriber is capped" do
    @user.create_subscription!(paddle_subscription_id: "sub_lapsed", paddle_price_id: "pri_lapsed", unit_price: 2000, plan: :annual, next_billed_at: 1.day.ago)

    assert_not @user.reload.upload_quota.unlimited?
  end

  test "reports bytes used" do
    @blog.posts.create!(title: "Gallery", content: image_attachment_html(2), status: :published)

    assert_equal ActiveStorage::Blob.last(2).sum(&:byte_size), @user.upload_quota.used_bytes
  end

  test "allows a blob that is already counted even when over the limit" do
    subscription = @user.create_subscription!(paddle_subscription_id: "sub_lapsing", paddle_price_id: "pri_lapsing", unit_price: 2000, plan: :annual, next_billed_at: 1.year.from_now)
    existing = ActiveStorage::Blob.ids
    @blog.posts.create!(title: "Gallery", content: image_attachment_html(UploadQuota::FREE_LIMIT + 10), status: :published)
    subscription.update!(next_billed_at: 1.day.ago)

    quota = @user.reload.upload_quota
    counted = ActiveStorage::Blob.where.not(id: existing).ids

    assert_equal UploadQuota::FREE_LIMIT + 10, quota.used
    assert_empty quota.uncounted(counted)

    fresh = create_image_blob.id
    assert_equal [ fresh ], quota.uncounted(counted + [ fresh ])
  end

  test "allowed content types close down once the allowance is used up" do
    assert_equal UploadQuota::FREE_CONTENT_TYPES, @user.upload_quota.allowed_content_types

    @blog.posts.create!(title: "Gallery", content: image_attachment_html(UploadQuota::FREE_LIMIT), status: :published)

    assert @user.upload_quota.exceeded?
    assert_empty @user.upload_quota.allowed_content_types
    assert_equal UploadLimits::CONTENT_TYPES.keys, users(:joel).upload_quota.allowed_content_types
  end
end
