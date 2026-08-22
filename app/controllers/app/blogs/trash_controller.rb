class App::Blogs::TrashController < AppController
  def show
    @trashed_blogs = Current.user.all_blogs.discarded.order(discarded_at: :desc)
  end

  def destroy
    Current.user.all_blogs.discarded.ids.each { Blogs::DestroyJob.perform_later(it) }
    redirect_to app_blogs_trash_path, notice: "Trash is being emptied"
  end
end
