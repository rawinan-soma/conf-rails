# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  # Sender display name wired via i18n — actual org name and SMTP configured in Story 1.6.
  default from: -> { I18n.t("mailers.sender_display") }
  layout "mailer"

  # Route all mailer jobs to the dedicated mailers queue (Story 1.6 / architecture rule).
  # All child mailers inherit this queue assignment automatically.
  # ActionMailer uses deliver_later_queue_name (not queue_as) to set the delivery queue.
  self.deliver_later_queue_name = :mailers
end
