class App::Settings::ThemeGardenController < AppController
  skip_before_action :onboarding_check
  before_action :set_template, only: [ :preview, :apply ]

  def index
    @templates = ThemeTemplate.active.ordered
  end

  def preview
    @blog.assign_attributes(@template.appearance_attributes)
    @posts = @blog.posts.visible.with_full_rich_text.includes(:upvotes).order(published_at: :desc).limit(5)
    @pagy = Data.define(:next).new(next: nil)
    @user = @blog.user
    with_blog_view_context do
      render template: "app/settings/theme_garden/preview", layout: "blog"
    end
  end

  def apply
    if @blog.update(@template.appearance_attributes)
      redirect_to app_settings_appearance_index_path, notice: "\"#{@template.name}\" template applied"
    else
      redirect_to app_settings_theme_garden_index_path, alert: "Could not apply template"
    end
  end

  private

    def set_template
      @template = ThemeTemplate.active.find(params[:id])
    end

    def with_blog_view_context
      original = lookup_context.prefixes.dup
      lookup_context.prefixes.unshift("blogs/posts", "blogs")
      yield
    ensure
      lookup_context.prefixes.replace(original)
    end
end
