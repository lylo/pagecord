Rake.application["db:fixtures:load"].invoke

# A flagged avatar so /admin/moderation/avatars has something to review locally.
if (blog = Blog.find_by(subdomain: "vivian"))
  unless blog.avatar.attached?
    blog.avatar.attach(
      io: File.open(Rails.root.join("test/fixtures/files/avatar.png")),
      filename: "avatar.png",
      content_type: "image/png"
    )
  end

  blog.avatar_moderation&.destroy
  blog.create_avatar_moderation!(
    status: :flagged,
    flags: { "sexual" => true },
    category_scores: { "sexual" => 0.92 },
    moderated_at: Time.current
  )
end
