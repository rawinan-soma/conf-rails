# frozen_string_literal: true

require "test_helper"

# RED-PHASE ATDD scaffold for Story 1.6: Email & Background-Job Infrastructure
# AC #3: Sender display name is the organization name; delivery uses org SMTP only.
#
# These tests are written in TDD red-phase style:
# - Tests marked with `skip` will be activated one-by-one during implementation.
# - Remove the `skip` call for the test that covers your current task, verify it
#   FAILS first, implement the feature, then verify it PASSES (green phase).
class ApplicationMailerTest < ActionMailer::TestCase
  # AC #3 — Sender display name must be the org name in RFC 5322 "Name <email>" format.
  # Depends on Task 2: en.mailers.sender_display updated to RFC 5322 placeholder.
  test "default from uses mailers.sender_display i18n key" do
    skip "RED: Task 2 — en.mailers.sender_display must be set to RFC 5322 'Name <email>' format"
    from_value = ApplicationMailer.default[:from]
    # The default[:from] is a lambda — call it to resolve the value.
    resolved = from_value.respond_to?(:call) ? from_value.call : from_value
    assert_not_nil resolved, "ApplicationMailer default :from must not be nil"
    assert_match(/\A.+\s<.+@.+>\z/, resolved,
      "ApplicationMailer default :from must be RFC 5322 'Name <email@domain>' format")
  end

  # AC #3 — Sender display name must contain the organization name "ENVOCC".
  # Depends on Task 2: en.mailers.sender_display updated to include "ENVOCC".
  test "default from contains organization name ENVOCC" do
    skip "RED: Task 2 — en.mailers.sender_display must include 'ENVOCC' as the org name"
    from_value = ApplicationMailer.default[:from]
    resolved = from_value.respond_to?(:call) ? from_value.call : from_value
    assert_includes resolved, "ENVOCC",
      "Sender display name must contain the organization name 'ENVOCC'"
  end

  # AC #3 — ApplicationMailer must inherit queue_as :mailers for async delivery routing.
  # Depends on Task 1 (queue config) + Dev Notes: queue_as :mailers on ApplicationMailer.
  test "ApplicationMailer routes to mailers queue" do
    skip "RED: Dev Notes — ApplicationMailer must have queue_as :mailers so child mailers inherit it"
    assert_equal "mailers", ApplicationMailer.new.queue_name,
      "ApplicationMailer must queue on 'mailers' queue (queue_as :mailers)"
  end
end
