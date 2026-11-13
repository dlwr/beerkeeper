class DiscordSessionsController < ApplicationController
  skip_before_action :authenticate
  before_action :require_discord

  def new
    state = SecureRandom.urlsafe_base64(32)
    session[:discord_oauth_state] = state
    redirect_to DiscordClient.authorize_url(redirect_uri: discord_callback_url, state:), allow_other_host: true, status: :see_other
  end

  def create
    expected_state = session.delete(:discord_oauth_state)
    return fail_login("Discord での認可がキャンセルされました") if params[:error].present?
    return fail_login unless valid_state?(expected_state)

    access_token = DiscordClient.exchange_code(code: params[:code].to_s, redirect_uri: discord_callback_url)
    profile = DiscordClient.fetch_user(access_token)
    user = User.sign_in_with_discord(profile)
    join_guild(user, access_token)
    DiscordDmJob.perform_later(user, welcome_message, welcome: true) if user.previously_new_record?

    reset_session
    session[:user_id] = user.id
    redirect_to events_path, notice: "ログインに成功しました"
  rescue DiscordClient::Error, ActiveRecord::RecordInvalid => e
    Rails.logger.warn("Discord login failed: #{e.message}")
    fail_login
  end

  private

  def require_discord
    head :not_found unless DiscordClient.configured?
  end

  def valid_state?(expected_state)
    expected_state.present? && params[:state].present? &&
      ActiveSupport::SecurityUtils.secure_compare(expected_state, params[:state].to_s)
  end

  def join_guild(user, access_token)
    DiscordClient.add_guild_member(user_id: user.discord_user_id, access_token:)
  rescue DiscordClient::Error => e
    Rails.logger.warn("Discord guild join failed for user #{user.id}: #{e.message}")
  end

  def welcome_message
    "beerkeeper へようこそ！ イベントの参加登録や中止などのお知らせは、この DM でお届けします。\n#{root_url}"
  end

  def fail_login(message = "Discord でのログインに失敗しました。もう一度お試しください")
    redirect_to login_path, alert: message
  end
end
