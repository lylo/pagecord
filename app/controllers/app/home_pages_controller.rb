class App::HomePagesController < AppController
  include EditorPreparation

  def new
    @home_page = @blog.pages.build
  end

  def create
    @home_page = @blog.pages.build(home_page_params)

    if @home_page.save
      @blog.update!(home_page_id: @home_page.id)
      redirect_to app_pages_path, notice: "Home page created!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @home_page = @blog.home_page
    redirect_to new_app_home_page_path and return unless @home_page
    prepare_content_for_editor(@home_page)
  end

  def update
    @home_page = @blog.home_page

    if @home_page.update(home_page_params)
      redirect_to app_pages_path, notice: "Home page updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    home_page = @blog.home_page

    # Give the former home page a recognisable title if it doesn't have one already
    ActiveRecord::Base.transaction do
      home_page.update!(title: "Home Page") if home_page.title.blank?
      @blog.update!(home_page_id: nil)
    end

    redirect_to app_pages_path, notice: "Home page removed"
  end

  private

    def home_page_params
      status = params[:button] == "save_draft" ? :draft : :published

      params.require(:post).permit(:title, :content, :slug).merge(
          is_page: true, status: status, is_home_page: true, show_in_navigation: false
        )
    end
end
