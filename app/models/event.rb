class Event < ApplicationRecord
  attr_accessor :start_at_date, :start_at_time, :end_at_date, :end_at_time

  include Cancellable

  belongs_to :organizer, class_name: "User"
  has_many :participations, dependent: :restrict_with_error
  has_many :participants, through: :participations, source: :user

  validates :start_at, presence: true
  validates :end_at, presence: true
  validates :name, presence: true
  validate :end_at_after_start_at

  default_scope { where.missing(:cancellation) }

  def organizer?(user)
    organizer_id == user&.id
  end

  def full?
    max_size && participations.count >= max_size
  end

  def receive(user)
    return if full?

    transaction do
      participation = participations.create!(user:)

      raise ActiveRecord::Rollback if overbook?

      participation
    end
  end

  private

  def overbook?
    max_size && participations.count > max_size
  end

  def end_at_after_start_at
    return if start_at.blank? || end_at.blank?

    if end_at <= start_at
      errors.add(:end_at, "\u306F\u958B\u59CB\u65E5\u6642\u3088\u308A\u5F8C\u306B\u3057\u3066\u304F\u3060\u3055\u3044")
    end
  end
end
