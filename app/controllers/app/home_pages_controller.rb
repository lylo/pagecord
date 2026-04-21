class App::HomePagesController < AppController
  def new
    @home_page = Current.user.blog.pages.build
  end

  def create
    @home_page = Current.user.blog.pages.build(home_page_params)

    return render_stale_form_context unless context_blog_id_matches_current_blog?

    if @home_page.save
      Current.user.blog.update!(home_page_id: @home_page.id)
      redirect_to app_pages_path, notice: "Home page created!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @home_page = Current.user.blog.home_page
    redirect_to new_app_home_page_path and return unless @home_page
  end

  def update
    @home_page = Current.user.blog.home_page

    if @home_page.update(home_page_params)
      redirect_to app_pages_path, notice: "Home page updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    home_page = Current.user.blog.home_page

    # Give the former home page a recognisable title if it doesn't have one already
    ActiveRecord::Base.transaction do
      home_page.update!(title: "Home Page") if home_page.title.blank?
      Current.user.blog.update!(home_page_id: nil)
    end

    redirect_to app_pages_path, notice: "Home page removed"
  end

  private

    def home_page_params
      status = params[:button] == "save_draft" ? :draft : :published
      permitted = [ :title, :content, :slug ]
      permitted += [ :open_graph_image, :open_graph_image_suppressed ] if Current.user.has_premium_access?
      params.require(:post).permit(*permitted).merge(is_page: true, status: status, is_home_page: true)
    end
end
