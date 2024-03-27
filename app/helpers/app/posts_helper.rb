module App::PostsHelper

  def meta_description
    if @post
      post_title(@post)
    elsif @user.present?
      user_bio(@user)
    else
      "Pagecord is a super-simple, minimialist blogging app. All you need is an email address."
    end
  end
end
