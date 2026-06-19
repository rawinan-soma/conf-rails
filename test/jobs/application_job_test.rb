# frozen_string_literal: true

require "test_helper"

# Story 1.6: Email & Background-Job Infrastructure
# AC #1: Background jobs and recurring-task scheduler are operational with a dead-letter path.
# AC #2: Triggering transaction commits even if send later fails (retry/backoff).
class ApplicationJobTest < ActiveSupport::TestCase
  # ActiveJob::TestHelper is already included globally in test_helper.rb.
  # No need to include again here.

  # Inline test job — used to exercise ApplicationJob behavior without real job classes.
  class TestMailerJob < ApplicationJob
    queue_as :mailers

    def perform(*)
      # no-op for testing infrastructure only
    end
  end

  # AC #1 — ApplicationJob subclasses must respond to perform_now (job infrastructure loads).
  test "[P1] ApplicationJob subclass responds to perform_now" do
    assert_respond_to TestMailerJob, :perform_now,
      "ApplicationJob subclasses must respond to perform_now"
  end

  # AC #1 — Retry configuration: ApplicationJob must retry on StandardError.
  test "[P0] ApplicationJob retries on StandardError with exponential backoff" do
    # Verify retry handler is registered for StandardError
    retry_handlers = ApplicationJob.rescue_handlers.map(&:first)
    assert_includes retry_handlers.map(&:to_s), "StandardError",
      "ApplicationJob must retry on StandardError (polynomially_longer, 5 attempts)"
  end

  # AC #1 — Discard on deserialization error (job record gone — don't retry forever).
  test "[P1] ApplicationJob discards on DeserializationError" do
    discard_handlers = ApplicationJob.rescue_handlers.map(&:first)
    assert_includes discard_handlers.map(&:to_s), "ActiveJob::DeserializationError",
      "ApplicationJob must discard_on ActiveJob::DeserializationError"
  end

  # AC #1 — Dead-letter path: solid_queue_failed_executions table must exist in queue schema.
  # Solid Queue moves exhausted-retry jobs to this table (production queue database).
  # In the test database, we verify the schema file defines the table.
  test "[P1] solid_queue_failed_executions table is defined in queue schema" do
    queue_schema_path = Rails.root.join("db/queue_schema.rb")
    schema_content = File.read(queue_schema_path)
    assert_match(/solid_queue_failed_executions/, schema_content,
      "db/queue_schema.rb must define solid_queue_failed_executions table (dead-letter path for AC #1)")
  end

  # AC #2 — Stub job classes must load without NameError (Solid Queue recurring entries reference them).
  test "[P1] SendRegistrationConfirmationJob loads without NameError" do
    assert defined?(SendRegistrationConfirmationJob),
      "SendRegistrationConfirmationJob class must be defined (stub for Story 3.2)"
  end

  test "[P1] SendEventReminderJob loads without NameError" do
    assert defined?(SendEventReminderJob),
      "SendEventReminderJob class must be defined (stub for Story 3.8)"
  end

  test "[P1] CloseExpiredRegistrationsJob loads without NameError" do
    assert defined?(CloseExpiredRegistrationsJob),
      "CloseExpiredRegistrationsJob class must be defined (stub for Story 3.1)"
  end

  # AC #2 — Stub jobs raise NotImplementedError (not silently pass or do wrong work).
  test "[P1] stub job classes raise NotImplementedError on perform" do
    assert_raises(NotImplementedError) { SendRegistrationConfirmationJob.perform_now(1) }
    assert_raises(NotImplementedError) { SendEventReminderJob.perform_now(1) }
    assert_raises(NotImplementedError) { CloseExpiredRegistrationsJob.perform_now }
  end
end
