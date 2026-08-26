class Blogs::Posts::ListsController < Blogs::PostsController
  # The blog root renders a custom home page when there is one; /posts always
  # renders the list.
  def index
    render_posts_list
  end
end
