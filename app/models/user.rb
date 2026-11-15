class User < ApplicationRecord
  has_many :organizing_events, class_name: "Event", foreign_key: :organizer_id, dependent: :destroy
  has_many :participations, dependent: :nullify

  validates :name, presence: true
  validates :discord_user_id, presence: true

  def self.sign_in_with_discord(profile)
    user = find_or_initialize_by(discord_user_id: profile.fetch("id"))
    user.name = profile["global_name"].presence || profile.fetch("username") if user.new_record?
    user.discord_avatar = profile["avatar"]
    user.save!
    user
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def avatar_url
    return if discord_avatar.blank?

    "https://cdn.discordapp.com/avatars/#{discord_user_id}/#{discord_avatar}.png?size=64"
  end

  def participatable?(event)
    !participations.find_by(event_id: event.id)
  end
end
