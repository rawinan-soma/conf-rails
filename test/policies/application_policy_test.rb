# frozen_string_literal: true

# Tests — Story 1.4: Capacities, Admin Role & Pundit Authorization Baseline
# Test Level: Unit (Policy)
#
# Acceptance Criteria Covered:
#   AC-1: Every authenticated user has organizer + attendee capacities by default
#   AC-2: Every controller action authorized through a Pundit policy; 403 on denial
#   AC-3: Admin user gets system-wide read access; no create/approve/edit of others' bookings

require "test_helper"

class ApplicationPolicyTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # Setup: fixtures from Story 1.3 (users.yml already committed)
  # ---------------------------------------------------------------------------

  # ---------------------------------------------------------------------------
  # AC-2: ApplicationPolicy deny-by-default for all CRUD actions (P0, FR-094)
  # Each policy action must return false for a plain user — safe baseline.
  # ---------------------------------------------------------------------------

  DENY_BY_DEFAULT_ACTIONS = %w[index? show? create? new? update? edit? destroy?].freeze

  DENY_BY_DEFAULT_ACTIONS.each do |action|
    test "[P0] ApplicationPolicy##{action} returns false for a plain user on a generic record" do
      user   = users(:regular_user)
      policy = ApplicationPolicy.new(user, Object.new)

      assert_equal false, policy.public_send(action),
                   "ApplicationPolicy##{action} must deny all requests by default (deny-by-default baseline)"
    end
  end

  # ---------------------------------------------------------------------------
  # AC-2: Scope#resolve raises NotImplementedError (forces subclass impl) (P0)
  # ---------------------------------------------------------------------------

  test "[P0] ApplicationPolicy::Scope#resolve raises NotImplementedError for base class" do
    user  = users(:regular_user)
    scope = ApplicationPolicy::Scope.new(user, Object.new)

    assert_raises(NotImplementedError,
                  "ApplicationPolicy::Scope#resolve must raise NotImplementedError to prevent silent misconfiguration") do
      scope.resolve
    end
  end

  # ---------------------------------------------------------------------------
  # AC-1 + AC-3: admin? predicate on User (P1)
  # Capacities: user.present? = organizer+attendee; user.admin? = admin capacity
  # NOTE: Full AC-3 enforcement (BookingPolicy, RegistrationPolicy) is in Stories 2.1/3.1
  # ---------------------------------------------------------------------------

  test "[P1] admin? returns false for a regular user (organizer+attendee only)" do
    user = users(:regular_user)

    # Every user has organizer+attendee capacities — expressed as user.present? in policies.
    # admin? is the only elevated flag.
    assert_not user.admin?,
               "regular_user fixture must have admin: false — organizer+attendee capacities only"
  end

  test "[P1] admin? returns true for an admin user" do
    user = users(:admin_user)

    assert user.admin?,
           "admin_user fixture must have admin: true"
  end

  # ---------------------------------------------------------------------------
  # AC-2: ApplicationPolicy initializes user and record attributes (P1)
  # ---------------------------------------------------------------------------

  test "[P1] ApplicationPolicy exposes user and record via attr_reader" do
    user   = users(:regular_user)
    record = Object.new
    policy = ApplicationPolicy.new(user, record)

    assert_equal user,   policy.user,   "ApplicationPolicy must expose @user via attr_reader"
    assert_equal record, policy.record, "ApplicationPolicy must expose @record via attr_reader"
  end

  # ---------------------------------------------------------------------------
  # AC-3 STUB: admin capacity asserted at policy layer (P1)
  # Full AC-3 deferred to Story 2.1 (BookingPolicy) and Story 3.1 (RegistrationPolicy)
  # ---------------------------------------------------------------------------

  test "[P1] admin user has admin? true — structural prerequisite for AC-3 BookingPolicy and RegistrationPolicy" do
    # AC-3: 'Given an admin user, when they read bookings/registrant data, then policy grants
    # system-wide read access, but no create/approve/edit of others' bookings.'
    #
    # This test validates the structural prerequisite: admin? returns true on the admin fixture.
    # Full AC-3 enforcement validated in:
    #   Story 2.1 — BookingPolicy (admin read all, no approve/edit of others)
    #   Story 3.1 — RegistrationPolicy (admin read all registrants)
    #
    # TODO: Story 2.1 — BookingPolicy must add: admin user can index? and show? any booking
    # TODO: Story 3.1 — RegistrationPolicy must add: admin user can index? and show? any registration

    admin = users(:admin_user)
    policy = ApplicationPolicy.new(admin, Object.new)

    assert admin.admin?,
           "admin_user must have admin: true — prerequisite for AC-3 BookingPolicy allow rules"

    # Base policy denies admin too (deny-by-default). Resource policies opt-in.
    assert_equal false, policy.show?,
                 "ApplicationPolicy base must deny even admin users — subclass BookingPolicy grants admin read in Story 2.1"
  end
end
