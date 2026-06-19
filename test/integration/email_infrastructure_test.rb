# frozen_string_literal: true

require "test_helper"

# RED-PHASE ATDD scaffold for Story 1.6: Email & Background-Job Infrastructure
# AC #1: Solid Queue operational with dead-letter path.
# AC #2: deliver_later enqueues mail; transaction commits independently of send.
# AC #3: Sender display name is the org name; SMTP-only delivery.
#
# These tests are written in TDD red-phase style:
# - Tests marked with `skip` will be activated one-by-one during implementation.
# - Remove the `skip` call for the test that covers your current task, verify it
#   FAILS first, implement the feature, then verify it PASSES (green phase).
#
# IMPORTANT: This file relies on ActiveJob::TestHelper helpers.
# Story 1.6 Task 8: Add `include ActiveJob::TestHelper` to ActiveSupport::TestCase
# in test/test_helper.rb (or include it in each file as done here).
class EmailInfrastructureTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  # ---------------------------------------------------------------------------
  # AC #2 — deliver_later does NOT immediately deliver (async decoupling)
  # ---------------------------------------------------------------------------

  # AC #2 — deliver_later enqueues exactly one mail job (does not deliver immediately).
  # Depends on Task 1 (ActionMailer configured), Task 2 (sender display), Task 7 (BookingMailer stub).
  # Uses assert_enqueued_emails to count jobs without performing them.
  test "deliver_later enqueues mail without immediate delivery" do
    skip "RED: Tasks 1+7 — BookingMailer stub must exist and ApplicationMailer must be configured"
    # No emails should be delivered yet.
    assert_no_emails do
      assert_enqueued_emails(1) do
        # BookingMailer is a stub — it will raise NotImplementedError if performed,
        # but enqueuing does not perform the job.
        BookingMailer.confirmation(stub_booking_data).deliver_later
      end
    end
  end

  # AC #2 — After deliver_later, performing enqueued jobs delivers the mail.
  # Verifies the full async pipeline: enqueue → perform → deliver.
  # Depends on Task 1, Task 7 (stub will raise NotImplementedError — use ApplicationMailer directly).
  test "perform_enqueued_jobs delivers the enqueued mail" do
    skip "RED: Tasks 1+2 — ApplicationMailer must be configured with working delivery in test env"
    # Use a minimal inline mailer derived from ApplicationMailer to test the pipeline.
    # This avoids depending on stub mailers that raise NotImplementedError.
    mailer_message = InlineTestMailer.sample_email
    assert_emails(0) { mailer_message.deliver_later }
    assert_emails(1) { perform_enqueued_jobs }
  end

  # ---------------------------------------------------------------------------
  # AC #2 — Transaction decoupling: deliver_later commits before mail is sent
  # ---------------------------------------------------------------------------

  # AC #2 — The triggering transaction commits independently of mail delivery.
  # This verifies the architecture hard rule (FR-084): no deliver_now inside transactions.
  test "deliver_later does not block the triggering transaction" do
    skip "RED: Tasks 1+2 — verify deliver_later does not block transaction commit"
    committed = false
    assert_enqueued_emails(1) do
      ActiveRecord::Base.transaction do
        # Simulate work in a transaction — using a simple DB-backed operation.
        # The mail is enqueued, not sent synchronously.
        InlineTestMailer.sample_email.deliver_later
        committed = true # Reached only if transaction did not raise or block.
      end
    end
    assert committed, "Transaction must commit before mail delivery (FR-084 decoupling rule)"
    assert_no_emails, "No email must be delivered synchronously inside the transaction"
  end

  # ---------------------------------------------------------------------------
  # AC #3 — Sender display name is org name; uses SMTP-only (no third-party service)
  # ---------------------------------------------------------------------------

  # AC #3 — ApplicationMailer default :from resolves to RFC 5322 format with org name.
  # Depends on Task 2: en.mailers.sender_display = "ENVOCC <noreply@conf.envocc.org>".
  test "ApplicationMailer from address contains ENVOCC organization name" do
    skip "RED: Task 2 — en.mailers.sender_display must be updated to RFC 5322 format with 'ENVOCC'"
    from_lambda = ApplicationMailer.default[:from]
    resolved_from = from_lambda.respond_to?(:call) ? from_lambda.call : from_lambda
    assert_match(/ENVOCC/, resolved_from,
      "Sender display name (from:) must contain org name 'ENVOCC' per AC #3 (FR-083)")
    assert_match(/\A.+\s<.+@.+>\z/, resolved_from,
      "Sender display must be RFC 5322 'Name <email>' format")
  end

  # AC #3 — Delivered mail carries the correct From header (org name in from:).
  # End-to-end verification through the ActionMailer :test adapter.
  test "delivered mail carries org name in From header" do
    skip "RED: Tasks 1+2+7 — Full pipeline: InlineTestMailer must exist and from must be configured"
    perform_enqueued_jobs do
      InlineTestMailer.sample_email.deliver_later
    end
    assert_equal 1, ActionMailer::Base.deliveries.size,
      "Exactly one email must be delivered"
    delivered = ActionMailer::Base.deliveries.last
    assert_match(/ENVOCC/, delivered.from.first || delivered[:from].value,
      "Delivered mail From header must include org name 'ENVOCC'")
  end

  # ---------------------------------------------------------------------------
  # AC #1 — Solid Queue queue configuration (mailers queue exists)
  # ---------------------------------------------------------------------------

  # AC #1 — Mailer jobs route to the dedicated 'mailers' queue.
  # Depends on Task 3 (config/queue.yml mailers worker) + Dev Notes (queue_as :mailers).
  test "ApplicationMailer jobs route to mailers queue" do
    skip "RED: Tasks 1+3 — ApplicationMailer must have queue_as :mailers; config/queue.yml must define mailers worker"
    # Verify enqueued job targets the mailers queue.
    assert_enqueued_with(queue: "mailers") do
      InlineTestMailer.sample_email.deliver_later
    end
  end

  # ---------------------------------------------------------------------------
  # Stub mailer classes exist (AC #1, #3) — no NameError at boot
  # ---------------------------------------------------------------------------

  # AC #1/#3 — Stub mailer classes must be loadable (Solid Queue boot check).
  # Depends on Task 7: BookingMailer + RegistrationMailer stubs.
  test "BookingMailer stub class is defined and extends ApplicationMailer" do
    skip "RED: Task 7 — Create app/mailers/booking_mailer.rb stub"
    assert defined?(BookingMailer), "BookingMailer must be defined"
    assert BookingMailer < ApplicationMailer,
      "BookingMailer must extend ApplicationMailer to inherit sender display name"
  end

  test "RegistrationMailer stub class is defined and extends ApplicationMailer" do
    skip "RED: Task 7 — Create app/mailers/registration_mailer.rb stub"
    assert defined?(RegistrationMailer), "RegistrationMailer must be defined"
    assert RegistrationMailer < ApplicationMailer,
      "RegistrationMailer must extend ApplicationMailer to inherit sender display name"
  end

  # AC #3 — Stub mailer methods raise NotImplementedError (not silently pass).
  test "BookingMailer stub methods raise NotImplementedError" do
    skip "RED: Task 7 — BookingMailer stub must raise NotImplementedError on :confirmation and :cancellation"
    assert_raises(NotImplementedError) { BookingMailer.confirmation(nil) }
    assert_raises(NotImplementedError) { BookingMailer.cancellation(nil) }
  end

  test "RegistrationMailer stub methods raise NotImplementedError" do
    skip "RED: Task 7 — RegistrationMailer stub must raise NotImplementedError on :confirmation, :cancellation, :reminder"
    assert_raises(NotImplementedError) { RegistrationMailer.confirmation(nil) }
    assert_raises(NotImplementedError) { RegistrationMailer.cancellation(nil) }
    assert_raises(NotImplementedError) { RegistrationMailer.reminder(nil) }
  end

  private

  # Minimal struct for stub booking data — avoids DB dependency in unit-style assertions.
  def stub_booking_data
    OpenStruct.new(id: 1, email: "attendee@example.com", event_title: "Test Event")
  end
end

# ---------------------------------------------------------------------------
# InlineTestMailer — Minimal concrete mailer for integration pipeline tests.
# NOT a stub — this actually sends mail so we can test the full delivery pipeline.
# Defined inline here to avoid polluting app/mailers/.
# ---------------------------------------------------------------------------
class InlineTestMailer < ApplicationMailer
  def sample_email
    mail(
      to: "test-recipient@example.com",
      subject: "ATDD Infrastructure Test"
    ) do |format|
      format.text { render plain: "This is a test email for Story 1.6 ATDD verification." }
    end
  end
end
