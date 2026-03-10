class SessionsController < ApplicationController
  def create
    auth_hash = request.env["omniauth.auth"]
    user = User.find_or_create_from_omniauth(auth_hash)

    if user.banned?
      reset_session
      redirect_to root_path, alert: "Your account has been suspended."
      return
    end

    return_to = session[:return_to]
    reset_session
    session[:user_id] = user.id
    redirect_to return_to || root_path, notice: "Signed in as #{user.github_username}."
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Signed out."
  end

  def failure
    redirect_to root_path, alert: "Authentication failed: #{params[:message].to_s.humanize}."
  end
end
