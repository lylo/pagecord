class App::PagesController < AppController
  def index
    persist_sort_preference if params[:sort].present?

    home_page_id = Current.user.blog.home_page_id
    @sort = selected_sort
    secondary_order = @sort == "updated" ? "updated_at DESC, LOWER(title)" : "LOWER(title), updated_at DESC"
    @pages = Current.user.blog.pages.kept.published
      .order(Arel.sql("CASE WHEN id = #{home_page_id.to_i} THEN 0 ELSE 1 END, #{secondary_order}"))
    @drafts = Current.user.blog.pages.kept.draft.order(:title)
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
    @page = Current.user.blog.pages.kept.find_by!(token: params[:token])
  end

  def update
    @page = Current.user.blog.pages.kept.find_by!(token: params[:token])

    if @page.update(page_params)
      redirect_to app_pages_path, notice: "Page was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @page = Current.user.blog.pages.kept.find_by!(token: params[:token])
    @page.discard!
    Current.user.blog.update!(home_page_id: nil) if @page.home_page?
    redirect_to app_pages_path, notice: "Page was successfully deleted."
  end

  def set_as_home_page
    @page = Current.user.blog.pages.kept.find_by!(token: params[:token])
    Current.user.blog.update!(home_page_id: @page.id)
    redirect_to app_pages_path, notice: "Home page set!"
  end

  private

    def selected_sort
      params[:sort] == "updated" || cookies.encrypted[:pages_sort] == "updated" ? "updated" : "alpha"
    end

    def persist_sort_preference
      if params[:sort] == "updated"
        cookies.encrypted[:pages_sort] = {
          value: "updated",
          expires: 1.year.from_now
        }
      else
        cookies.delete(:pages_sort)
      end
    end

    def page_params
      status = params[:button] == "save_draft" ? :draft : :published

      params.require(:post).permit(:title, :content, :slug).merge(is_page: true, status: status)
    end
end
