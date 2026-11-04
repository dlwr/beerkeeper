class ApplicationController < ActionController::Base
  helper_method :current_user
  before_action :authenticate

  def authenticate
    @current_user ||= session[:user_id] && User.find_by(id: session[:user_id])
  end

  def current_user
    @current_user
  end

  private

  def require_login
    redirect_to login_path, alert: "ログインしてください" unless current_user
  end
end
