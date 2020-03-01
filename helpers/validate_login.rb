# filter to validate that a valid account is logged in
module ValidateLogin
  def is_user_logged_in()
    if session[:username].nil?
      return FALSE
    end

    return TRUE
  end
end
