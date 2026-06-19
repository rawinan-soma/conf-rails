# frozen_string_literal: true

require "test_helper"

# Story 1.6: Email & Background-Job Infrastructure
# AC #3: Sender display name is the organization name; delivery uses org SMTP only.
class ApplicationMailerTest < ActionMailer::TestCase
  # AC #3 — Sender display name must be the org name in RFC 5322 "Name <email>" format.
  test "default from uses mailers.sender_display i18n key" do
    from_value = ApplicationMailer.default[:from]
    # The default[:from] is a lambda — call it to resolve the value.
    resolved = from_value.respond_to?(:call) ? from_value.call : from_value
    assert_not_nil resolved, "ApplicationMailer default :from must not be nil"
    assert_match(/\A.+\s<.+@.+>\z/, resolved,
      "ApplicationMailer default :from must be RFC 5322 'Name <email@domain>' format")
  end

  # AC #3 — Sender display name must contain the organization name "ENVOCC".
  test "default from contains organization name ENVOCC" do
    from_value = ApplicationMailer.default[:from]
    resolved = from_value.respond_to?(:call) ? from_value.call : from_value
    assert_includes resolved, "ENVOCC",
      "Sender display name must contain the organization name 'ENVOCC'"
  end

  # AC #3 — ApplicationMailer must route to mailers queue for async delivery.
  # Uses deliver_later_queue_name (ActionMailer API) rather than queue_as (ActiveJob API).
  test "ApplicationMailer deliver_later uses mailers queue" do
    assert_equal "mailers", ApplicationMailer.deliver_later_queue_name.to_s,
      "ApplicationMailer must deliver to 'mailers' queue (deliver_later_queue_name)"
  end
end
