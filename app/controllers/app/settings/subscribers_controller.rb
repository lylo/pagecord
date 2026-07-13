class App::Settings::SubscribersController < AppController
  def index
    send_data @blog.email_subscribers.confirmed.to_csv,
      filename: "#{@blog.subdomain}-subscribers-#{Date.current.iso8601}.csv",
      type: "text/csv"
  end
end
