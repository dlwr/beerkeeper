module Event::Cancellable
  def cancelled?
    cancellation.present?
  end

  def cancelled_at
    cancellation&.created_at
  end

  def cancel(reason = nil)
    create_cancellation(reason:) unless cancelled?
  end
end
