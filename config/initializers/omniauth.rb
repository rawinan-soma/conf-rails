# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :openid_connect,
    name: :openid_connect,
    client_id: Rails.application.credentials.dig(:oidc, :client_id),
    client_secret: Rails.application.credentials.dig(:oidc, :client_secret),
    issuer: Rails.application.credentials.dig(:oidc, :issuer_url),
    discovery: true,
    scope: %i[openid email profile],
    response_type: :code,
    pkce: true
end

OmniAuth.config.logger = Rails.logger
OmniAuth.config.silence_get_warning = false  # Keep GET warning visible
