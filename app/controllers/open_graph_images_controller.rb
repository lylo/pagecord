class OpenGraphImagesController < Blogs::BaseController
  def show
    post = Post.find_by!(token: params[:post_token])
    og_image = post.open_graph_image

    if og_image&.image&.attached?
      send_data og_image.image.download, type: "image/png", disposition: "inline"
    else
      head :not_found
    end
  end

  def blog
    og_image = @blog.open_graph_image

    if og_image&.image&.attached?
      send_data og_image.image.download, type: "image/png", disposition: "inline"
    else
      head :not_found
    end
  end
end
