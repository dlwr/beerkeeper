class User < ApplicationRecord
  has_one :password_credential, dependent: :destroy, autosave: true, validate: false

  has_many :organizing_events, class_name: "Event", foreign_key: :organizer_id, dependent: :destroy
  has_many :participations, dependent: :nullify

  validates :name, presence: true
  validate :password_credential_must_be_valid

  delegate :email, :password, :password_confirmation, :password_reset_token, to: :password_credential, allow_nil: true

  def self.sign_in_with_discord(profile)
    user = find_or_initialize_by(discord_user_id: profile.fetch("id"))
    user.name = profile["global_name"].presence || profile.fetch("username") if user.new_record?
    user.discord_avatar = profile["avatar"]
    user.save!
    user
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def self.find_by_email(email)
    joins(:password_credential).find_by(user_password_credentials: { email: })
  end

  def self.find_by_password_reset_token(token)
    User::PasswordCredential.find_by_password_reset_token(token)&.user
  end

  def email=(email)
    credential.email = email
  end

  def password=(password)
    credential.password = password
  end

  def password_confirmation=(password_confirmation)
    credential.password_confirmation = password_confirmation
  end

  def authenticate(password)
    password_credential&.authenticate(password) && self
  end

  def avatar_url
    return if discord_user_id.blank? || discord_avatar.blank?

    "https://cdn.discordapp.com/avatars/#{discord_user_id}/#{discord_avatar}.png?size=64"
  end

  def participatable?(event)
    !participations.find_by(event_id: event.id)
  end

  private

  def credential
    password_credential || build_password_credential
  end

  def password_credential_must_be_valid
    return if discord_user_id.present? && password_credential.nil?
    return if credential.valid?

    credential.errors.each { |error| errors.import(error) }
  end
end
