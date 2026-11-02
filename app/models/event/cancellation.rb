class Event::Cancellation < ApplicationRecord
  belongs_to :event

  after_create_commit :notify_participants

  private

  def notify_participants
    event.participants.each do |user|
      EventMailer.with(user:, event:).cancellation_email.deliver_later
    end
  end
end
