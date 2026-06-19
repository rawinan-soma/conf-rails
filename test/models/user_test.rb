# frozen_string_literal: true

# ATDD Red-Phase Tests — Story 1.3: OIDC Authentication & Sessions
# Test Level: Unit (Model)
#
# All tests are SKIPPED (TDD red phase).
# Remove the `skip` line for each test as its corresponding task is implemented,
# confirm the test FAILS first, then passes after implementation.
#
# Acceptance Criteria Covered:
#   AC-1: User is found or created by IdP subject; session starts
#
# Activation Map:
#   Task 1 (User model + migration): activate all tests in this file

require "test_helper"

class UserTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # AC-1: User.find_or_create_by_omniauth — happy path (P0, FR-090)
  # ---------------------------------------------------------------------------

  test "[P0] find_or_create_by_omniauth creates a new user from a valid auth hash" do
    auth = OmniAuth::AuthHash.new(
      provider: "openid_connect",
      uid: "new-uid-test-001",
      info: { email: "newuser@example.test" }
    )

    assert_difference "User.count", 1 do
      user = User.find_or_create_by_omniauth(auth)
      assert user.persisted?, "User must be persisted after find_or_create_by_omniauth"
      assert_equal "openid_connect", user.provider
      assert_equal "new-uid-test-001", user.uid
      assert_equal "newuser@example.test", user.email
    end
  end

  test "[P0] find_or_create_by_omniauth returns existing user for the same provider/uid" do
    # Use a UID not in fixtures.yml to ensure find_or_create actually creates, then finds.
    auth = OmniAuth::AuthHash.new(
      provider: "openid_connect",
      uid: "fresh-uid-for-idempotency-test",
      info: { email: "idempotency@example.test" }
    )

    # First call — must create
    user_first = User.find_or_create_by_omniauth(auth)
    assert user_first.persisted?, "First call must persist the user"

    assert_no_difference "User.count" do
      user_second = User.find_or_create_by_omniauth(auth)
      assert_equal user_first.id, user_second.id,
                   "find_or_create_by_omniauth must return the same user on repeated calls"
    end
  end

  test "[P0] find_or_create_by_omniauth does NOT update email on subsequent logins" do
    # Use a UID not in fixtures.yml so the first call truly creates the user.
    uid = "fresh-uid-for-email-immutability-test"
    auth = OmniAuth::AuthHash.new(
      provider: "openid_connect",
      uid: uid,
      info: { email: "original@example.test" }
    )
    User.find_or_create_by_omniauth(auth)

    # Simulate IdP returning a changed email — must NOT overwrite stored email
    auth_with_new_email = OmniAuth::AuthHash.new(
      provider: "openid_connect",
      uid: uid,
      info: { email: "changed@example.test" }
    )
    user = User.find_or_create_by_omniauth(auth_with_new_email)

    assert_equal "original@example.test", user.reload.email,
                 "Email must NOT be silently updated on subsequent logins (FR-095 design)"
  end

  # ---------------------------------------------------------------------------
  # AC-1: User model validations (P1, FR-090)
  # ---------------------------------------------------------------------------

  test "[P1] user is invalid without provider" do
    user = User.new(uid: "uid-001", email: "test@example.test")
    assert_not user.valid?, "User without provider must be invalid"
    assert_includes user.errors[:provider], "can't be blank"
  end

  test "[P1] user is invalid without uid" do
    user = User.new(provider: "openid_connect", email: "test@example.test")
    assert_not user.valid?, "User without uid must be invalid"
    assert_includes user.errors[:uid], "can't be blank"
  end

  test "[P1] user is invalid without email" do
    user = User.new(provider: "openid_connect", uid: "uid-001")
    assert_not user.valid?, "User without email must be invalid"
    assert_includes user.errors[:email], "can't be blank"
  end

  test "[P1] user is invalid when provider/uid combination is not unique" do
    User.create!(
      provider: "openid_connect",
      uid: "duplicate-uid-001",
      email: "first@example.test"
    )

    duplicate = User.new(
      provider: "openid_connect",
      uid: "duplicate-uid-001",
      email: "second@example.test"
    )
    assert_not duplicate.valid?, "Duplicate provider/uid must fail uniqueness validation"
    assert_includes duplicate.errors[:uid], "has already been taken"
  end

  # ---------------------------------------------------------------------------
  # AC-1: admin? predicate (P1, FR-090 — used by Pundit in Story 1.4)
  # ---------------------------------------------------------------------------

  test "[P1] admin? returns false for a regular user" do
    user = User.new(provider: "openid_connect", uid: "uid-001", email: "test@example.test", admin: false)
    assert_not user.admin?, "admin? must return false for non-admin users"
  end

  test "[P1] admin? returns true for an admin user" do
    user = User.new(provider: "openid_connect", uid: "uid-002", email: "admin@example.test", admin: true)
    assert user.admin?, "admin? must return true for admin users"
  end

  # ---------------------------------------------------------------------------
  # AC-1: profile_complete? predicate (P1, FR-090 — used by first-login gate in Story 1.5)
  # ---------------------------------------------------------------------------

  test "[P1] profile_complete? returns false when profile_completed_at is nil" do
    user = User.new(
      provider: "openid_connect",
      uid: "uid-003",
      email: "incomplete@example.test",
      profile_completed_at: nil
    )
    assert_not user.profile_complete?,
               "profile_complete? must return false when profile_completed_at is nil"
  end

  test "[P1] profile_complete? returns true when profile_completed_at is set" do
    user = User.new(
      provider: "openid_connect",
      uid: "uid-004",
      email: "complete@example.test",
      profile_completed_at: Time.current
    )
    assert user.profile_complete?,
           "profile_complete? must return true when profile_completed_at is present"
  end

  # ---------------------------------------------------------------------------
  # AC-1: User.admins scope (P2, used by Story 4.6)
  # ---------------------------------------------------------------------------

  test "[P2] User.admins scope returns only admin users" do
    # Use UIDs distinct from fixtures to avoid ambiguity in assertions
    User.create!(provider: "openid_connect", uid: "uid-admin-scope-001", email: "scopeadmin@example.test", admin: true)
    User.create!(provider: "openid_connect", uid: "uid-regular-scope-001", email: "scopereg@example.test", admin: false)

    assert User.admins.exists?(uid: "uid-admin-scope-001"),
           "User.admins scope must include the newly created admin user"
    refute User.admins.exists?(uid: "uid-regular-scope-001"),
           "User.admins scope must exclude the non-admin user"
    assert User.admins.all?(&:admin?),
           "User.admins scope must return only users where admin is true"
  end
end
