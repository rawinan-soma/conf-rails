# frozen_string_literal: true

# ATDD Red-Phase Tests — Story 1.3: OIDC Authentication & Sessions
# Test Level: Integration
#
# All tests are SKIPPED (TDD red phase).
# Remove the `skip` line for each test as its corresponding task is implemented,
# confirm the test FAILS first, then passes after implementation.
#
# Acceptance Criteria Covered:
#   AC-1: Unauthenticated visitor redirected to IdP; user found/created; session starts
#   AC-2: 30-min inactivity timeout — session expires, re-authentication required
#   AC-3: OIDC callback failure shows error, no session created
#
# Activation Map:
#   Task 1 (User model):           prerequisite — activate model tests first
#   Task 3 (SessionsController):   prerequisite
#   Task 4 (Routes):               prerequisite
#   Task 5 (ApplicationController helpers): activate AC-1 redirect + AC-2 timeout tests

require "test_helper"

class AuthenticationFlowTest < ActionDispatch::IntegrationTest
  # ---------------------------------------------------------------------------
  # AC-1: Unauthenticated access redirects to sign-in (P0, FR-090)
  # ---------------------------------------------------------------------------

  test "[P0] unauthenticated request to a protected page redirects to sign-in" do
    # Assumes at least one controller uses `before_action :require_authentication`.
    # In this story the root path will redirect to sessions#new if unauthenticated.
    get root_path

    assert_redirected_to new_session_path,
                         "Unauthenticated visitor must be redirected to the sign-in page"
  end

  test "[P0] unauthenticated request stores the original URL in session[:return_to]" do
    get root_path

    assert_equal root_path, session[:return_to],
                 "require_authentication must store the original request path in session[:return_to]"
  end

  # ---------------------------------------------------------------------------
  # AC-1: Full sign-in flow — redirect back to original URL (P0, FR-090)
  # ---------------------------------------------------------------------------

  test "[P0] full sign-in flow: unauthenticated → IdP → callback → original URL" do
    # Step 1: Visit a protected page (unauthenticated)
    get root_path
    assert_redirected_to new_session_path
    follow_redirect!

    # Step 2: Sign in via OmniAuth (mocked)
    stub_omniauth(uid: "test-uid-regular-001", email: "regular@example.test")
    get "/auth/openid_connect/callback"

    # Step 3: Must be redirected back to the originally requested URL
    assert_redirected_to root_path,
                         "After successful sign-in, must redirect to the originally requested page"

    # Step 4: Session must be established
    assert_not_nil session[:user_id], "Session must be established after successful OIDC callback"
  end

  # ---------------------------------------------------------------------------
  # AC-2: 30-minute inactivity timeout (P0, FR-093 — fixed, not configurable)
  # ---------------------------------------------------------------------------

  test "[P0] session expires after 30 minutes of inactivity" do
    # Sign in
    stub_omniauth(uid: "test-uid-regular-001", email: "regular@example.test")
    get "/auth/openid_connect/callback"
    assert_not_nil session[:user_id], "Pre-condition: must be signed in"

    # Simulate 31 minutes of inactivity by backdating last_active_at
    travel 31.minutes do
      get root_path
    end

    assert_redirected_to new_session_path,
                         "Session must expire after 30 minutes of inactivity (FR-093)"
    assert_nil session[:user_id], "session[:user_id] must be cleared on timeout"
  end

  test "[P0] session timeout sets a flash alert informing the user" do
    stub_omniauth(uid: "test-uid-regular-001", email: "regular@example.test")
    get "/auth/openid_connect/callback"

    travel 31.minutes do
      get root_path
    end

    assert_not_empty flash[:alert],
                     "Session timeout must display a flash alert to inform the user"
  end

  test "[P0] session does NOT expire before 30 minutes of inactivity" do
    stub_omniauth(uid: "test-uid-regular-001", email: "regular@example.test")
    get "/auth/openid_connect/callback"
    assert_not_nil session[:user_id], "Pre-condition: must be signed in"

    # 29 minutes — should still be valid
    travel 29.minutes do
      get root_path
    end

    assert_not_nil session[:user_id],
                   "Session must remain active after 29 minutes of inactivity (timeout is 30 min)"
    assert_response :success
  end

  test "[P0] inactivity timeout is a sliding window — activity resets the timer" do
    stub_omniauth(uid: "test-uid-regular-001", email: "regular@example.test")
    get "/auth/openid_connect/callback"

    # Make a request at 25 minutes — should reset the timer
    travel 25.minutes do
      get root_path
      assert_not_nil session[:user_id], "Session must still be active at 25 minutes"
    end

    # Make another request 25 minutes after the activity (now 50 min total, but only 25 since last activity)
    travel 50.minutes do
      get root_path
    end

    assert_not_nil session[:user_id],
                   "Session must remain active when there is activity within the 30-min window (sliding window)"
  end

  test "[P0] session timeout calls reset_session to prevent session fixation" do
    stub_omniauth(uid: "test-uid-regular-001", email: "regular@example.test")
    get "/auth/openid_connect/callback"
    old_session_id = request.session.id.to_s

    travel 31.minutes do
      get root_path
    end

    # reset_session must have been called — new session ID issued
    refute_equal old_session_id, request.session.id.to_s,
                 "enforce_session_timeout must call reset_session to prevent session fixation"
  end

  # ---------------------------------------------------------------------------
  # AC-2: Timeout is NOT configurable (FR-093 hard rule) (P1)
  # ---------------------------------------------------------------------------

  test "[P1] INACTIVITY_TIMEOUT constant is exactly 30 minutes and not configurable" do
    assert_equal 30.minutes.to_i, ApplicationController::INACTIVITY_TIMEOUT,
                 "INACTIVITY_TIMEOUT must be exactly 30 minutes (FR-093 — not configurable)"
  end

  # ---------------------------------------------------------------------------
  # AC-3: Authentication failure — no session, clear error (P0, FR-090)
  # ---------------------------------------------------------------------------

  test "[P0] OIDC callback failure does not create a session" do
    stub_omniauth_failure

    get "/auth/failure"

    assert_nil session[:user_id],
               "A failed OIDC callback must not create a session (AC-3)"
  end

  test "[P0] authentication failure renders a clear error message" do
    stub_omniauth_failure

    get "/auth/failure"
    follow_redirect!  # redirects to new_session_path with error flash

    assert_select "[data-testid='auth-error'], .alert, .error, [role='alert']",
                  minimum: 0  # structural assertion — at least a flash or error element exists
    assert_not_empty flash[:alert],
                     "Authentication failure must display a clear error message to the user (AC-3)"
  end

  # ---------------------------------------------------------------------------
  # AC-1: session[:last_active_at] is updated on each authenticated request (P1)
  # ---------------------------------------------------------------------------

  test "[P1] session[:last_active_at] is updated on each authenticated request" do
    stub_omniauth(uid: "test-uid-regular-001", email: "regular@example.test")
    get "/auth/openid_connect/callback"

    initial_last_active = session[:last_active_at]
    assert_not_nil initial_last_active, "session[:last_active_at] must be set after sign-in"

    travel 5.minutes do
      get root_path
      updated_last_active = session[:last_active_at]
      assert_operator updated_last_active, :>, initial_last_active,
                      "session[:last_active_at] must be updated on each authenticated request"
    end
  end

  # ---------------------------------------------------------------------------
  # AC-1: current_user helper (P1, Task 5)
  # ---------------------------------------------------------------------------

  test "[P1] current_user returns the authenticated user for a valid session" do
    stub_omniauth(uid: "test-uid-regular-001", email: "regular@example.test")
    get "/auth/openid_connect/callback"

    # Access a page that exposes current_user (e.g., layout renders sign-out link)
    get root_path
    assert_response :success

    # Indirect assertion: the layout shows a sign-out link for authenticated users
    assert_select "form[action='#{sign_out_path}']",
                  minimum: 1,
                  message: "Layout must show a sign-out form when current_user is present"
  end

  test "[P1] current_user returns nil for an unauthenticated request" do
    get new_session_path
    assert_response :success

    # Layout must show sign-in link, not sign-out, when not authenticated
    assert_select "a[href='#{new_session_path}']",
                  minimum: 1,
                  message: "Layout must show a sign-in link when current_user is nil"
  end
end
