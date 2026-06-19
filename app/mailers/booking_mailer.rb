# frozen_string_literal: true

# Stub mailer for booking notifications — implemented in Stories 2.4 and 2.5.
# Extends ApplicationMailer to inherit sender display name and mailers queue.
class BookingMailer < ApplicationMailer
  # Stub — implemented in Story 2.4.
  # Usage: BookingMailer.confirmation(booking).deliver_later
  def confirmation(booking)
    raise NotImplementedError, "Implemented in Story 2.4"
  end

  # Stub — implemented in Story 2.5.
  # Usage: BookingMailer.cancellation(booking).deliver_later
  def cancellation(booking)
    raise NotImplementedError, "Implemented in Story 2.5"
  end
end
