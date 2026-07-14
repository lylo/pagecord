class App::Blogs::TrashController < AppController
  def show
    @trashed_blogs = Current.user.all_blogs.discarded.order(discarded_at: :desc)
  end

  def destroy
    Current.user.all_blogs.discarded.destroy_all
    redirect_to app_blogs_trash_path, notice: "Trash was successfully emptied"
  end
end
