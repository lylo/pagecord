class SocialPreviewsController < Blogs::BaseController
  def show
    post = Post.find_by!(token: params[:post_token])
    preview = SocialPreview.new(post)

    send_data preview.to_png, type: "image/png", disposition: "inline"
  end
end
