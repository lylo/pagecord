class Blogs::FormNoncesController < Blogs::BaseController
  skip_forgery_protection

  # Blog pages on pagecord.com are edge cached, so a form can't carry anything
  # tied to the visitor's session. A form fetches the nonce when it is first
  # used, and the browser sends it back as a cookie when the form is submitted.
  def create
    session[:form_nonce] ||= SecureRandom.hex(16)
    cookies[:form_nonce] = session[:form_nonce]
    head :no_content
  end
end
