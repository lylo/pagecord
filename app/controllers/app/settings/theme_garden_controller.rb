class App::Settings::ThemeGardenController < AppController
  before_action :set_template, only: [ :preview, :apply ]

  def index
    @templates = ThemeTemplate.active.ordered
  end

  def preview
    @blog.assign_attributes(@template.appearance_attributes)
    @posts = @blog.posts.visible.with_full_rich_text.includes(:upvotes).order(published_at: :desc).limit(5)
    render layout: "blog"
  end

  def apply
    unless @blog.user.has_premium_access?
      redirect_to app_settings_theme_garden_index_path, alert: "A premium subscription is required to apply templates."
      return
    end

    @blog.update!(@template.appearance_attributes)
    redirect_to app_settings_appearance_index_path, notice: "\"#{@template.name}\" template applied"
  end

  private

    def set_template
      @template = ThemeTemplate.active.find(params[:id])
    end
end
