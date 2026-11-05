class User::PasswordCredential < ApplicationRecord
  has_secure_password

  belongs_to :user

  validates :email, presence: true, format: { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i }, uniqueness: { case_sensitive: false }
end
