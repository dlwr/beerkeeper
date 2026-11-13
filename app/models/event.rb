class Event < ApplicationRecord
  SCHEDULE_ATTRIBUTES = %w[start_at end_at location].freeze
  COPIED_ATTRIBUTES = %w[name location max_size budget description participant_notice].freeze

  attr_accessor :start_at_date, :start_at_time, :end_at_date, :end_at_time

  include Cancellable

  belongs_to :organizer, class_name: "User"
  has_one :cancellation, required: false
  has_many :participations, dependent: :restrict_with_error
  has_many :confirmed_participations, -> { where(waitlisted: false) }, class_name: "Participation"
  has_many :participants, through: :confirmed_participations, source: :user
  has_many :waitlisted_participations, -> { where(waitlisted: true).order(:id) }, class_name: "Participation"
  has_many :waitlisters, through: :waitlisted_participations, source: :user

  validates :start_at, presence: true
  validates :end_at, presence: true
  validates :name, presence: true
  validate :end_at_after_start_at

  after_update :promote_waitlisters, if: :saved_change_to_max_size?
  after_update_commit :notify_schedule_change
  after_create_commit :announce

  scope :not_cancelled, -> { where.missing(:cancellation) }
  scope :upcoming, -> { where(end_at: Time.current..).order(:start_at, :id) }
  scope :past, -> { where(end_at: ...Time.current).order(start_at: :desc, id: :desc) }

  def copy
    Event.new(attributes.slice(*COPIED_ATTRIBUTES))
  end

  def organized_by?(user)
    organizer_id == user&.id
  end

  def ended?
    ends = end_at
    !ends.nil? && ends < Time.current
  end

  def full?
    limit = max_size
    !limit.nil? && participations.confirmed.count >= limit
  end

  def receive(user)
    return if ended?

    transaction do
      participation = participations.create!(user:, waitlisted: full?)

      raise ActiveRecord::Rollback if Event::Cancellation.exists?(event_id: id)

      participation.update!(waitlisted: true) if overbook?
      participation
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    nil
  end

  def participant_notice_visible_to?(user)
    participant_notice.present? && !cancelled? && (organized_by?(user) || participants.include?(user))
  end

  def waitlist_position(user)
    index = waitlisted_participations.pluck(:user_id).index(user&.id)
    index && index + 1
  end

  def promote_waitlisters
    return if ended? || Event::Cancellation.exists?(event_id: id)

    while !full? && (participation = participations.waitlisted.order(:id).first)
      participation.update!(waitlisted: false)
    end
  end

  private

  def announce
    EventAnnouncementJob.perform_later("created", self)
  end

  def notify_schedule_change
    schedule_changes = saved_changes.slice(*SCHEDULE_ATTRIBUTES)
    return if schedule_changes.empty? || Event::Cancellation.exists?(event_id: id)

    participations.includes(:user).map(&:user).each do |user|
      EventNotificationJob.perform_later("schedule_change", user, self, schedule_changes)
    end
  end

  def overbook?
    limit = max_size
    !limit.nil? && participations.confirmed.count > limit
  end

  def end_at_after_start_at
    starts = start_at
    ends = end_at
    return if starts.nil? || ends.nil?

    if ends <= starts
      errors.add(:end_at, "\u306F\u958B\u59CB\u65E5\u6642\u3088\u308A\u5F8C\u306B\u3057\u3066\u304F\u3060\u3055\u3044")
    end
  end
end
