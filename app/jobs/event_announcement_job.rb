class EventAnnouncementJob < ApplicationJob
  MAX_ATTEMPTS = 5

  discard_on ActiveJob::DeserializationError

  def perform(kind, event)
    channel_id = ENV["DISCORD_EVENTS_CHANNEL_ID"]
    return if channel_id.blank? || ENV["DISCORD_BOT_TOKEN"].blank?
    return if kind == "created" && event.cancelled?

    DiscordClient.post_message(channel_id:, content: content(kind, event))
  rescue DiscordClient::RateLimited => e
    if executions < MAX_ATTEMPTS
      retry_job(wait: e.retry_after.seconds)
    else
      log_failure(event, e)
    end
  rescue DiscordClient::Error => e
    log_failure(event, e)
  end

  private

  def content(kind, event)
    lines = kind == "cancelled" ? cancelled_lines(event) : created_lines(event)
    [ *lines, Rails.application.routes.url_helpers.event_url(event, **Rails.application.config.action_mailer.default_url_options) ].join("\n")
  end

  def created_lines(event)
    [
      "新しいイベント「#{event.name}」の参加登録を受け付けています",
      "日時：#{I18n.l(event.start_at)}",
      "場所：#{event.location.presence || "未定"}",
      "定員：#{event.max_size ? "#{event.max_size} 人" : "なし"}"
    ]
  end

  def cancelled_lines(event)
    reason = event.cancellation&.reason
    [
      "「#{event.name}」は中止になりました",
      "日時：#{I18n.l(event.start_at)}",
      *(reason.present? ? [ "中止理由：#{reason}" ] : [])
    ]
  end

  def log_failure(event, error)
    Rails.logger.warn("Discord announcement for event #{event.id} failed: #{error.message} (code: #{error.code.inspect})")
  end
end
