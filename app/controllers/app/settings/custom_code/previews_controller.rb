class App::Settings::CustomCode::PreviewsController < App::BaseController
  include BlogContentSecurityPolicy

  skip_before_action :onboarding_check

  blog_content_security_policy only: :update

  # A reload of the preview tab arrives here as a GET.
  def show
    redirect_to app_settings_custom_code_path
  end

  def update
    @blog.assign_attributes(custom_css: params[:blog][:custom_css])
    @user = @blog.user
    @preview = true

    with_blog_view_context do
      if (@post = @blog.all_posts.visible.find_by(id: @blog.home_page_id))
        render template: "blogs/posts/show", layout: "blog"
      else
        @posts = @blog.posts.visible.with_full_rich_text.includes(:upvotes).order(published_at: :desc).limit(5)
        @pagy = Data.define(:next).new(next: nil)
        render template: "app/settings/custom_code/previews/update", layout: "blog"
      end
    end
  end

  private

    def with_blog_view_context
      original = lookup_context.prefixes
      lookup_context.prefixes = [ "blogs/posts", "blogs", *original ]
      yield
    ensure
      lookup_context.prefixes = original
    end
end
