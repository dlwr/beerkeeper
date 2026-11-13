class EventMailer < ApplicationMailer
  after_action :skip_without_email
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.event_mailer.participation_email.subject
  #
  def participation_email
    @user = params[:user]
    @event = params[:event]

    mail to: @user.email, subject: "【#{@event.name}】参加登録を受け付けました"
  end

  def waitlist_email
    @user = params[:user]
    @event = params[:event]

    mail to: @user.email, subject: "【#{@event.name}】補欠として受け付けました"
  end

  def promotion_email
    @user = params[:user]
    @event = params[:event]

    mail to: @user.email, subject: "【#{@event.name}】繰り上げで参加が確定しました"
  end

  def schedule_change_email
    @user = params[:user]
    @event = params[:event]
    @changes = params[:changes]

    mail to: @user.email, subject: "【#{@event.name}】開催日時・場所が変更されました"
  end

  def cancellation_email
    @user = params[:user]
    @event = params[:event]
    @reason = @event.cancellation&.reason

    mail to: @user.email, subject: "【#{@event.name}】イベントは中止になりました"
  end

  private

  def skip_without_email
    message.perform_deliveries = false if @user.email.blank?
  end
end
