class App::HomePagesController < AppController
  def new
    @home_page = Current.user.blog.pages.build
  end

  def create
    @home_page = Current.user.blog.pages.build(home_page_params)
    @home_page.is_home_page = true

    if @home_page.save
      Current.user.blog.update!(home_page_id: @home_page.id)
      redirect_to edit_app_home_page_path, notice: "Homepage created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @home_page = Current.user.blog.home_page
    redirect_to new_app_home_page_path unless @home_page
  end

  def update
    @home_page = Current.user.blog.home_page
    @home_page.is_home_page = true

    if @home_page.update(home_page_params)
      redirect_to app_pages_path, notice: "Homepage updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    home_page = Current.user.blog.home_page
    home_page.update!(title: "Home Page") if home_page.title.blank?
    Current.user.blog.update!(home_page_id: nil)
    redirect_to app_pages_path, notice: "Homepage removed."
  end

  private

    def home_page_params
      status = params[:button] == "save_draft" ? :draft : :published

      params.require(:post).permit(:title, :content, :slug).merge(is_page: true, status: status, show_in_navigation: false)
    end
end
