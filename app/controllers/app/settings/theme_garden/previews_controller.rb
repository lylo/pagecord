class App::Settings::ThemeGarden::PreviewsController < App::BaseController
  include BlogContentSecurityPolicy

  skip_before_action :onboarding_check

  # The preview renders blog content, embeds included, under the blog layout
  blog_content_security_policy only: :show

  def show
    template = ThemeTemplate.active.find(params[:theme_garden_id])

    @blog.assign_attributes(template.appearance_attributes)
    @posts = @blog.posts.visible.with_full_rich_text.includes(:upvotes).order(published_at: :desc).limit(5)
    @pagy = Data.define(:next).new(next: nil)
    @user = @blog.user
    @preview = true

    with_blog_view_context do
      render template: "app/settings/theme_garden/previews/show", layout: "blog"
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
