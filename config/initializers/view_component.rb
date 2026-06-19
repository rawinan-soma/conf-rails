# frozen_string_literal: true

ViewComponent::Base.config.use_linting = !Rails.env.test?
