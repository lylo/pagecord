class App::Settings::NavigationItemsController < AppController
  before_action :set_navigation_item, only: [ :update, :destroy ]

  def index
    load_form_data
  end

  def create
    klass = case params[:nav_type]
    when "page" then PageNavigationItem
    when "custom" then CustomNavigationItem
    when "social" then SocialNavigationItem
    else NavigationItem
    end

    @navigation_item = klass.new(navigation_item_params)
    @navigation_item.blog = @blog
    @navigation_item.position = (@blog.navigation_items.maximum(:position) || 0) + 1

    if @navigation_item.save
      redirect_to app_settings_navigation_items_path, notice: "Navigation item added"
    else
      load_form_data
      render :index, status: :unprocessable_entity
    end
  end

  def update
    if params[:navigation_item]&.[](:position).present?
      reorder_navigation_item(params[:navigation_item][:position].to_i)
      head :ok
    elsif @navigation_item.update(navigation_item_params)
      redirect_to app_settings_navigation_items_path, notice: "Navigation item updated"
    else
      load_form_data
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @navigation_item.destroy
    redirect_to app_settings_navigation_items_path, notice: "Navigation item removed"
  end

  private

    def set_navigation_item
      @navigation_item = @blog.navigation_items.find(params[:id])
    end

    def load_form_data
      @navigation_items = @blog.navigation_items.includes(:post).ordered
      @pages = @blog.pages.visible.where.not(id: @blog.home_page_id).order(:title)
    end

    def reorder_navigation_item(new_position)
      @navigation_item.reorder(new_position)
    end

    def navigation_item_params
      params.require(:navigation_item).permit(:label, :url, :post_id, :platform)
    end
end
