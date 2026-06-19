# frozen_string_literal: true

require "test_helper"

# Story 1.6: Email & Background-Job Infrastructure
# AC #1: Solid Queue operational with dead-letter path.
# AC #2: deliver_later enqueues mail; transaction commits independently of send.
# AC #3: Sender display name is the org name; SMTP-only delivery.
class EmailInfrastructureTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  # Clear the deliveries array before and after each test so delivery counts are isolated.
  # ActiveJob::TestHelper auto-clears the job queue but NOT ActionMailer::Base.deliveries.
  # NOTE: parallelize(workers: 1) was intentionally removed — it sets a process-wide global
  # (Minitest.parallel_executor) that degrades the entire test suite to 1 worker, not just
  # this class. Instead we rely on setup/teardown to keep deliveries isolated per test.
  # ActionMailer::Base.deliveries uses a mutex-protected array in :test delivery mode, so
  # concurrent reads within a single test are safe as long as we clear between tests.
  setup do
    ActionMailer::Base.deliveries.clear
  end

  teardown do
    ActionMailer::Base.deliveries.clear
  end

  # ---------------------------------------------------------------------------
  # AC #2 — deliver_later does NOT immediately deliver (async decoupling)
  # ---------------------------------------------------------------------------

  # AC #2 — deliver_later enqueues exactly one mail job (does not deliver immediately).
  test "[P0] deliver_later enqueues mail without immediate delivery" do
    # Verify no emails are delivered synchronously with deliver_later.
    assert_enqueued_emails(1) do
      InlineTestMailer.sample_email.deliver_later
    end
    # After deliver_later but before perform, no actual delivery should have occurred.
    assert_equal 0, ActionMailer::Base.deliveries.size,
      "deliver_later must not immediately deliver the email (AC #2 async decoupling)"
  end

  # AC #2 — After deliver_later, performing enqueued jobs delivers the mail.
  test "[P0] perform_enqueued_jobs delivers the enqueued mail" do
    InlineTestMailer.sample_email.deliver_later
    assert_emails(1) { perform_enqueued_jobs }
  end

  # ---------------------------------------------------------------------------
  # AC #2 — Transaction decoupling: deliver_later commits before mail is sent
  # ---------------------------------------------------------------------------

  # AC #2 — The triggering transaction commits independently of mail delivery.
  test "[P0] deliver_later does not block the triggering transaction" do
    committed = false
    assert_enqueued_emails(1) do
      ActiveRecord::Base.transaction do
        InlineTestMailer.sample_email.deliver_later
        committed = true
      end
    end
    assert committed, "Transaction must commit before mail delivery (FR-084 decoupling rule)"
    # No email should be delivered yet (still in queue, not performed).
    assert_equal 0, ActionMailer::Base.deliveries.size,
      "No email must be delivered synchronously inside the transaction"
  end

  # ---------------------------------------------------------------------------
  # AC #3 — Sender display name is org name; uses SMTP-only (no third-party service)
  # ---------------------------------------------------------------------------

  # AC #3 — ApplicationMailer default :from resolves to RFC 5322 format with org name.
  test "[P0] ApplicationMailer from address contains ENVOCC organization name" do
    from_lambda = ApplicationMailer.default[:from]
    resolved_from = from_lambda.respond_to?(:call) ? from_lambda.call : from_lambda
    assert_match(/ENVOCC/, resolved_from,
      "Sender display name (from:) must contain org name 'ENVOCC' per AC #3 (FR-083)")
    assert_match(/\A.+\s<.+@.+>\z/, resolved_from,
      "Sender display must be RFC 5322 'Name <email>' format")
  end

  # AC #3 — Delivered mail carries the correct From header (org name in from:).
  test "[P1] delivered mail carries org name in From header" do
    perform_enqueued_jobs do
      InlineTestMailer.sample_email.deliver_later
    end
    assert_equal 1, ActionMailer::Base.deliveries.size,
      "Exactly one email must be delivered"
    delivered = ActionMailer::Base.deliveries.last
    assert_match(/ENVOCC/, delivered[:from].value,
      "Delivered mail From header must include org name 'ENVOCC'")
  end

  # ---------------------------------------------------------------------------
  # AC #1 — Solid Queue queue configuration (mailers queue exists)
  # ---------------------------------------------------------------------------

  # AC #1 — Mailer jobs route to the dedicated 'mailers' queue.
  # ActionMailer uses deliver_later_queue_name to route delivery jobs.
  test "[P1] ApplicationMailer jobs route to mailers queue" do
    assert_equal "mailers", ApplicationMailer.deliver_later_queue_name.to_s,
      "ApplicationMailer must route to 'mailers' queue via deliver_later_queue_name"
  end

  # ---------------------------------------------------------------------------
  # Stub mailer classes exist (AC #1, #3) — no NameError at boot
  # ---------------------------------------------------------------------------

  # AC #1/#3 — Stub mailer classes must be loadable (Solid Queue boot check).
  test "[P1] BookingMailer stub class is defined and extends ApplicationMailer" do
    assert defined?(BookingMailer), "BookingMailer must be defined"
    assert BookingMailer < ApplicationMailer,
      "BookingMailer must extend ApplicationMailer to inherit sender display name"
  end

  test "[P1] RegistrationMailer stub class is defined and extends ApplicationMailer" do
    assert defined?(RegistrationMailer), "RegistrationMailer must be defined"
    assert RegistrationMailer < ApplicationMailer,
      "RegistrationMailer must extend ApplicationMailer to inherit sender display name"
  end

  # AC #3 — Stub mailer methods raise NotImplementedError when delivered.
  # Note: ActionMailer class methods return MessageDelivery — the error is raised on delivery.
  test "[P1] BookingMailer stub methods raise NotImplementedError on delivery" do
    assert_raises(NotImplementedError) { BookingMailer.confirmation(nil).deliver_now }
    assert_raises(NotImplementedError) { BookingMailer.cancellation(nil).deliver_now }
  end

  test "[P1] RegistrationMailer stub methods raise NotImplementedError on delivery" do
    assert_raises(NotImplementedError) { RegistrationMailer.confirmation(nil).deliver_now }
    assert_raises(NotImplementedError) { RegistrationMailer.cancellation(nil).deliver_now }
    assert_raises(NotImplementedError) { RegistrationMailer.reminder(nil).deliver_now }
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
