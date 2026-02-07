class Admin::BlogsController < AdminController
  include Pagy::Method

  def index
    @total_users = User.count

    users = User.left_outer_joins(:subscription)
                .includes(:blogs)
                .order(created_at: :desc)

    if params[:search].present?
      users = users.joins(:blogs)
                   .where("blogs.subdomain ILIKE ? OR users.email ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
                   .distinct
    end

    if params[:status].present?
      case params[:status]
      when "paid"
        users = users.where("subscriptions.plan IN (?) AND subscriptions.cancelled_at IS NULL AND subscriptions.next_billed_at > ?", [ "annual", "monthly" ], Time.current)
      when "comped"
        users = users.where("subscriptions.plan = ?", "complimentary")
      end
    end

    @pagy, @users = pagy(users, limit: 15)
  end
end
