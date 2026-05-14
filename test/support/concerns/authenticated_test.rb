module AuthenticatedTest
  extend ActiveSupport::Concern

  def login_as(user)
    access_request = user.access_requests.create!
    original_host = host

    host! Rails.application.config.action_controller.default_url_options[:host]

    get verify_access_request_url(access_request.token_digest)

    host! original_host
    Current.user = user
  end

  def logout
    delete logout_path
  end
end
