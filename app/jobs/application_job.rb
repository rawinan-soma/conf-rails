# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Retry transient failures with exponential backoff (Story 1.6 / AC #1, #2).
  # After 5 failed attempts, Solid Queue moves the job to solid_queue_failed_executions (dead-letter).
  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  # Retry database deadlocks with the same polynomial backoff as the general handler.
  # Explicitly set wait/attempts to avoid the bare-default of flat 3s wait (which would give
  # deadlocks shorter retry windows than any generic transient error — the opposite of intent).
  retry_on ActiveRecord::Deadlocked, wait: :polynomially_longer, attempts: 5

  # Discard jobs whose records no longer exist — retrying is pointless and wastes resources.
  discard_on ActiveJob::DeserializationError
end
