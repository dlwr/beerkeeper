class RegistrationsController < ApplicationController
  # GET /signup
  def new
    @user = User.new
  end

  # POST /signup 会員登録
  def create
    @user = User.new(user_params)

    if @user.save
      flash[:notice] = "\u30E6\u30FC\u30B6\u30FC\u767B\u9332\u3057\u307E\u3057\u305F"
      redirect_to login_path
    else
      flash.now[:alert] = @user.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  private

  # Only allow a trusted parameter "white list" through.
  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
