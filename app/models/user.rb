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
  # Returns nil when:
  #   - auth hash is nil or missing required claims (provider/uid)
  #   - the IdP omits a required attribute (e.g. email) — RecordInvalid
  #   - a DB-level uniqueness conflict cannot be resolved (see RecordNotUnique below)
  # Callers MUST check `user&.persisted?` before starting a session.
  #
  # Find-first strategy: existing users (the overwhelmingly common case after first
  # login) are found with a single SELECT. New users are created with an INSERT.
  #
  # RecordNotUnique handling: two unique indexes exist on the users table:
  #   1. (provider, uid) — the primary identity key
  #   2. email           — for case-insensitive lookup (Story 1.3 requirement)
  # A RecordNotUnique can be raised by either index:
  #   - (provider, uid) conflict: concurrent first-login race → re-fetch by (provider, uid)
  #   - email conflict: different provider/uid shares an email with an existing account
  #     → re-fetch by (provider, uid) returns nil → method returns nil → auth fails safely
  #     (this is a known design constraint documented in deferred-work.md)
  # Note: create_or_find_by is NOT used because Rails model validations can prevent the
  # INSERT from reaching the DB, causing it to return an invalid unpersisted record.
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
    # Either a concurrent first-login race (provider+uid conflict) or an email
    # uniqueness conflict. Re-fetch by (provider, uid): returns the existing user
    # for the race case, or nil for the email-conflict case (caller routes to failure).
    find_by(provider: provider, uid: uid)
  rescue ActiveRecord::RecordInvalid
    # Validation failed (e.g. blank email from IdP) — nil signals the caller to
    # route to the auth failure flow via the `user&.persisted?` guard.
    nil
  end
end
