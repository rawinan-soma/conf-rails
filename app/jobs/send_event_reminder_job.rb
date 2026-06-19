# frozen_string_literal: true

class SendEventReminderJob < ApplicationJob
  queue_as :mailers

  # IDEMPOTENCY GUARD: Implementing story (3.8) must add a sent-at marker to prevent
  # duplicate sends if this job is retried or run more than once.
  # Example: return if booking.reminder_sent_at.present?
  def perform(booking_id)
    raise NotImplementedError, "Implemented in Story 3.8"
  end
end
