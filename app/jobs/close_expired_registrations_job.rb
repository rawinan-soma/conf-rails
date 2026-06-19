# frozen_string_literal: true

class CloseExpiredRegistrationsJob < ApplicationJob
  queue_as :default

  # IDEMPOTENCY GUARD: Implementing story (3.1) must ensure closing already-closed registrations
  # is a no-op. Example: Registration.where(status: :open).where("closes_at <= ?", Time.current).each(...)
  def perform
    raise NotImplementedError, "Implemented in Story 3.1"
  end
end
