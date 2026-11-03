class UserMailer < ApplicationMailer
  def password_reset_email
    @user = params[:user]
    @url = edit_password_reset_url(@user.password_reset_token)

    mail to: @user.email, subject: "パスワードの再設定"
  end
end
