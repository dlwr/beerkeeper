class PasswordResetsController < ApplicationController
  skip_before_action :authenticate
  before_action :set_user_by_token, only: %i[edit update]

  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_password_reset_path, alert: "しばらく時間をおいてから、もう一度お試しください" }

  def new; end

  def create
    if (user = User.find_by_email(params[:email].to_s))
      UserMailer.with(user:).password_reset_email.deliver_later
    end

    redirect_to login_path, notice: "登録されているメールアドレスであれば、パスワード再設定の案内を送りました"
  end

  def edit; end

  def update
    if params[:password].blank?
      @user.errors.add(:password, :blank)
    elsif @user.update(params.permit(:password, :password_confirmation))
      reset_session
      return redirect_to login_path, notice: "パスワードを再設定しました。新しいパスワードでログインしてください"
    end

    flash.now[:alert] = @user.errors.full_messages.join("、")
    render :edit, status: :unprocessable_content
  end

  private

  def set_user_by_token
    @user = User.find_by_password_reset_token(params[:token])
    redirect_to new_password_reset_path, alert: "再設定用のリンクが無効か、期限が切れています" unless @user
  end
end
