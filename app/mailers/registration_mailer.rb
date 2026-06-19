# frozen_string_literal: true

# Stub mailer for registration notifications — implemented in Stories 3.2, 3.3, and 3.8.
# Extends ApplicationMailer to inherit sender display name and mailers queue.
class RegistrationMailer < ApplicationMailer
  # Stub — implemented in Story 3.2.
  # Usage: RegistrationMailer.confirmation(registration).deliver_later
  def confirmation(registration)
    raise NotImplementedError, "Implemented in Story 3.2"
  end

  # Stub — implemented in Story 3.3.
  # Usage: RegistrationMailer.cancellation(registration).deliver_later
  def cancellation(registration)
    raise NotImplementedError, "Implemented in Story 3.3"
  end

  # Stub — implemented in Story 3.8.
  # Usage: RegistrationMailer.reminder(registration).deliver_later
  def reminder(registration)
    raise NotImplementedError, "Implemented in Story 3.8"
  end
end
