class SessionsController < ApplicationController
  skip_before_action :authenticate

  def new; end

  def destroy
    reset_session
    redirect_to login_path
  end
end
