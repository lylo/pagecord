class App::PagesController < AppController
  include EditorPreparation
  def index
    home_page_id = @blog.home_page_id
    @pages = @blog.pages.kept.published.order(:title).sort_by { |p| p.id == home_page_id ? 0 : 1 }
    @drafts = @blog.pages.kept.draft.order(:title)
  end

  def new
    @page = @blog.pages.build
  end

  def create
    @page = @blog.pages.build(page_params)

    if @page.save
      redirect_to app_pages_path, notice: "Page was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @page = @blog.pages.kept.find_by!(token: params[:token])
    prepare_content_for_editor(@page)
  end

  def update
    @page = @blog.pages.kept.find_by!(token: params[:token])

    if @page.update(page_params)
      redirect_to app_pages_path, notice: "Page was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @page = @blog.pages.kept.find_by!(token: params[:token])
    @page.destroy!
    redirect_to app_pages_path, notice: "Page was successfully deleted."
  end

  def set_as_home_page
    @page = @blog.pages.kept.find_by!(token: params[:token])
    @blog.update!(home_page_id: @page.id)
    redirect_to app_pages_path, notice: "Home page set!"
  end

  private

    def page_params
      status = params[:button] == "save_draft" ? :draft : :published

      params.require(:post).permit(:title, :content, :slug, :show_in_navigation).merge(is_page: true, status: status)
    end
end
