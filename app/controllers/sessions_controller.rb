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

    session[:user_id] = user.id
    session[:last_active_at] = Time.current.to_i

    redirect_to safe_return_to || root_path
  end

  # GET /auth/failure
  # OmniAuth calls this when authentication fails
  def failure
    # Clear any partial session state
    session.delete(:user_id)
    session.delete(:last_active_at)
    session.delete(:return_to)

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
