module NotificationHelpers
  def have_enqueued_notification(kind, *args)
    have_enqueued_job(EventNotificationJob).with(kind.to_s, *(args.empty? ? [ any_args ] : args))
  end
end

RSpec.configure do |config|
  config.include NotificationHelpers
end
