class Event::Cancellation < ApplicationRecord
  belongs_to :event

  after_create_commit :notify_participants

  private

  def notify_participants
    event.participations.includes(:user).map(&:user).each do |user|
      EventNotificationJob.perform_later("cancellation", user, event)
    end
  end
end
