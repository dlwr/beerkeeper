class SessionsController < ApplicationController
  skip_before_action :authenticate

  def new
    remember_return_to(params[:return_to]) if params[:return_to].present?
  end

  def destroy
    reset_session
    redirect_to login_path
  end
end
