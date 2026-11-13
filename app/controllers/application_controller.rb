class ApplicationController < ActionController::Base
  helper_method :current_user
  before_action :authenticate
  before_action :warn_undeliverable_dm
  after_action :forget_undeliverable_dm

  def authenticate
    @current_user ||= session[:user_id] && User.find_by(id: session[:user_id])
  end

  def current_user
    @current_user
  end

  private

  def warn_undeliverable_dm
    return unless request.format.html? && current_user && DiscordDmJob.welcome_failed?(current_user)

    @undeliverable_dm_warned = true
    flash.now[:alert] = "Discord の DM を送れませんでした。beerkeeper のサーバーに参加しているか確かめ、サーバーのプライバシー設定で「サーバーにいるメンバーからのダイレクトメッセージを許可する」をオンにしてください"
  end

  def forget_undeliverable_dm
    DiscordDmJob.forget_welcome_failure(current_user) if @undeliverable_dm_warned && !response.redirect?
  end

  def require_login
    redirect_to login_path, alert: "ログインしてください" unless current_user
  end
end
