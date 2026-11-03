class UserMailerPreview < ActionMailer::Preview
  def password_reset_email
    UserMailer.with(user: User.first).password_reset_email
  end
end
