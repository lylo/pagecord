class App::PagesController < AppController
  include EditorPreparation
  def index
    @pages = Current.user.blog.pages.published.order(:title)
    @drafts = Current.user.blog.pages.draft.order(:title)
  end

  def new
    @page = Current.user.blog.pages.build
  end

  def create
    @page = Current.user.blog.pages.build(page_params)

    if @page.save
      redirect_to app_pages_path, notice: "Page was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @page = Current.user.blog.pages.find_by!(token: params[:token])
    prepare_content_for_editor(@page)
  end

  def update
    @page = Current.user.blog.pages.find_by!(token: params[:token])

    if @page.update(page_params)
      redirect_to app_pages_path, notice: "Page was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @page = Current.user.blog.pages.find_by!(token: params[:token])
    @page.destroy!
    redirect_to app_pages_path, notice: "Page was successfully deleted."
  end

  def set_as_home_page
    @page = Current.user.blog.pages.find_by!(token: params[:token])
    Current.user.blog.update!(home_page_id: @page.id)
    redirect_to app_pages_path, notice: "Home page set!"
  end

  private

    def page_params
      status = params[:button] == "save_draft" ? :draft : :published

      params.require(:post).permit(:title, :content, :slug, :show_in_navigation).merge(is_page: true, status: status)
    end
end
