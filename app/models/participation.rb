class Participation < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :user_id, uniqueness: { scope: :event_id }

  scope :confirmed, -> { where(waitlisted: false) }
  scope :waitlisted, -> { where(waitlisted: true) }

  after_destroy :promote_waitlisters, unless: :waitlisted?
  after_create_commit :send_application_email
  after_update_commit :send_promotion_email, if: -> { saved_change_to_waitlisted?(from: true, to: false) }

  private

  def promote_waitlisters
    event.promote_waitlisters
  end

  def send_application_email
    mailer = EventMailer.with(user:, event:)
    (waitlisted? ? mailer.waitlist_email : mailer.participation_email).deliver_later
  end

  def send_promotion_email
    EventMailer.with(user:, event:).promotion_email.deliver_later
  end
end
