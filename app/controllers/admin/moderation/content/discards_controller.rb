class Admin::Moderation::Content::DiscardsController < Admin::BaseController
  def create
    post = Post.find_by!(token: params[:content_id])
    post.discard!

    redirect_to admin_moderation_content_index_path, notice: "Post discarded"
  end
end
