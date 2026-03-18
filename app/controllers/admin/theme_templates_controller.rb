class Admin::ThemeTemplatesController < AdminController
  before_action :set_template, only: [ :show, :edit, :update, :destroy ]

  def index
    @templates = ThemeTemplate.ordered
  end

  def show
  end

  def new
    @template = ThemeTemplate.new
  end

  def create
    @template = ThemeTemplate.new(template_params)

    if @template.save
      redirect_to admin_theme_templates_path, notice: "Template created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if params[:theme_template]&.key?(:position)
      @template.reorder(params[:theme_template][:position].to_i)
      return head :ok
    end

    if @template.update(template_params)
      redirect_to admin_theme_templates_path, notice: "Template updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @template.destroy
    redirect_to admin_theme_templates_path, notice: "Template deleted"
  end

  private

    def set_template
      @template = ThemeTemplate.find(params[:id])
    end

    def template_params
      permitted = params.require(:theme_template).permit(
        :name, :description, :custom_css, :theme, :font, :width, :layout,
        :custom_theme_bg_light, :custom_theme_text_light, :custom_theme_accent_light,
        :custom_theme_bg_dark, :custom_theme_text_dark, :custom_theme_accent_dark,
        :author_name, :author_url, :position, :active
      )

      unless permitted[:theme] == "custom"
        colour_fields = %w[custom_theme_bg_light custom_theme_text_light custom_theme_accent_light
                           custom_theme_bg_dark custom_theme_text_dark custom_theme_accent_dark]
        colour_fields.each { |f| permitted[f] = nil }
      end

      permitted
    end
end
