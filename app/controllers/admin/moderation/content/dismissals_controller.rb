class Admin::Moderation::Content::DismissalsController < Admin::BaseController
  def create
    post = Post.with_discarded.find_by!(token: params[:content_id])
    post.undiscard if post.discarded?
    post.content_moderation&.update!(status: :clean, fingerprint: post.moderation_fingerprint)

    redirect_to admin_moderation_content_index_path, notice: "Post restored and marked as reviewed"
  end
end
