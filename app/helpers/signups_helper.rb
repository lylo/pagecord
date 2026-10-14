module SignupsHelper
  def signup_note(user)
    blog = user.blogs.first

    if user.errors.of_kind?(:email, :taken)
      safe_join [ "That email already has a Pagecord account. ", link_to("Sign in instead?", login_path) ]
    elsif blog&.errors&.of_kind?(:subdomain, :taken)
      "That subdomain's taken. Try another?"
    else
      blog&.errors&.full_messages&.first || user.errors.full_messages_for(:email).first
    end
  end
end
