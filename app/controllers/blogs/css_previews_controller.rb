# Renders the blog home with the custom CSS stashed by the settings preview button.
class Blogs::CssPreviewsController < Blogs::PostsController
  after_action :no_store

  def show
    @blog.custom_css = Rails.cache.read("css_preview:#{@blog.id}:#{params[:id]}") or raise ActiveRecord::RecordNotFound

    index
  end
end
