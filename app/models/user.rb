# frozen_string_literal: true

class User < ApplicationRecord
  # Validations
  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  # Scopes
  scope :admins, -> { where(admin: true) }

  # Predicates

  # Returns true if the user has admin privileges.
  # Used by Pundit policies (Story 1.4).
  def admin?
    admin
  end

  # Returns true when the user has completed their profile.
  # Used by the first-login gate (Story 1.5).
  def profile_complete?
    profile_completed_at.present?
  end

  # Finds an existing user by (provider, uid) or creates a new one.
  # Email is set on creation only — NOT updated on subsequent logins (FR-095 design).
  def self.find_or_create_by_omniauth(auth)
    find_or_create_by(provider: auth.provider, uid: auth.uid) do |u|
      u.email = auth.info.email
    end
  end
end
