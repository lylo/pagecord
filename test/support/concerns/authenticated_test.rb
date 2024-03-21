module AuthenticatedTest
  extend ActiveSupport::Concern

  def login_as(user)
    access_request = user.access_requests.create!

    get verify_access_request_url(access_request.token_digest)

    Current.user = user
  end

  def logout
    delete logout_path
  end
end
