class AdminConstraint
  def matches?(request)
    return false unless request.session[:user_id]
    user = User.kept.find_by(id: request.session[:user_id])
    user&.admin?
  end
end
