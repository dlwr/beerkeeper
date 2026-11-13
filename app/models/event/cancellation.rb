class Event::Cancellation < ApplicationRecord
  belongs_to :event

  after_create_commit :notify_participants
  after_create_commit :announce

  private

  def announce
    EventAnnouncementJob.perform_later("cancelled", event)
  end

  def notify_participants
    event.participations.includes(:user).map(&:user).each do |user|
      EventNotificationJob.perform_later("cancellation", user, event)
    end
  end
end
