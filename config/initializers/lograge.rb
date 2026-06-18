# frozen_string_literal: true

Rails.application.configure do
  # Structured logging via lograge — reduces verbose Rails log output to a single JSON line per request.
  # Full SMTP and operational logging configuration is done in Story 1.6.
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
end
