# frozen_string_literal: true

require "test_helper"

# RED-PHASE ATDD scaffold for Story 1.6: Email & Background-Job Infrastructure
# AC #1: Background jobs and recurring-task scheduler are operational with a dead-letter path.
# AC #2: Triggering transaction commits even if send later fails (retry/backoff).
#
# These tests are written in TDD red-phase style:
# - Tests marked with `skip` will be activated one-by-one during implementation.
# - Remove the `skip` call for the test that covers your current task, verify it
#   FAILS first, implement the feature, then verify it PASSES (green phase).
class ApplicationJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  # Inline test job — used to exercise ApplicationJob behavior without real job classes.
  class TestMailerJob < ApplicationJob
    queue_as :mailers

    def perform(*)
      # no-op for testing infrastructure only
    end
  end

  class TestJobThatFails < ApplicationJob
    queue_as :default

    def perform(*)
      raise StandardError, "Simulated transient error"
    end
  end

  # AC #1 — ApplicationJob subclasses must respond to perform_now (job infrastructure loads).
  # Depends on Task 5: ApplicationJob configured with retry/backoff.
  test "ApplicationJob subclass responds to perform_now" do
    skip "RED: Task 5 — ApplicationJob must configure retry_on StandardError with backoff"
    assert_respond_to TestMailerJob, :perform_now,
      "ApplicationJob subclasses must respond to perform_now"
  end

  # AC #1 — Retry configuration: ApplicationJob must retry on StandardError.
  # Depends on Task 5: retry_on StandardError, wait: :polynomially_longer, attempts: 5
  test "ApplicationJob retries on StandardError with exponential backoff" do
    skip "RED: Task 5 — ApplicationJob must have retry_on StandardError, wait: :polynomially_longer, attempts: 5"
    # Verify retry handler is registered for StandardError
    retry_handlers = ApplicationJob.rescue_handlers.map(&:first)
    assert_includes retry_handlers.map(&:to_s), "StandardError",
      "ApplicationJob must retry on StandardError (polynomially_longer, 5 attempts)"
  end

  # AC #1 — Discard on deserialization error (job record gone — don't retry forever).
  # Depends on Task 5: discard_on ActiveJob::DeserializationError
  test "ApplicationJob discards on DeserializationError" do
    skip "RED: Task 5 — ApplicationJob must discard_on ActiveJob::DeserializationError"
    discard_handlers = ApplicationJob.rescue_handlers.map(&:first)
    assert_includes discard_handlers.map(&:to_s), "ActiveJob::DeserializationError",
      "ApplicationJob must discard_on ActiveJob::DeserializationError"
  end

  # AC #1 — Dead-letter path: solid_queue_failed_executions table must exist.
  # Depends on db/queue_schema.rb from Story 1.1 (verify only — no migration needed).
  test "solid_queue_failed_executions table exists for dead-letter path" do
    skip "RED: AC #1 — Verify solid_queue_failed_executions table is present in db/queue_schema.rb"
    assert ActiveRecord::Base.connection.table_exists?("solid_queue_failed_executions"),
      "solid_queue_failed_executions table must exist (dead-letter path for AC #1)"
  end

  # AC #2 — Stub job classes must load without NameError (Solid Queue recurring entries reference them).
  # Depends on Task 6: stub job files in app/jobs/.
  test "SendRegistrationConfirmationJob loads without NameError" do
    skip "RED: Task 6 — Create app/jobs/send_registration_confirmation_job.rb stub"
    assert defined?(SendRegistrationConfirmationJob),
      "SendRegistrationConfirmationJob class must be defined (stub for Story 3.2)"
  end

  test "SendEventReminderJob loads without NameError" do
    skip "RED: Task 6 — Create app/jobs/send_event_reminder_job.rb stub"
    assert defined?(SendEventReminderJob),
      "SendEventReminderJob class must be defined (stub for Story 3.8)"
  end

  test "CloseExpiredRegistrationsJob loads without NameError" do
    skip "RED: Task 6 — Create app/jobs/close_expired_registrations_job.rb stub"
    assert defined?(CloseExpiredRegistrationsJob),
      "CloseExpiredRegistrationsJob class must be defined (stub for Story 3.1)"
  end

  # AC #2 — Stub jobs raise NotImplementedError (not silently pass or do wrong work).
  # Depends on Task 6.
  test "stub job classes raise NotImplementedError on perform" do
    skip "RED: Task 6 — Stub jobs must raise NotImplementedError when performed"
    assert_raises(NotImplementedError) { SendRegistrationConfirmationJob.perform_now(1) }
    assert_raises(NotImplementedError) { SendEventReminderJob.perform_now(1) }
    assert_raises(NotImplementedError) { CloseExpiredRegistrationsJob.perform_now }
  end
end
