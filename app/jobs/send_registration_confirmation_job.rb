# frozen_string_literal: true

class SendRegistrationConfirmationJob < ApplicationJob
  queue_as :mailers

  # IDEMPOTENCY GUARD: Implementing story (3.2) must add a sent-at marker to prevent
  # duplicate sends if this job is retried or run more than once.
  # Example: return if registration.confirmation_sent_at.present?
  def perform(registration_id)
    raise NotImplementedError, "Implemented in Story 3.2"
  end
end
