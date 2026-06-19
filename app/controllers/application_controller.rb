# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Story 1.3: Session timeout constant (FR-093 — fixed 30-minute inactivity, NOT configurable)
  INACTIVITY_TIMEOUT = 30.minutes.to_i

  # Story 1.3: Authentication helpers
  helper_method :current_user

  # Enforce session timeout BEFORE require_authentication in before_action chain
  before_action :enforce_session_timeout
  before_action :require_authentication

  # Story 1.4: Enforce authorization on every action. Controllers with no Pundit subject
  # (sessions, temporary home) must call skip_after_action :verify_authorized.
  # This project does NOT use Devise — do NOT use `unless: :devise_controller?`.
  after_action :verify_authorized

  rescue_from Pundit::NotAuthorizedError, with: :handle_not_authorized

  # Returns the currently authenticated user, or nil for unauthenticated requests.
  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  # Redirects unauthenticated visitors to the sign-in page.
  # Stores the original request path in session[:return_to] for post-login redirect.
  def require_authentication
    return if current_user

    session[:return_to] = request.fullpath
    redirect_to new_session_path
  end

  # Enforces 30-minute sliding-window inactivity timeout (FR-093).
  # Must be called BEFORE require_authentication.
  def enforce_session_timeout
    return unless session[:user_id]

    last_active = session[:last_active_at].to_i
    # Fail closed: an authenticated session with a missing/zero last_active_at
    # (legacy or tampered cookie) is treated as expired rather than never-expiring.
    if last_active <= 0 || Time.current.to_i - last_active > INACTIVITY_TIMEOUT
      reset_session
      flash[:alert] = t("flash.session_timeout")
      redirect_to new_session_path and return
    end

    session[:last_active_at] = Time.current.to_i
  end

  # Returns the safe post-login redirect URL from session.
  # Validates it is a relative path to prevent open redirect attacks.
  def safe_return_to
    url = session.delete(:return_to)
    return unless url

    # Decode percent-encoding before validation so that "/%2Fevil.com" (which
    # decodes to "//evil.com" in the browser) is caught by the guard below.
    decoded = URI::DEFAULT_PARSER.unescape(url) rescue nil
    return unless decoded

    # Only allow a single-leading-slash relative path. Reject:
    #   "//host"   — protocol-relative URL
    #   "/\host"   — backslash-normalized (browsers treat as "//host")
    #   "/\/host"  — slash-backslash-slash variant (use single-quoted literal)
    return unless decoded.start_with?("/")
    return if decoded.start_with?("//", "/\\", '/\/')

    url
  end

  private

  # Story 1.4: Handle Pundit authorization failures.
  # Sets an alert flash and redirects the unauthorized user to root_path
  # (an HTTP 302 redirect, not a 403 body — root is skip-listed so it never
  # itself re-raises). A hard 403 response is intentionally not used here so
  # the user lands on a usable page rather than a bare error.
  def handle_not_authorized
    flash[:alert] = t("flash.not_authorized")
    redirect_to root_path
  end
end
