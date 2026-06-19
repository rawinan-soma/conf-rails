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
  # Find-first strategy: existing users (the overwhelmingly common case after first
  # login) are found with a single SELECT. New users are created with an INSERT;
  # the DB unique index on (provider, uid) is the safety net for the rare concurrent
  # first-login race — RecordNotUnique is rescued and the row is re-fetched.
  # Note: create_or_find_by is NOT used here because Rails model validations
  # (e.g. email uniqueness) can prevent the INSERT from reaching the DB, causing
  # create_or_find_by to return an invalid unpersisted record instead of finding
  # the existing row.
  def self.find_or_create_by_omniauth(auth)
    return nil if auth.nil?

    provider = auth.provider
    uid = auth.uid
    return nil if provider.blank? || uid.blank?

    # Fast path: user already exists (every login after the first)
    existing = find_by(provider: provider, uid: uid)
    return existing if existing

    # Slow path: first-ever login — attempt to create
    create!(provider: provider, uid: uid, email: auth.info&.email)
  rescue ActiveRecord::RecordNotUnique
    # Concurrent first-login: another process already created the row.
    find_by(provider: provider, uid: uid)
  rescue ActiveRecord::RecordInvalid
    # Validation failed (e.g. blank email) — return an unsaved instance so the
    # caller's `user&.persisted?` guard routes to the failure flow.
    nil
  end
end
