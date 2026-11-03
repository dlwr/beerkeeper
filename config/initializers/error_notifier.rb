Rails.application.config.after_initialize do
  if Rails.env.production? && ENV["ERROR_NOTIFY_TO"].present?
    Rails.error.subscribe(ErrorNotifier.new(to: ENV["ERROR_NOTIFY_TO"]))
  end
end
