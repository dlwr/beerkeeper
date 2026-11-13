class DiscordDmJob < ApplicationJob
  MAX_ATTEMPTS = 5

  def self.remember_welcome_failure(user)
    Rails.cache.write(welcome_failure_key(user), true, expires_in: 30.days)
  end

  def self.pop_welcome_failure(user)
    key = welcome_failure_key(user)
    failed = Rails.cache.read(key).present?
    Rails.cache.delete(key) if failed
    failed
  end

  def self.welcome_failure_key(user)
    "discord_dm/welcome_failed/#{user.id}"
  end

  def perform(user, content, welcome: false)
    return if user.discord_user_id.blank?

    DiscordClient.send_dm(user_id: user.discord_user_id, content:)
  rescue DiscordClient::RateLimited => e
    if executions < MAX_ATTEMPTS
      retry_job(wait: e.retry_after.seconds)
    else
      give_up(user, e, welcome:)
    end
  rescue DiscordClient::Error => e
    give_up(user, e, welcome:)
  end

  private

  def give_up(user, error, welcome:)
    Rails.logger.warn("Discord DM to user #{user.id} failed: #{error.message} (code: #{error.code.inspect})")
    self.class.remember_welcome_failure(user) if welcome
  end
end
