# frozen_string_literal: true

class EmptyStateComponent < ApplicationComponent
  def initialize(message: nil, action_label: nil, action_path: nil)
    @message = message || I18n.t("components.empty_state.default_message")
    @action_label = action_label
    @action_path = action_path
  end

  def has_action?
    @action_label.present? && @action_path.present?
  end
end
