ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# ---------------------------------------------------------------------------
# Story 1.3: OmniAuth test mode (activated — initializer exists)
# ---------------------------------------------------------------------------
# OmniAuth.config.test_mode = true prevents real OIDC network calls in tests.
# ---------------------------------------------------------------------------
OmniAuth.config.test_mode = true

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers.
    # :processes is required — each worker gets its own OmniAuth.config.mock_auth.
    # Do NOT change to :threads; OmniAuth mock state is not thread-safe.
    parallelize(workers: :number_of_processors, with: :processes)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Include ActiveJob::TestHelper globally so all test cases can use assert_enqueued_with,
    # perform_enqueued_jobs, assert_enqueued_emails, etc. (Story 1.6 / Task 8).
    include ActiveJob::TestHelper

    # Add more helper methods to be used by all tests here...
  end
end

# ---------------------------------------------------------------------------
# Story 1.3: OmniAuth mock helpers (used by controller + integration tests)
#
# Usage:
#   stub_omniauth                        # default uid + email
#   stub_omniauth(uid: "x", email: "y") # custom values
#   stub_omniauth_failure                # simulate IdP error
# ---------------------------------------------------------------------------
def stub_omniauth(uid: "omniauth-uid-test-001", email: "testuser@example.test")
  auth_hash = OmniAuth::AuthHash.new(
    provider: "openid_connect",
    uid: uid,
    info: OmniAuth::AuthHash::InfoHash.new(email: email)
  )
  OmniAuth.config.mock_auth[:openid_connect] = auth_hash
  # Also populate env_config so that integration tests hitting the callback URL
  # directly (without going through /auth/openid_connect first) get the mock hash
  # in request.env["omniauth.auth"] via the OmniAuth middleware test_mode flow.
  Rails.application.env_config["omniauth.auth"] = auth_hash
end

def stub_omniauth_failure
  OmniAuth.config.mock_auth[:openid_connect] = :invalid_credentials
  Rails.application.env_config.delete("omniauth.auth")
end

# ---------------------------------------------------------------------------
# Story 1.3: Sign-in convenience helper
# Stubs OmniAuth and hits the callback to establish a session in integration tests.
#
# Usage:
#   sign_in                                           # default test user
#   sign_in(uid: "other-uid", email: "x@example.test") # specific user
# ---------------------------------------------------------------------------
def sign_in(uid: "test-uid-regular-001", email: "regular@example.test")
  stub_omniauth(uid: uid, email: email)
  get "/auth/openid_connect/callback"
  assert_not_nil session[:user_id], "Pre-condition: sign_in must establish a session"
end
