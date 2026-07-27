# The same index, scoped to one post. Renders app/comments/index through
# inherited view prefixes.
class App::Posts::CommentsController < App::CommentsController
  private

    def scoped_post
      @blog.posts.find_by!(token: params[:post_token])
    end
end
