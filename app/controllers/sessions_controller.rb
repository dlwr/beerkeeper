class SessionsController < ApplicationController
  skip_before_action :authenticate

  def new;end

  def create
    user = User.find_by_email(params[:email])&.authenticate(params[:password])

    if user
      reset_session
      session[:user_id] = user.id
      flash[:notice] = "\u30ED\u30B0\u30A4\u30F3\u306B\u6210\u529F\u3057\u307E\u3057\u305F"
      redirect_to events_path
    else
      flash.now[:alert] = "\u30ED\u30B0\u30A4\u30F3\u306B\u5931\u6557\u3057\u307E\u3057\u305F"
      render :new, status: :unauthorized
    end
  end

  def destroy
    reset_session
    redirect_to login_path
  end
end
