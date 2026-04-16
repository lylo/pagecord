class App::Posts::OpenGraphImagesController < AppController
  before_action :require_feature
  before_action :require_premium

  def destroy
    post = Current.user.blog.posts.kept.find_by!(token: params[:post_token])
    post.open_graph_image.purge
    redirect_to edit_app_post_path(post), notice: "Open Graph image removed"
  end

  private

    def require_feature
      render_app_not_found unless current_features.enabled?(:open_graph_image)
    end

    def require_premium
      render_app_not_found unless Current.user.has_premium_access?
    end
end
