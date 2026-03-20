module AdminHelper
  def blogs_date_column
    case params[:status]
    when "churning" then { label: "Churns on", sql: "MAX(subscriptions.next_billed_at)" }
    when "paid" then { label: "Subscribed", sql: "MAX(subscriptions.created_at)" }
    else { label: "Created", sql: "blogs.created_at" }
    end
  end
end
