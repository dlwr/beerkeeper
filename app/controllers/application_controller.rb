class ApplicationController < ActionController::Base
  helper_method :current_user
  before_action :authenticate
  before_action :warn_undeliverable_dm

  def authenticate
    @current_user ||= session[:user_id] && User.find_by(id: session[:user_id])
  end

  def current_user
    @current_user
  end

  private

  def warn_undeliverable_dm
    return unless request.format.html? && current_user && DiscordDmJob.pop_welcome_failure(current_user)

    flash.now[:alert] = "Discord の DM を送れませんでした。beerkeeper のサーバーのプライバシー設定で「サーバーにいるメンバーからのダイレクトメッセージを許可する」をオンにしてください"
  end

  def require_login
    redirect_to login_path, alert: "ログインしてください" unless current_user
  end
end
