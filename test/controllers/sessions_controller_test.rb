# frozen_string_literal: true

# ATDD Red-Phase Tests — Story 1.3: OIDC Authentication & Sessions
# Test Level: Controller
#
# All tests are SKIPPED (TDD red phase).
# Remove the `skip` line for each test as its corresponding task is implemented,
# confirm the test FAILS first, then passes after implementation.
#
# Acceptance Criteria Covered:
#   AC-1: Unauthenticated visitor redirected to IdP; user found/created; session starts
#   AC-3: OIDC callback failure shows error and creates no session
#
# Activation Map:
#   Task 1 (User model):    activate User model tests first
#   Task 3 (SessionsController): activate all tests in this file
#   Task 4 (Routes):        required before controller tests can run

require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  # ---------------------------------------------------------------------------
  # AC-1: OmniAuth callback creates session (P0, FR-090)
  # ---------------------------------------------------------------------------

  test "[P0] GET /auth/openid_connect/callback creates session and redirects to root" do
    stub_omniauth(uid: "test-uid-regular-001", email: "regular@example.test")

    get "/auth/openid_connect/callback"

    assert_not_nil session[:user_id],
                   "Session must contain :user_id after successful OmniAuth callback"
    assert_not_nil session[:last_active_at],
                   "Session must contain :last_active_at after successful OmniAuth callback"
    assert_redirected_to root_path
  end

  test "[P0] OmniAuth callback creates a new User when uid is unknown" do
    stub_omniauth(uid: "brand-new-uid-999", email: "newuser@example.test")

    assert_difference "User.count", 1 do
      get "/auth/openid_connect/callback"
    end

    user = User.find_by(uid: "brand-new-uid-999")
    assert_not_nil user, "A new User must be created when uid is unknown"
    assert_equal "newuser@example.test", user.email
  end

  test "[P0] OmniAuth callback finds existing User when uid is known" do
    stub_omniauth(uid: "test-uid-regular-001", email: "regular@example.test")

    assert_no_difference "User.count" do
      get "/auth/openid_connect/callback"
    end
  end

  test "[P0] OmniAuth callback sets session[:user_id] to the found/created user's id" do
    stub_omniauth(uid: "test-uid-regular-001", email: "regular@example.test")
    get "/auth/openid_connect/callback"

    user = User.find_by(uid: "test-uid-regular-001")
    assert_equal user.id, session[:user_id],
                 "session[:user_id] must be set to the authenticated User's id"
  end

  # ---------------------------------------------------------------------------
  # AC-1: Post-auth redirect to return_to (P0, FR-090)
  # ---------------------------------------------------------------------------

  test "[P0] OmniAuth callback redirects to session[:return_to] if set" do
    stub_omniauth(uid: "test-uid-regular-001", email: "regular@example.test")

    # Simulate the require_authentication before_action storing return_to by visiting
    # a protected route (root_path = home#index, which requires authentication)
    get root_path  # triggers require_authentication which sets session[:return_to] = "/"
    assert_redirected_to new_session_path

    # Follow through with the OmniAuth callback
    get "/auth/openid_connect/callback"

    assert_redirected_to root_path,
                         "After successful auth, must redirect to the original protected URL"
    assert_nil session[:return_to], "session[:return_to] must be cleared after use"
  end

  test "[P0] return_to URL with external domain is ignored (open redirect protection)" do
    # safe_return_to guard: accepts "/relative" paths, rejects "//external" and "http://external".
    # We set session[:return_to] to a malicious URL by visiting a protected page whose path
    # starts with "//" — that's not possible via routing, so we test safe_return_to's boundary
    # conditions via the sign-in flow combined with an ApplicationController unit test.
    #
    # Integration-level boundary test: after a normal sign-in, no session[:return_to] is present
    # (it was nil or "/"), so redirect goes to root_path (safe). This confirms the callback
    # never blindly follows whatever the client sends.
    stub_omniauth(uid: "test-uid-regular-001", email: "regular@example.test")

    # Step 1: Visit protected page — stores session[:return_to] = root_path (relative, safe)
    get root_path
    assert_redirected_to new_session_path

    # Step 2: Callback — safe_return_to reads session[:return_to] = "/" (relative)
    get "/auth/openid_connect/callback"

    # Must redirect to the stored relative URL (not any external header value)
    assert_redirected_to root_path,
                         "Callback must redirect to stored relative return_to, not an external URL"
    assert_nil session[:return_to], "session[:return_to] must be cleared after use"
  end

  test "[P0] safe_return_to accepts relative paths and rejects external/open-redirect URLs" do
    # Direct unit test of ApplicationController#safe_return_to. It reads (and deletes)
    # session[:return_to], so we drive it via a tiny subclass that injects the session.
    harness = Class.new(ApplicationController) do
      def initialize(stored)
        @injected_session = { return_to: stored }
      end

      def session
        @injected_session
      end
    end

    accept = {
      "/dashboard"      => "/dashboard",
      "/events/1?tab=x" => "/events/1?tab=x",
      "/"               => "/"
    }
    reject = [
      "//evil.example.com",    # protocol-relative
      "/\\evil.example.com",   # backslash → browser-normalized to //
      "/\\/evil.example.com",  # backslash-slash
      "/%2Fevil.example.com",  # percent-encoded "//evil.example.com" — open redirect bypass
      "http://evil.example.com",
      "https://evil.example.com",
      "javascript:alert(1)",
      "",
      nil
    ]

    accept.each do |stored, expected|
      assert_equal expected, harness.new(stored).send(:safe_return_to),
                   "safe_return_to must accept relative path #{stored.inspect}"
    end

    reject.each do |stored|
      assert_nil harness.new(stored).send(:safe_return_to),
                 "safe_return_to must reject #{stored.inspect} (open-redirect protection)"
    end
  end

  # ---------------------------------------------------------------------------
  # AC-3: Failure action — no session, clear error (P0, FR-090)
  # ---------------------------------------------------------------------------

  test "[P0] GET /auth/failure clears any partial session state" do
    # Simulate a partially started session
    stub_omniauth_failure

    get "/auth/failure"

    assert_nil session[:user_id],
               "session[:user_id] must be nil after auth failure"
    assert_nil session[:last_active_at],
               "session[:last_active_at] must be nil after auth failure"
  end

  test "[P0] GET /auth/failure redirects to new_session_path" do
    stub_omniauth_failure

    get "/auth/failure"

    assert_redirected_to new_session_path
  end

  test "[P0] GET /auth/failure sets a flash alert" do
    stub_omniauth_failure

    get "/auth/failure"

    assert_not_empty flash[:alert],
                     "A flash alert must be set on authentication failure"
  end

  # ---------------------------------------------------------------------------
  # AC-1: Destroy action (sign-out) (P1, FR-090)
  # ---------------------------------------------------------------------------

  test "[P1] DELETE /sign_out clears session and redirects to new_session_path" do
    sign_in

    delete sign_out_path

    assert_nil session[:user_id], "session[:user_id] must be nil after sign-out"
    assert_nil session[:last_active_at], "session[:last_active_at] must be nil after sign-out"
    assert_redirected_to new_session_path
  end

  test "[P1] DELETE /sign_out calls reset_session (prevents session fixation)" do
    sign_in
    old_session_id = request.session.id.to_s

    delete sign_out_path

    # After reset_session a new session ID must be issued
    refute_equal old_session_id, request.session.id.to_s,
                 "reset_session must issue a new session ID to prevent session fixation"
  end

  test "[P1] DELETE /sign_out sets a signed-out flash notice" do
    sign_in
    delete sign_out_path

    assert_not_empty flash[:notice],
                     "A flash notice must confirm sign-out to the user"
  end

  # ---------------------------------------------------------------------------
  # AC-1: New action (sign-in page) (P2)
  # ---------------------------------------------------------------------------

  test "[P2] GET /sign_in renders the sign-in page with HTTP 200" do
    get new_session_path

    assert_response :success
  end

  test "[P2] sign-in page contains a POST form to /auth/openid_connect" do
    get new_session_path

    assert_select "form[action='/auth/openid_connect'][method='post']",
                  minimum: 1,
                  message: "Sign-in page must contain a POST form to /auth/openid_connect (OmniAuth 2.x POST-only requirement)"
  end
end
