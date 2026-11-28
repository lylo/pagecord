class Blogs::CustomCssController < Blogs::BaseController
  skip_before_action :require_blog_access

  def show
    raise ActiveRecord::RecordNotFound if @blog.custom_css.blank?

    request.session_options[:skip] = true
    expires_in 1.year, public: true, immutable: true if params[:v] == @blog.custom_css_digest
    render plain: @blog.custom_css, content_type: "text/css"
  end
end
