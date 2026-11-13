class EventNotificationJob < ApplicationJob
  discard_on ActiveJob::DeserializationError

  def perform(kind, user, event, changes = {})
    return if kind == "schedule_change" && event.cancelled?

    DiscordDmJob.perform_now(user, EventNotification.new(kind, user:, event:, changes:).content)
  end
end
