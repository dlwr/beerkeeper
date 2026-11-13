class Participation < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :user_id, uniqueness: { scope: :event_id }

  scope :confirmed, -> { where(waitlisted: false) }
  scope :waitlisted, -> { where(waitlisted: true) }

  after_destroy :promote_waitlisters, unless: :waitlisted?
  after_create_commit :notify_application
  after_update_commit :notify_promotion, if: -> { saved_change_to_waitlisted?(from: true, to: false) }

  private

  def promote_waitlisters
    event.promote_waitlisters
  end

  def notify_application
    EventNotificationJob.perform_later(waitlisted? ? "waitlist" : "participation", user, event)
  end

  def notify_promotion
    EventNotificationJob.perform_later("promotion", user, event)
  end
end
