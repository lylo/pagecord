class Admin::UsersController < AdminController
  include Pagy::Method

  def index
    @total_users = User.count

    users = User.left_outer_joins(:subscription)
                .includes(:subscription, :blogs)
                .order(created_at: :desc)

    if params[:search].present?
      search = "%#{params[:search]}%"
      blog_user_ids = Blog.kept
                          .where("blogs.subdomain ILIKE ? OR blogs.custom_domain ILIKE ?", search, search)
                          .select(:user_id)

      users = users.where("users.email ILIKE :search OR subscriptions.paddle_customer_id ILIKE :search OR subscriptions.paddle_subscription_id ILIKE :search", search:)
                   .or(users.where(id: blog_user_ids))
    end

    if params[:status].present?
      case params[:status]
      when "paid"
        users = users.merge(Subscription.active_paid)
                     .reorder(Subscription.arel_table[:created_at].desc)
      when "comped"
        users = users.where("subscriptions.plan = ?", "complimentary")
      when "churning"
        users = users.where.not(subscriptions: { cancelled_at: nil }).where("subscriptions.next_billed_at > ?", Time.current)
      end
    end

    @pagy, @users = pagy(users, limit: 15)
    @post_counts_by_blog_id = Post.where(blog_id: @users.flat_map { |user| user.blogs.map(&:id) }, is_page: false).group(:blog_id).count
  end

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
    @user.blogs.build
  end

  def create
    @user = User.new(user_params)
    if @user.save
      AccountVerificationMailer.with(user: @user).verify.deliver_later
      redirect_to admin_user_path(@user), notice: "User was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "User was successfully updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    @user = User.find(params[:id])

    if params[:spam]
      flash[:notice] = "User was marked as spam and discarded"
      DestroyUserJob.perform_now(@user.id, spam: true)
    else
      flash[:notice] = "User was successfully discarded"
      DestroyUserJob.perform_now(@user.id)
    end

    redirect_to admin_users_path
  end

  def restore
    @user = User.find(params[:id])

    if @user.discarded?
      @user.undiscard!
      @user.blogs.find_each(&:touch)
      flash[:notice] = "User was successfully restored"
    end

    redirect_to admin_users_path
  end

  private

    def user_params
      permitted = params.require(:user).permit(:email, :trial_ends_at, features: [], blogs_attributes: [ :id, :subdomain ])
      permitted[:features] = permitted[:features].reject(&:blank?) if permitted[:features]
      permitted
    end
end
