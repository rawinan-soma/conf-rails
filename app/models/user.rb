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
  #
  # Returns nil if the auth hash is missing required identity claims (provider/uid).
  # Returns an unpersisted (invalid) User when the IdP omits a required attribute
  # such as email — callers MUST check `persisted?` before starting a session.
  #
  # Uses create_or_find_by for race safety: the DB unique index on (provider, uid)
  # is the source of truth, so concurrent first-logins resolve to the same row
  # instead of raising ActiveRecord::RecordNotUnique.
  def self.find_or_create_by_omniauth(auth)
    return nil if auth.nil?

    provider = auth.provider
    uid = auth.uid
    return nil if provider.blank? || uid.blank?

    create_or_find_by(provider: provider, uid: uid) do |u|
      u.email = auth.info&.email
    end
  rescue ActiveRecord::RecordNotUnique
    # A non-(provider,uid) unique constraint (e.g. the email index) was violated.
    # Treat as an authentication failure rather than crashing the callback.
    find_by(provider: provider, uid: uid)
  end
end
