class ErrorNotifier
  INTERVAL = 1.hour

  def initialize(to:, cache: nil)
    @to = to
    @cache = cache
  end

  def report(error, handled:, severity:, context:, source: nil)
    return if handled || @to.blank?
    return unless first_in_interval?(error)

    ErrorMailer.with(to: @to, error:, source:).error_email.deliver_now
  rescue StandardError => e
    Rails.logger.error("ErrorNotifier failed: #{e.class}: #{e.message}")
  end

  private

  def first_in_interval?(error)
    key = "error_notifier/#{Digest::SHA256.hexdigest([ error.class.name, error.backtrace&.first ].join("\n"))}"
    (@cache || Rails.cache).write(key, true, expires_in: INTERVAL, unless_exist: true)
  end
end
