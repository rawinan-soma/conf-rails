# frozen_string_literal: true

class ToastComponent < ApplicationComponent
  TYPE_CLASSES = {
    success: "alert-success",
    error: "alert-error",
    info: "alert-info",
    notice: "alert-success",
    alert: "alert-error"
  }.freeze

  TYPE_PREFIXES = {
    success: "components.toast.success_prefix",
    error: "components.toast.error_prefix",
    info: "components.toast.info_prefix",
    notice: "components.toast.success_prefix",
    alert: "components.toast.error_prefix"
  }.freeze

  def initialize(message:, type: :info)
    @message = message
    @type = type&.to_sym || :info
  end

  def alert_class
    TYPE_CLASSES.fetch(@type, "alert-info")
  end

  def prefix
    key = TYPE_PREFIXES.fetch(@type, "components.toast.info_prefix")
    I18n.t(key)
  end
end
