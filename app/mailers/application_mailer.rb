# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  # Sender display name wired via i18n — actual org name and SMTP configured in Story 1.6.
  default from: -> { I18n.t("mailers.sender_display") }
  layout "mailer"
end
