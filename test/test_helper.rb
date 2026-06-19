ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# ---------------------------------------------------------------------------
# Story 1.3: OmniAuth test mode (added in ATDD red phase)
# ---------------------------------------------------------------------------
# OmniAuth.config.test_mode = true prevents real OIDC network calls in tests.
# Uncomment the block below when Story 1.3 implementation begins (Task 3).
# Activating this now (before OmniAuth is in the middleware stack) will raise
# a NameError — keep it commented until the gem initializer exists.
# ---------------------------------------------------------------------------
# OmniAuth.config.test_mode = true

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

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
#
# Activate these helpers once OmniAuth.config.test_mode = true is uncommented
# above and the OmniAuth initializer exists (config/initializers/omniauth.rb).
# ---------------------------------------------------------------------------
# def stub_omniauth(uid: "omniauth-uid-test-001", email: "testuser@example.test")
#   OmniAuth.config.mock_auth[:openid_connect] = OmniAuth::AuthHash.new(
#     provider: "openid_connect",
#     uid: uid,
#     info: OmniAuth::AuthHash::InfoHash.new(email: email)
#   )
# end
#
# def stub_omniauth_failure
#   OmniAuth.config.mock_auth[:openid_connect] = :invalid_credentials
# end
