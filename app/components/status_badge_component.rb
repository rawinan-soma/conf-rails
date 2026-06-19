# frozen_string_literal: true

class StatusBadgeComponent < ApplicationComponent
  STATUS_STYLES = {
    registered: "badge-success",
    cancelled: "badge-ghost"
  }.freeze

  def initialize(status:)
    @status = status&.to_sym || :unknown
  end

  def badge_class
    STATUS_STYLES.fetch(@status, "badge-ghost")
  end

  def label
    I18n.t("components.status_badge.#{@status}", default: @status.to_s.humanize)
  end
end
