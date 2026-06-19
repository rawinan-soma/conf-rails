# frozen_string_literal: true

class ButtonComponent < ApplicationComponent
  VARIANT_CLASSES = {
    primary: "btn-primary",
    secondary: "btn-secondary",
    ghost: "btn-ghost"
  }.freeze

  def initialize(label:, variant: :primary, loading: false, type: :button, href: nil, method: nil, disabled: false, **html_options)
    @label = label
    @variant = variant.to_sym
    @loading = loading
    @type = type
    @href = href
    @method = method
    @disabled = disabled
    @html_options = html_options
  end

  def variant_class
    VARIANT_CLASSES.fetch(@variant, "btn-primary")
  end

  def render_as_link?
    @href.present?
  end

  def disabled?
    @disabled || @loading
  end
end
