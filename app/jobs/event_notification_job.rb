class EventNotificationJob < ApplicationJob
  discard_on ActiveJob::DeserializationError

  def perform(kind, user, event, changes = {})
    DiscordDmJob.perform_now(user, EventNotification.new(kind, user:, event:, changes:).content)
  end
end
