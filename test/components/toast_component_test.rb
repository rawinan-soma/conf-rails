# frozen_string_literal: true

# ATDD Red-Phase Tests — Story 1.2: Core Design System & ViewComponent UI Library
# Subgroup: ToastComponent
#
# TDD RED PHASE: All tests use `skip` until ToastComponent is implemented.
#
# Acceptance Criteria Covered:
#   AC-2: Toast shows icon or prefix word in addition to color (no color-alone meaning,
#         WCAG 2.1 AA). Accepts message:, type: (:success, :error, :info) kwargs.

require "test_helper"

class ToastComponentTest < ViewComponent::TestCase
  # ---------------------------------------------------------------------------
  # P0 — No color-alone meaning: icon or text prefix alongside color
  # ---------------------------------------------------------------------------

  test "[P0] success toast shows prefix word or icon (not color-only)" do
    render_inline(ToastComponent.new(message: "Conference saved.", type: :success))
    # Must show a prefix like "Success" or an icon element, not rely on color alone
    has_prefix = page.has_text?(I18n.t("components.toast.success_prefix"))
    has_icon = page.has_css?("[aria-hidden='true'], svg, .icon")
    assert has_prefix || has_icon,
           "success toast must convey meaning via text prefix or icon, not color alone"
  end

  test "[P0] error toast shows prefix word or icon (not color-only)" do
    render_inline(ToastComponent.new(message: "Failed to save.", type: :error))
    has_prefix = page.has_text?(I18n.t("components.toast.error_prefix"))
    has_icon = page.has_css?("[aria-hidden='true'], svg, .icon")
    assert has_prefix || has_icon,
           "error toast must convey meaning via text prefix or icon, not color alone"
  end

  # ---------------------------------------------------------------------------
  # P0 — Message is rendered
  # ---------------------------------------------------------------------------

  test "[P0] renders the message kwarg as text" do
    render_inline(ToastComponent.new(message: "Conference created successfully.", type: :success))
    assert_text "Conference created successfully."
  end

  # ---------------------------------------------------------------------------
  # P1 — Type variants render without error
  # ---------------------------------------------------------------------------

  test "[P1] info type renders without raising" do
    assert_nothing_raised do
      render_inline(ToastComponent.new(message: "Reminder sent.", type: :info))
    end
    assert_text "Reminder sent."
  end

  # ---------------------------------------------------------------------------
  # P1 — Positioned top-right (structural: class or data attribute)
  # ---------------------------------------------------------------------------

  test "[P1] toast has toast positioning class" do
    render_inline(ToastComponent.new(message: "Saved.", type: :success))
    assert_selector ".toast, [data-toast]"
  end

  # ---------------------------------------------------------------------------
  # P2 — Auto-dismiss controller hook
  # ---------------------------------------------------------------------------

  test "[P2] toast element has Stimulus controller attribute for auto-dismiss" do
    render_inline(ToastComponent.new(message: "Saved.", type: :success))
    # Stimulus controller for auto-dismiss via setTimeout
    assert_selector "[data-controller]"
  end
end
