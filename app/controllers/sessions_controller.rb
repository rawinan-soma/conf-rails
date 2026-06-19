# frozen_string_literal: true

class SessionsController < ApplicationController
  # Skip session timeout and authentication checks on public session actions
  skip_before_action :enforce_session_timeout, only: %i[new create failure destroy]
  skip_before_action :require_authentication, only: %i[new create failure]

  # GET /sign_in
  def new
    # Renders the sign-in page with the IdP button
  end

  # GET /auth/openid_connect/callback
  # OmniAuth calls this after a successful IdP authentication
  def create
    auth = request.env["omniauth.auth"]
    user = User.find_or_create_by_omniauth(auth)

    # auth hash missing/invalid, or the user could not be persisted (e.g. the IdP
    # omitted a required claim like email, or a unique constraint was violated).
    # Do NOT start a session — route to the failure flow with a clear message.
    return redirect_to auth_failure_path unless user&.persisted?

    # Capture the post-login destination before reset_session clears it.
    destination = safe_return_to || root_path

    reset_session # rotate session id on login to prevent session fixation
    session[:user_id] = user.id
    session[:last_active_at] = Time.current.to_i

    redirect_to destination
  end

  # GET /auth/failure
  # OmniAuth calls this when authentication fails
  def failure
    # Rotate the session id and clear ALL partial state to prevent session
    # fixation (consistent with destroy and the timeout path). Set the flash
    # AFTER reset_session, which clears the flash store.
    reset_session

    flash[:alert] = t("flash.authentication_failed")
    redirect_to new_session_path
  end

  # DELETE /sign_out
  def destroy
    reset_session
    flash[:notice] = t("flash.signed_out")
    redirect_to new_session_path
  end
end
