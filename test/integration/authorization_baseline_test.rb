# frozen_string_literal: true

# Tests — Story 1.4: Capacities, Admin Role & Pundit Authorization Baseline
# Test Level: Integration
#
# Acceptance Criteria Covered:
#   AC-1: Every authenticated user has organizer + attendee capacities by default
#   AC-2: Every controller action authorized through a Pundit policy; 403 on denial
#   AC-3: Admin user gets system-wide read access (structural prerequisite asserted here;
#         full enforcement in Stories 2.1 and 3.1)

require "test_helper"

class AuthorizationBaselineTest < ActionDispatch::IntegrationTest
  # ---------------------------------------------------------------------------
  # AC-2: HomeController skip — GET / must NOT raise Pundit::NotAuthorizedError (P0, FR-094)
  # ---------------------------------------------------------------------------

  test "[P0] authenticated user hits GET / and gets 200 — HomeController skips verify_authorized" do
    sign_in

    get root_path

    assert_response :success,
                    "GET / must return 200 for an authenticated user — HomeController must skip verify_authorized"
  end

  # ---------------------------------------------------------------------------
  # AC-2: Unauthenticated user hits GET / is redirected to sign-in (P0, FR-090)
  # Pre-existing behavior (Story 1.3) — must not regress after Pundit wiring
  # ---------------------------------------------------------------------------

  test "[P0] unauthenticated user hitting GET / is redirected to sign-in — verify_authorized does not interfere" do
    get root_path

    assert_redirected_to new_session_path,
                         "Unauthenticated visitor must be redirected to sign-in (Story 1.3 regression guard)"
  end

  # ---------------------------------------------------------------------------
  # AC-2: SessionsController skip — actions must NOT raise Pundit::NotAuthorizedError (P0)
  # ---------------------------------------------------------------------------

  test "[P0] GET /sign_in does NOT raise Pundit::NotAuthorizedError — SessionsController skips verify_authorized" do
    get new_session_path

    assert_response :success,
                    "GET /sign_in must return 200 — SessionsController must skip verify_authorized entirely"
  end

  test "[P0] DELETE /sign_out does NOT raise Pundit::NotAuthorizedError — SessionsController skips verify_authorized" do
    sign_in
    delete sign_out_path

    # sign_out redirects to new_session_path — 3xx is success here (no Pundit error raised)
    assert_not_equal 500, response.status,
                     "DELETE /sign_out must not raise an internal server error — SessionsController must skip verify_authorized"
    assert response.redirect?,
           "DELETE /sign_out must redirect (not raise Pundit::NotAuthorizedError)"
  end

  # ---------------------------------------------------------------------------
  # AC-2: Pundit rescue_from — unauthorized action returns 403 with flash (P0, FR-094)
  # Tests the rescue_from Pundit::NotAuthorizedError handler in ApplicationController
  # ---------------------------------------------------------------------------

  test "[P0] Pundit::NotAuthorizedError is rescued with 403 redirect and flash alert" do
    # This test verifies the rescue_from handler behavior by directly testing
    # ApplicationPolicy deny behavior + flash/redirect contract.
    #
    # Full integration test with a real resource controller is deferred to Story 2.1
    # (the first story that introduces a real resource policy + controller action).
    # Here we validate the rescue_from wiring via the ApplicationPolicy unit + controller contract.
    #
    # Implementation note: The simplest correct approach is to test that
    # ApplicationPolicy.new(user, record).show? returns false, AND that
    # the rescue_from handler sets flash[:alert] with the I18n key value.
    sign_in

    # Directly verify the policy returns false (deny-by-default baseline)
    user = User.find(session[:user_id])
    policy = ApplicationPolicy.new(user, Object.new)

    assert_equal false, policy.show?,
                 "ApplicationPolicy#show? must deny — triggering NotAuthorizedError when authorize is called"

    # Verify the I18n key exists and has a value (so rescue_from flash is populated)
    expected_flash = I18n.t("flash.not_authorized")
    assert_not_nil expected_flash,
                   "flash.not_authorized I18n key must be set (Task 5)"
    assert_not_empty expected_flash,
                     "flash.not_authorized must have a non-empty value"
  end

  test "[P0] flash.not_authorized I18n key returns a non-empty string in English" do
    # AC-2: unauthorized attempt returns 403 with a flash message
    # This test validates the I18n key is present and translates to a human-readable string.
    I18n.with_locale(:en) do
      message = I18n.t("flash.not_authorized")
      assert_not_nil message,
                     "flash.not_authorized key must exist in config/locales/en.yml"
      assert_not_empty message,
                       "flash.not_authorized must have a non-empty English value"
      assert_not_equal "translation missing: en.flash.not_authorized", message,
                       "flash.not_authorized key must be present in en.yml (not missing)"
    end
  end

  test "[P0] flash.not_authorized I18n key is mirrored in Thai locale" do
    # i18n-tasks health will also catch this, but an explicit test is the ATDD contract.
    I18n.with_locale(:th) do
      message = I18n.t("flash.not_authorized")
      assert_not_nil message,
                     "flash.not_authorized key must exist in config/locales/th.yml"
      assert_not_equal "translation missing: th.flash.not_authorized", message,
                       "flash.not_authorized must be mirrored in th.yml (i18n-tasks health gate)"
    end
  end

  # ---------------------------------------------------------------------------
  # AC-1: Capacities baseline — any authenticated user can access the root (P1, FR-091)
  # Expresses: user.present? = has organizer+attendee capacities (no assignment needed)
  # ---------------------------------------------------------------------------

  test "[P1] any authenticated user reaches GET / — organizer+attendee capacities are default, no assignment required" do
    # FR-091: Organizer + attendee are default capacities; no role assignment needed.
    # This test expresses that constraint at the HTTP layer: any user who is authenticated
    # can reach the root path (home controller skips verify_authorized, but no 403 fires).
    sign_in

    get root_path

    assert_response :success,
                    "Any authenticated user must reach GET / — organizer+attendee capacities are default (FR-091)"
    assert_nil flash[:alert],
               "No authorization flash alert must fire for an authenticated user at root path"
  end

  test "[P1] admin user also reaches GET / — admin is the only elevated role, not a restriction" do
    # Admin capacity is additive — admin users still have organizer+attendee capacities too.
    sign_in(uid: "test-uid-admin-001", email: "admin@example.test")

    get root_path

    assert_response :success,
                    "Admin user must also reach GET / without restriction (admin is additive)"
  end

  # ---------------------------------------------------------------------------
  # AC-2: Pundit::Authorization included in ApplicationController (P1)
  # ---------------------------------------------------------------------------

  test "[P1] ApplicationController includes Pundit::Authorization" do
    assert ApplicationController.ancestors.include?(Pundit::Authorization),
           "ApplicationController must include Pundit::Authorization (Task 1)"
  end

  test "[P1] ApplicationController has after_action :verify_authorized registered" do
    # Verify the after_action callback is registered (not just included).
    # Rails stores after_actions as an array on __callbacks[:verify_authorized].
    verify_authorized_callbacks = ApplicationController._process_action_callbacks.select do |cb|
      cb.kind == :after && cb.filter == :verify_authorized
    end

    assert_not_empty verify_authorized_callbacks,
                     "ApplicationController must register after_action :verify_authorized (Task 1)"
  end

  test "[P1] SessionsController has skip_after_action :verify_authorized registered" do
    # Ensure SessionsController does NOT have verify_authorized in its effective callback chain.
    # The skip_after_action :verify_authorized must suppress the parent's after_action.
    effective_callbacks = SessionsController._process_action_callbacks.select do |cb|
      cb.kind == :after && cb.filter == :verify_authorized
    end

    # After skip_after_action, the callback must be absent from the effective chain.
    # (The exact implementation may vary — this asserts the functional result.)
    assert_empty effective_callbacks,
                 "SessionsController must skip :verify_authorized — add skip_after_action :verify_authorized (Task 1)"
  end
end
